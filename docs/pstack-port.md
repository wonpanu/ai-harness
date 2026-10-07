# pstack port: PRD and translation glossary

Source: https://github.com/cursor/plugins/tree/main/pstack (MIT, by poteto / Lauren Tan), snapshot v0.15.15, ported 2026-10-07.

## Goal

Bring pstack's rigor machinery into this harness so agents follow the agreed practices without being re-prompted every session: a mode skill that matches each task to a playbook and copies the steps into the todo list, a principles index the mode cites, and the workflow skills the playbooks route to (how, why, interrogate, reflect, correct, ...). Everything is renamed to fit this harness's roles and Claude Code / Codex tooling. pstack is a source of patterns, not a verbatim copy.

## Acceptance criteria

1. `skills/harness-mode/SKILL.md` exists, routes to playbooks under `skills/harness-mode/playbooks/`, and names only agents, skills and tools that exist in this harness or in Claude Code.
2. Every `skills/principle-*/SKILL.md` ports with its rule intact; references to `poteto-mode` become `harness-mode`.
3. Every workflow skill listed under "Ported" below exists under `skills/<name>/` with valid Claude Code frontmatter (`name`, `description`, optional `disable-model-invocation`). Cursor-only frontmatter keys (`mode`, `icon`, `color`, `reminder`, `is_background`) are gone.
4. `agents/harness-agent.md` and `agents/comment-reviewer.md` exist with Claude Code agent frontmatter; `codex/config.toml` + `codex/agents/*.toml` mirror them.
5. No file contains a dangling reference to a Cursor-only thing (`Task` tool, `AskQuestion`, `create-skill`, `deslop`, `cursor-team-kit`, `control-ui`, `control-cli`, `Origin`, `drive`, `~/.cursor`, `generalPurpose`, grok slugs). `grep -rn` for each returns nothing under `skills/`, `agents/`, `docs/`.
6. `AGENTS.md`, `README.md`, `INSTALL.md`, `PLAYBOOK.html` describe the new routing. `install.sh` moves a pre-existing real `~/.claude/skills/<name>` directory to `~/.claude/skills-backup/<name>` instead of deleting it (a `.bak` inside `skills/` would still load as a skill).
7. Chat replies keep the harness output style (i-have-adhd); pstack's reply rules apply to written artifacts (docs, PR bodies, skills, commit messages), not to chat.

## Translation glossary (apply everywhere)

| pstack (Cursor) | this harness (Claude Code / Codex) |
|---|---|
| `poteto-mode`, `/poteto-mode`, "poteto's style" | `harness-mode`, `/harness-mode`, "the harness style" |
| `poteto-agent` (`subagent_type: "poteto-agent"`) | `harness-agent` (`subagent_type: "harness-agent"`) |
| Comment Sicko (`subagent_type: "Comment Sicko"`) | `comment-reviewer` (`subagent_type: "comment-reviewer"`) |
| `poteto-help` | `harness-help` |
| pstack (the plugin) | ai-harness (the repo) |
| `Task` tool, `Task` call | `Agent` tool, `Agent` call |
| `run_in_background: true` default | omit (Claude Code runs subagents in the background by default) |
| `generalPurpose` | `general-purpose` |
| `AskQuestion` | `AskUserQuestion` |
| `create-skill` (Cursor built-in) | `creating-skills` skill (this harness) |
| `deslop` from `cursor-team-kit` | `simplifying-code` skill (this harness) |
| `control-cli`, `control-ui` from `cursor-team-kit` | `run` skill (Claude Code) for CLIs and servers; `claude-in-chrome` skill for browser UIs |
| Bugbot, "agentic security review" | review bots: Claude Code `/code-review`, GitHub review bots, `/security-review` |
| `drive` tool, Cursor's built-in babysit | Claude Code `/loop` + `gh pr checks --watch` + `Monitor` tool |
| Origin (stacking CLI) | dropped. `gh` only, bottom-up through the stack |
| `/loop` | `/loop` (same in Claude Code) |
| Cursor custom mode (option+enter) | always on: AGENTS.md tells the orchestrator to apply `harness-mode` at task start |
| `~/.cursor/rules/*.mdc`, `.cursor/rules` | `AGENTS.md` (global) or the project's `CLAUDE.md` |
| `.cursor/skills/<name>/` | `skills/<name>/` in this repo, or `.claude/skills/<name>/` for project-local skills |
| Cursor transcripts / chat history | Claude Code transcripts: `$CLAUDE_CONFIG_DIR/projects/<cwd-slug>/*.jsonl` (here `~/.claude-fenrir/projects/`); Codex: `~/.codex/sessions/` |
| `grok-4.7-xhigh-fast` as code delegate | `harness-agent` (session model, fresh context). Hardest changes: `deep-reasoner` |
| `grok-4.7-xhigh-fast` as explorer / investigator / swarm worker | `fast-worker` for mechanical sweeps; `Explore` for read-only search; `harness-agent` when judgment is needed |
| `claude-opus-5-5-xhigh` as judgment / prose / synthesizer / judge | `deep-reasoner` |
| multi-model panel (arena runners, architect runners, interrogate reviewers) | `deep-reasoner` + `harness-agent` + one Codex run: `codex exec -c model="gpt-6-sol" -c model_reasoning_effort="xhigh" "<prompt>"` |
| `/setup-pstack` per-role model rule | dropped. Models are pinned in `agents/*.md` frontmatter and `codex/agents/*.toml` |
| reply style ("Writing the reply", unslop in chat) | chat replies follow i-have-adhd (AGENTS.md Output style). unslop / technical-writing apply to docs, PR bodies, commit messages, skills |
| "name each principle that shaped a decision" | one line at most in the reply, e.g. `principles: laziness-protocol, prove-it-works` |
| Grok Bot, webhook routines | not ported |

## Ported

- Mode: `harness-mode` (+ `playbooks/`, `references/bugbot-triage.md` → `references/review-bot-triage.md`, `scripts/worktree-audit.sh`)
- Agents: `harness-agent`, `comment-reviewer`
- Principles: all 24 `principle-*`
- Workflow: `how`, `why`, `recall`, `blast-radius`, `architect`, `arena`, `swarm`, `interrogate`, `reflect`, `correct`, `teach`, `figure-it-out`, `automate-me`, `harness-help`, `benchmark-checklist`, `no-comments`, `show-me-your-work` (+ `scripts/log.sh`), `unslop`, `bro`, `technical-writing`, `typescript-best-practices`, `create-verification-skill`, `maintain-verification-skill`
- Docs: `docs/guide/` adapted

## Not ported, and why

- `setup-pstack`: model per role is pinned in agent frontmatter here.
- `make-bot-ui`: Grok Bot webhook UI, no equivalent.
- pstack's `tdd`: replaced by Matt Pocock's `tdd` skill (https://github.com/mattpocock/skills, MIT) plus its `codebase-design` companion, ported under `skills/tdd/` and `skills/codebase-design/` and made mandatory for every behavior change in `harness-mode`. The older copy at `~/.claude/skills/tdd` is moved to `~/.claude/skills-backup/tdd` by `install.sh`.
- `automations/benny`: Cursor Automations product.
- `poteto-mode/scripts/{orch,watch-pr,check-plan.mjs,bootstrap.ts}`: bun/TypeScript tooling built around Cursor's `drive` and plan format. Playbooks that used them fall back to `gh` + `/loop`.
- `.cursor-plugin/plugin.json`, `assets/`.
