---
name: recall
description: "Reconstruct your recent working context from your own chat history, live state, and the shared record (user reports, prior fixes, incidents), then hand back a tight current-state brief. Use for 'recall my work on X', 'catch me up', 'what have I been working on', 'where did I leave off', before starting or resuming work."
---

# Recall

**Before you start or resume work, you rebuild the user's recent working context and hand back a tight capsule of where things stand now and what to do next.**

Keep it tight and on-topic. Read only what the in-scope threads need, then stop.

Your context lives in two records. Your own chat history holds what you did and decided. The shared record holds everything that happened around the same code under other names: the symptoms users keep reporting, the fixes that shipped and got reverted, the errors still firing in prod. That second record is what the **why** skill searches, across source control, the issue tracker, chat and issue channels, long-form docs, and error tracking. A feature with a long bug tail keeps most of its story there, so don't reconstruct it from your transcripts alone.

## Where the chat history lives

Every line of a transcript is one JSON record. Read them with `jq` and `grep`, never by loading whole files into context.

**Claude Code.** `$CLAUDE_CONFIG_DIR/projects/<slug>/<session-id>.jsonl`, one file per session (`CLAUDE_CONFIG_DIR` defaults to `~/.claude`). `<slug>` is the absolute cwd with `/` and other non-alphanumerics turned into `-`, so `/Users/you/proj` becomes `-Users-you-proj`. Find it by name rather than computing it: `ls "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects" | grep -- "$(basename "$PWD")"`. Next to each session file, `<session-id>/subagents/agent-*.jsonl` holds subagent transcripts (`agent-*.meta.json` names the `agentType`) and `<session-id>/tool-results/` holds tool outputs too large to inline.

Record shapes:

- `"type":"user"` is either a human prompt or a tool result. A human prompt has no `toolUseResult` key, `isMeta` is not `true`, and `.message.content` is a string or an array of `text` blocks. Skip the injected wrappers: `[Request interrupted…`, `<command-…>`, `<local-command-…>`, `<task-notification>`, `<bash-…>`.
- `"type":"assistant"` carries `.message.content[]` blocks of type `text`, `thinking`, and `tool_use` (`.name`, `.input`).
- `"type":"ai-title"` carries the session title in `.aiTitle`. Every message record carries `timestamp`, `cwd`, `gitBranch`, and `sessionId`.

```bash
PROJECT_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/<slug>"

# Sessions in the window, newest first by real modification time
find "$PROJECT_DIR" -maxdepth 1 -name '*.jsonl' -mtime -7 -print0 | xargs -0 ls -t

# Which of them mention the topic
grep -l -i '<topic>' <session files>

# Session title
jq -r 'select(.type=="ai-title") | .aiTitle' <file> | tail -1

# Human prompts only
jq -r 'select(.type=="user" and (has("toolUseResult") | not) and (.isMeta != true))
  | .message.content
  | if type=="string" then . else map(select(.type=="text") | .text) | join("\n") end
  | select(test("^(\\[Request interrupted|<command-|<local-command-|<task-notification|<bash-)") | not)' <file>

# Assistant prose, then the tool calls it made
jq -r 'select(.type=="assistant") | .message.content[] | select(.type=="text") | .text' <file>
jq -r 'select(.type=="assistant") | .message.content[] | select(.type=="tool_use") | "\(.name) \(.input | tostring | .[0:200])"' <file>

# Branches the session ran on
jq -r '.gitBranch // empty' <file> | sort -u
```

**Codex.** `~/.codex/sessions/YYYY/MM/DD/rollout-<timestamp>-<session-id>.jsonl`, not split by project. The first record is `"type":"session_meta"` with `.payload.cwd`, `.payload.id`, and `.payload.git.branch`, so filter sessions by `cwd` to stay in the active workspace. Messages are `"type":"response_item"` with `.payload.type=="message"` and `.payload.role` of `user`, `assistant`, or `developer` (injected instructions, skip). User text is in `.payload.content[]` blocks of type `input_text`. The first user message also carries injected context blocks (`<environment_context>`, `# AGENTS.md instructions`, other `<…>` wrappers), so skip blocks that start with `<` or `# AGENTS.md`. Assistant text is in `output_text` blocks. Other `.payload.type` values are tool traffic. List them before reading: `jq -r 'select(.type=="response_item") | .payload.type' <file> | sort | uniq -c`.

```bash
# Sessions in the window for this workspace
find ~/.codex/sessions -name 'rollout-*.jsonl' -mtime -7 -print0 | xargs -0 ls -t \
  | while read -r f; do jq -e --arg cwd "$PWD" 'select(.type=="session_meta" and .payload.cwd==$cwd)' "$f" >/dev/null && echo "$f"; done

# Human prompts only
jq -r 'select(.type=="response_item" and .payload.type=="message" and .payload.role=="user")
  | .payload.content[] | select(.type=="input_text") | .text
  | select(test("^(<|# AGENTS\\.md)") | not)' <file>
```

## Steps

1. Classify, then route. One specific prior chat to resume is the `session-pickup` playbook of **harness-mode**, not this. Turning habits into a durable skill is `automate-me`. A human-readable summary of your work is a different task. Recall loads working context across recent chats before you act. If the user already gave you a full state capsule (paths, branch, the change), use it and skip the mining.
2. Lock the scope before searching. Pin the window ("recent" is a real range, default the last 7 days), the topic if named, and the workspace (default the active one. Never read another project's transcripts without being asked). Search Claude Code transcripts by default, and Codex sessions too when the user works in both. State the scope back. Never quietly turn "all" into "recent N".
3. Fan out across your chat history. Spawn parallel `Agent` subagents with `subagent_type: "fast-worker"`, each taking a slice of the corpus and the recipes above. Tell every subagent to order candidates by real modification time (`ls -t`) and never by session-id name, grep the topic first and then read only the matching chats and only their relevant regions, and skip the current chat (the newest file, whose last human prompt is this request) plus obvious noise: subagent transcripts (the `-maxdepth 1` above already leaves them out), and eval or test chats (a `cwd` under a scratchpad or tmp dir). Each returns the same schema, one block per chat: topic, the user's goal, decisions, open threads, struggles and corrections, and artifacts (PRs, tickets, branches), each citing the session id. For one or two chats, skip the fan-out and search directly. The raw transcripts stay in the subagents. The main thread gets only their findings.
4. Sweep the shared record whenever the topic names a feature, file, subsystem, area, or bug. This is the default, not a judgment call, and "my work on X" does not exempt it. Hand it to the **why** skill's source investigators, but steer their question from "why was this built this way" to "what's the current state, what's been tried and didn't hold, and what are users still reporting". Reuse its per-source playbooks, run the investigators in parallel with the chat-history mining, and inherit its posture: one investigator per source, null results are findings, skip an unavailable MCP and say so. Fold what comes back into the brief. Skip this step only for pure activity recall with no named target ("what did I do this week"), where your own history and live state are the entire answer.
5. Verify against live state. Take the PRs, branches, and tickets that the mining and the sweep surfaced and check them with `git` and `gh`. When the answer hinges on what an agent actually did (the tools it ran, files it read, errors it hit), read its full record: the `tool_use` blocks and tool results, its `subagents/agent-*.jsonl`, and its `tool-results/` files, not just the prose turns.
6. Write the brief to the contract below. Group by thread. Stay on the named topic.

## Output contract

Lead with the capsule, then the thread status, then the problems, then the next move. Deeper detail goes below or gets cut.

- **Capsule.** At most 5 bullets. What this work is and where it stands overall.
- **Threads.** One line each, prefixed with exactly one status tag: `[merged #N]`, `[open PR #N]`, `[in flight <branch>]`, `[verified, uncommitted]`, `[reverted #N]`, or `[planned, not started]`. A thread with no tag is not done yet, so tag it.
- **Problems.** At most 5, the recurring ones. Include the symptoms users keep reporting and any fix that shipped and was reverted, so the next attempt starts where the last one failed.
- **Next move.** The single most useful next action, concrete.

An adjacent feature or ticket stays out unless it blocks this one. When the capsule and thread lines outgrow a screen, cut detail before you cut threads. Cite chat findings by session id and shared-record findings by their source (PR #, ticket ID, chat permalink, error-tracker issue), and sanitize private context before any public output.

**Reply:** the brief, to the contract above, in the harness output style (AGENTS.md Output style). When the brief is saved to a file or posted somewhere others read it, write it through the **unslop** skill.
