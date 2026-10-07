---
name: reflect
description: Spawn three parallel review subagents over the active Claude Code or Codex transcript, surface durable learnings, and route each to a concrete edit on an existing skill or to a structural fix. Use when the user says "reflect" or "/reflect", or wants a session's lessons captured so the next run doesn't repeat them.
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits the user approves, or into structural fixes when prose would not hold.

## When to invoke

Invoke when the user says "reflect" or "/reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## Process

### 1. Locate the active transcript

The parent finds its own transcript before fanning out. Paths below are relative to this skill's directory (`skills/reflect/` in the ai-harness repo, linked into `${CLAUDE_CONFIG_DIR:-~/.claude}/skills/reflect/`).

```bash
scripts/transcripts.sh current
```

It prints `$CLAUDE_CONFIG_DIR/projects/<cwd-slug>/$CLAUDE_CODE_SESSION_ID.jsonl`. It matches this session's file name only, so it never opens chats from unrelated projects. Do not glob or read across `projects/*/` yourself.

Layout next to the main transcript:

- `<session-id>/subagents/agent-<id>.jsonl`: each subagent's transcript, with `agent-<id>.meta.json` naming its `agentType` and `model`.
- `<session-id>/tool-results/`: tool output too large to inline.

Under Codex, the session is the newest `rollout-*.jsonl` under `~/.codex/sessions/YYYY/MM/DD/` (or `$CODEX_HOME/sessions`) whose first line's `payload.cwd` is this project. `scripts/transcripts.sh codex 1 <project-path>` lists its prompts.

Render a readable view once, so reviewers don't parse megabytes of JSON:

```bash
scripts/transcripts.sh view "<transcript>" > "<scratchpad>/reflect-view.txt"
```

One line per event: `USER:`, `ASSISTANT:`, `TOOL <name>: <input>`, `RESULT: <first 400 chars>`, and `SKILLS LISTED:` (the model-invocable skills the session could see). Pass both paths to the reviewers: the view to read, the raw file for exact quotes. Match inside transcripts with `jq` `test()`, not raw `grep`: the JSON is escaped and the operator's prompts are often not ASCII.

If no transcript resolves, write a tight digest of the session and pass that instead.

### 2. Spawn three reviewers in parallel

One message, three `Agent` calls:

| Lens | `subagent_type` | Prompt template |
|---|---|---|
| Judgment | `deep-reasoner` | `references/judgment-reviewer.md` |
| Tooling | `fast-worker` | `references/tooling-reviewer.md` |
| Divergent | `deep-reasoner` | `references/divergent-reviewer.md` |

Pass each template verbatim, substituting the view path, the raw transcript path, or the digest where marked. Reviewers keep MCP access for lookups the transcript references (tickets, chat threads, traces); the templates forbid file edits. Reviewers return findings in their final report.

### 3. Synthesize

One `Agent` call, `subagent_type: "deep-reasoner"`, with `references/synthesizer.md` verbatim and each reviewer's full output inlined where marked. The synthesizer spot-verifies citations and returns a structured Accepted / Rejected / Backlog list.

### 4. Structural enforcement check

Sanity-check the Accepted list:

- An item a lint rule, type, script, hook, permission rule, metadata flag, or runtime check would enforce more reliably than prose moves to Backlog. See the **principle-encode-lessons-in-structure** skill. Prose is for judgment calls no mechanism can check.
- A `tune description` row on a skill with `disable-model-invocation: true` cannot work: Claude Code never auto-loads those skills, whatever the description says. Re-route it to the step that should have run the skill: a `harness-mode` trigger or playbook step, or the harness-mode routing section of AGENTS.md.

### 5. Apply

Present the synthesizer's full Accepted / Rejected / Backlog output to the user and wait for explicit approval. Ask with `AskUserQuestion` (multi-select, one option per row) when the rows fit its option limit. Otherwise number the rows and ask which numbers to apply. The user may also redirect routings. Skill changes steer every future session. Do not auto-apply.

Backlog items do not wait for approval. They leave this skill:

- A repeated mistake in a project's code (needs a lint, type, test, or CI check): name it as a `/correct` class in the summary. `correct` builds and proves the check.
- A harness-level mechanism (a hook, a script, `install.sh`, agent frontmatter): file an issue on the ai-harness repo with `gh issue create`. If `gh` is not authenticated, list the item with the command to file it.

For each approved Accepted item, follow the Routing field exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): the parent edits directly.
- Substantive existing-skill edit (a new section, a new pattern table, more than ~10 lines): run the Authoring a skill playbook (`../harness-mode/playbooks/authoring-a-skill.md`), which uses the `creating-skills` skill's draft, test, iterate loop.
- `tune description: <skill path>` (a model-invocable skill that didn't trigger when it should have): rewrite the description per `creating-skills` (what it does plus when, trigger terms first, at most 1024 characters), then test it on the phrasing that missed with a fresh subagent.
- `missed step: <harness-mode trigger or playbook step>` (a user-invoked skill that should have run): edit that trigger or step so it names the skill at the moment it applies.
- `new skill via creating-skills: <kebab-name>`: hand creation to `creating-skills`. Do not invent the shape ad hoc.

Where edits land:

- Harness skills live in the ai-harness repo (`skills/<name>/`). `${CLAUDE_CONFIG_DIR:-~/.claude}/skills/<name>` is a symlink into it, so an edit lands on whatever branch `~/ai-harness` has checked out: run `git -C ~/ai-harness switch -c reflect/<topic>` before the first edit. Project-local skills live in the project's `.claude/skills/`.
- An edit to AGENTS.md, `agents/*.md` or `skills/harness-mode/SKILL.md` also updates PLAYBOOK.html in the same change (AGENTS.md's sync rule); other skill edits do not.
- Ship through `code-committer`: a branch and a PR, never a push to main.

Before declaring done, check every touched SKILL.md against the `creating-skills` core rules: `name` equals the directory name, `description` is at most 1024 characters and says what plus when, the body is under 500 lines.

### 6. Summarize for the user

Harness output style (AGENTS.md "Output style"). Lead with what changed:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog: the issue link, or the `/correct` class to run. One line each.
- Dropped: one line per rejected finding with the synthesizer's reason.
- The PR link.

Cap each list at 5 and give the count of the rest. End with the one next action, for example: review the PR, about 5 minutes.
