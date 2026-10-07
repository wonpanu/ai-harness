# How to install

Agent-facing procedure. A human can follow it too, but the README's one-line prompt is meant to hand this file to an AI coding agent.

## Procedure (agent)

1. Clone to `~/ai-harness` and read `README.md`, this file and `bootstrap.sh` before running anything.
2. Ask the user one question, multi-select: which AI providers to connect — **Claude**, **OpenAI**, or both. Do not ask about models: tiers are fixed by the repo (`agents/*.md`, `codex/config.toml`, `codex/agents/*.toml`, `claude/settings.json`) — apply them as-is.
3. Run `./bootstrap.sh`. If the user has more than one Claude account, run `PROFILES="<one short name per extra account>" ./bootstrap.sh` and tell them the `CLAUDE_CONFIG_DIR=~/.claude-<name>` to use for each.
4. Walk the logins in this order, one at a time, waiting for confirmation after each:
   1. Install [Orca](https://www.onorca.dev) and open it once (it writes its hooks into `~/.claude/settings.json` and `~/.orca/agent-hooks`).
   2. In Orca, add an account for each chosen provider — Claude first, then OpenAI.
   3. `claude` → sign in, once per profile.
   4. `codex login` → sign in with ChatGPT (Plus is enough) — only if OpenAI was chosen.
   5. `gh auth login`.
5. Verify (below) and report what works and what is left.

Never print or ask for account names, emails or tokens; refer to them only as "your Claude account" / "your OpenAI account". Do not read `~/.claude/.claude.json`, `~/.codex/auth.json` or Orca's app data.

## What `bootstrap.sh` does

Idempotent, ~3 min, safe to re-run:

- installs `node`, `jq`, `gh` (brew) and `claude`, `codex` (npm) if missing
- **Claude:** merges [claude/settings.json](claude/settings.json) (model, effort, plugins, TUI prefs — no secrets, no machine paths) over `~/.claude/settings.json`, unioning `permissions` (deny rules for pushes to main) and `hooks` (the harness-mode `UserPromptSubmit` reminder) with the machine's own rules and Orca's hooks; installs [claude/statusline-command.sh](claude/statusline-command.sh)
- **OpenAI:** `install.sh` symlinks [codex/config.toml](codex/config.toml) (session model + `[agents.*]` roles) to `~/.codex/config.toml` and `AGENTS.md` to `~/.codex/AGENTS.md`. Each role's model, effort and instructions live in [codex/agents/](codex/agents/); `config.toml` references them as `~/ai-harness/codex/agents/<role>.toml`, so the repo must stay at `~/ai-harness`
- **Orca keeps its own copy:** Orca runs Codex with a managed home (`$CODEX_HOME` inside an Orca terminal) whose `config.toml` is copied when the account is added. Later edits to `codex/config.toml` do not reach that copy; re-apply the `[agents.*]` section there by hand
- adds the [i-have-adhd](https://github.com/ayghri/i-have-adhd) plugin (always-on via hook)
- runs `install.sh` for `~/.claude`, `~/.codex` and each `PROFILES` entry (`~/.claude-<name>`, sharing settings and skills with `~/.claude`)
- symlinks every skill into `~/.agents/skills` too, the Agent Skills standard directory that Codex and Gemini CLI read

## Verify

```sh
claude --version && codex --version
ls -l ~/.claude/CLAUDE.md ~/.claude/agents ~/.codex/config.toml   # symlinks into ~/ai-harness
ls ~/.orca/agent-hooks                                             # claude-hook.sh codex-hook.sh (after Orca's first launch)
```

## Update

```sh
cd ~/ai-harness && make update   # git pull + re-link; agents/skills are symlinks, so edits are live without this
```

## Harness only (existing machine)

```sh
cd ~/ai-harness && make install                          # ~/.claude + ~/.codex
CLAUDE_DIR=~/.claude-<name> ./install.sh                 # extra Claude profile
```

A pre-existing regular-file `CLAUDE.md` is backed up to `CLAUDE.md.bak`. `install.sh` only replaces a real `~/.claude/skills/<name>` directory when the harness ships a skill of that name, so skills installed from elsewhere (e.g. `tdd`, `grill-me`, `handoff`) are untouched. **Customize models:** edit `model:` / `effort:` in `agents/*.md`, or `model` / `model_reasoning_effort` in `codex/agents/*.toml` — live at once.

## Uninstall

```sh
rm ~/.claude/CLAUDE.md ~/.claude/agents/* ~/.claude/skills/* ~/.codex/AGENTS.md ~/.codex/config.toml
find ~/.agents/skills -type l -lname "$HOME/ai-harness/*" -delete   # only the links this repo made
claude plugin uninstall i-have-adhd
```
