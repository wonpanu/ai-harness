# ai-harness

AI coding-agent harness: one orchestrator routing work to pinned agents behind a
PRD gate, plus code-style skills loaded per stack and a frontier-discipline skill
for cheaper models. Built for Claude Code; the portable rules also work with any
tool that reads [AGENTS.md](AGENTS.md) (Codex, Cursor, Gemini CLI, Zed, …).

**One source of truth:** [AGENTS.md](AGENTS.md) holds everything — orchestration
workflow, delegate rules, PRD gate, code style, practices. `CLAUDE.md` is a symlink
to it, so Claude Code and every AGENTS.md-reading tool follow the same file with
nothing maintained twice. Tools with subagents map the roles to [agents/](agents/);
tools without apply each role's discipline inline.

Open `PLAYBOOK.html` for the interactive version (flow diagram with clickable nodes).

## Flow

```mermaid
flowchart LR
    REQ([Requirement]) --> ORCH
    ORCH{"Orchestrator<br/>fable / gpt-6-astra · PRD gate"}
    ORCH -->|"solo (default)"| SYN(( ))
    ORCH -->|reasoning-heavy| DEEP["deep-reasoner<br/>opus-5-5 / gpt-6-sol · xhigh"]
    ORCH -->|mechanical bulk| FAST["fast-worker<br/>sonnet-5 / gpt-6-luna · medium"]
    ORCH -->|multi-file search| EXP["Explore<br/>read-only"]
    ORCH -->|high-stakes 2nd opinion| PEER["Peer<br/>session model · fresh ctx"]
    ORCH -->|internet research| WEB["web-searcher<br/>haiku-4.5 / gpt-6-luna"]
    ORCH -->|commit on instruction| COMMIT["code-committer<br/>haiku-4.5 / gpt-6-luna"]
    DEEP --> SYN
    FAST --> SYN
    EXP --> SYN
    PEER --> SYN
    WEB --> SYN
    COMMIT --> SYN
    SYN -->|synthesize| REV["senior-lead-reviewer<br/>opus-5-5 / gpt-6-sol · xhigh · fresh ctx"]
    REV --> SHIP([Ship])
```

Rules of the road: default is **solo** (one-turn work is never delegated); every
requirement gets a brief **PRD** (goal + acceptance criteria + context) passed to
every worker and reviewer; ambiguous domain terms get resolved against project
docs (`grill-with-docs`) **before** the PRD is drafted.

## Agents

| Agent | Claude · effort | OpenAI (Codex) | Role |
|---|---|---|---|
| **Orchestrator** | session model (fable · high) | gpt-6-astra · high | The main loop. Plans, decomposes, synthesizes; writes the PRD (goal + acceptance criteria + context) before any delegation. Does one-turn work itself — delegates only when a condition below clearly applies. |
| **deep-reasoner** | opus-5-5 · xhigh | gpt-6-sol · xhigh | Reasoning-heavy phases: architecture, complex debugging, algorithm design, trade-off analysis. Returns a concise conclusion — decision, key evidence, rejected alternatives. |
| **fast-worker** | sonnet-5 · medium | gpt-6-luna · medium | Mechanical, well-specified bulk work: multi-file renames, boilerplate, test scaffolds. Executes the spec exactly, no scope expansion; verifies with a cheap check. |
| **Explore** (built-in) | inherits session | — (Claude Code only) | Read-only search across many files/directories when reading exceeds answering. Locates code, returns conclusions — never reviews or edits. |
| **Peer** | session model · fresh context | gpt-6-astra · fresh context | An engineer on par with deep-reasoner, from a different perspective — a peer, not a reviewer. Works the same high-stakes problem independently; the orchestrator synthesizes without showing either the other's answer. |
| **web-searcher** | haiku-4.5 | gpt-6-luna · low | Internet research: docs, library versions, error messages, current facts. Prefers primary sources, cross-checks surprises, returns answer + source URLs; says so when sources conflict — never guesses. |
| **code-committer** | haiku-4.5 | gpt-6-luna · low | Commits finished work on instruction from the orchestrator or another worker. Reads the actual diff before writing the message, stages only relevant files, matches repo convention. Never edits code; pushes only when explicitly told. |
| **senior-lead-reviewer** | opus-5-5 · xhigh · fresh context | gpt-6-sol · xhigh | Reviews work about to merge/ship (plans, diffs, designs) through a maintainability / tech-debt / operability lens — distinct from peer (correctness) and ponytail (over-engineering). Receives the PRD so review targets the real acceptance criteria. |

**Codex CLI:** `install.sh` also links `~/.codex/AGENTS.md` → `AGENTS.md` and `~/.codex/config.toml` → [codex/config.toml](codex/config.toml), which defines the same roles as `[agents.*]` on the OpenAI tier map (astra ≈ Fable, sol ≈ Opus, luna ≈ Sonnet/Haiku).

## New machine

Paste this into any AI coding agent on the new machine (it needs a shell and a browser you can reach):

```text
Set this machine up from https://github.com/wonpanu/ai-harness.
1. Clone it to ~/ai-harness and read README.md and bootstrap.sh before running anything.
2. Ask me one question, multi-select: which AI providers to connect — Claude, OpenAI, or both. Do not ask about model choices: model tiers are fixed by the repo (agents/*.md, codex/config.toml, claude/settings.json) — apply them as-is.
3. Run ./bootstrap.sh. If I chose more than one Claude account, run it with PROFILES="<one short name per extra account>" and tell me the CLAUDE_CONFIG_DIR to use for each.
4. Then walk me through the logins in this order, one at a time, waiting for me to confirm each: (a) install Orca from https://www.onorca.dev and open it; (b) in Orca, add an account for each provider I chose — Claude first, then OpenAI; (c) `claude` sign-in per profile; (d) `codex login` if OpenAI was chosen; (e) `gh auth login`.
5. Verify: `claude --version`, `codex --version` (if chosen), `ls -l ~/.claude/agents ~/.codex/config.toml` show symlinks into ~/ai-harness, and Orca's hooks exist in ~/.orca/agent-hooks. Report what works and what is left.
Never print or ask for account names, emails, or tokens; refer to accounts only as "your Claude account" / "your OpenAI account".
```

What `bootstrap.sh` does (idempotent, ~3 min): installs node/jq/gh/claude/codex via brew+npm, then applies both providers' config — Claude: merges [claude/settings.json](claude/settings.json) (model, effort, plugins, TUI prefs — no secrets, no machine paths) over `~/.claude/settings.json` and installs [claude/statusline-command.sh](claude/statusline-command.sh); OpenAI: symlinks [codex/config.toml](codex/config.toml) (session model + `[agents.*]` roles) to `~/.codex/config.toml` — adds the ponytail + i-have-adhd plugins, and runs `install.sh` for `~/.claude`, `~/.codex` and each `PROFILES` entry (`~/.claude-<name>`, sharing settings and skills with `~/.claude`). Logins and the Orca app are the only manual steps; Orca writes its own hooks into `~/.claude/settings.json` and `~/.orca/agent-hooks`, and account tokens stay in Orca's app data, never in this repo.

## Second brain

| Area | What it holds | Read |
|---|---|---|
| Orchestration & delegate rules | Who does what, when to delegate, PRD gate | [CLAUDE.md](CLAUDE.md) |
| Agent definitions | Models, effort levels, per-agent instructions | [agents/](agents/) |
| Go backend style | Guard ladders, naming, layering, tests | [skills/go-backend-style/SKILL.md](skills/go-backend-style/SKILL.md) · [examples](skills/go-backend-style/EXAMPLES.md) |
| React frontend style | Hooks, state shape, gate components, strict TS | [skills/react-frontend-style/SKILL.md](skills/react-frontend-style/SKILL.md) · [examples](skills/react-frontend-style/EXAMPLES.md) |
| Tailwind CSS style | Semantic tokens, cn(), inline-style rules | [skills/tailwindcss-style/SKILL.md](skills/tailwindcss-style/SKILL.md) |
| TanStack Query style | Key factories, domain hooks, invalidation | [skills/tanstack-query-style/SKILL.md](skills/tanstack-query-style/SKILL.md) |
| Frontier mode | Frontier-discipline scaffold + checklist | [skills/frontier-mode/SKILL.md](skills/frontier-mode/SKILL.md) |
| Creating skills | Pattern-per-use-case skill authoring guide | [skills/creating-skills/SKILL.md](skills/creating-skills/SKILL.md) |
| Output style | ADHD-friendly response shape (action-first, numbered, no preamble) | [AGENTS.md § Output style](AGENTS.md#output-style) · [i-have-adhd](https://github.com/ayghri/i-have-adhd) |
| Visual playbook | Everything above as one interactive page | [PLAYBOOK.html](PLAYBOOK.html) |

## Layout

- `AGENTS.md` — global rules: orchestration workflow, delegate conditions, PRD gate, universal code style, general practice (`CLAUDE.md` symlinks here)
- `PLAYBOOK.html` — visual version of AGENTS.md (kept in sync by rule)
- `install.sh` — symlinks everything into `~/.claude` (see Install)
- `agents/` — subagent definitions: `deep-reasoner` (opus-5-5/xhigh), `fast-worker` (sonnet-5/medium), `web-searcher` (haiku-4.5), `code-committer` (haiku-4.5), `senior-lead-reviewer` (opus-5-5/xhigh)
- `skills/` — on-demand skills: `go-backend-style`, `react-frontend-style` (each with EXAMPLES.md), `tailwindcss-style`, `tanstack-query-style`, `frontier-mode`, `creating-skills`

## Install

```sh
git clone git@github.com:wonpanu/ai-harness.git ~/ai-harness
cd ~/ai-harness && make install   # harness only; new machine: ./bootstrap.sh (see below)
claude plugin marketplace add ayghri/i-have-adhd && claude plugin install i-have-adhd@i-have-adhd   # always-on via .i-have-adhd-always (install.sh); short form in AGENTS.md
npx skills add ayghri/i-have-adhd -g -a cursor -y   # same skill for Cursor (lands in ~/.agents/skills)
```

`CLAUDE.md`, agents and skills are symlinked, so `git pull` updates them live. A pre-existing regular-file `CLAUDE.md` is backed up to
`CLAUDE.md.bak` first. Install into a different profile with
`CLAUDE_DIR=~/.claude-x ~/ai-harness/install.sh`.

**Customize models:** edit `model:` / `effort:` in `agents/*.md` — the symlink makes it live at once.

## License

MIT — see [LICENSE](LICENSE).
