# How to install

Agent-facing procedure. A human can follow it too, but the README's one-line prompt is meant to hand this file to an AI coding agent.

## Procedure (agent)

1. Clone to `~/ai-harness` and read `README.md`, this file and `bootstrap.sh` before running anything.
2. Ask the user one question, multi-select: which AI providers to connect — **Claude**, **OpenAI**, or both. Do not ask about models: tiers are fixed by the repo (`agents/*.md`, `codex/config.toml`, `claude/settings.json`) — apply them as-is.
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
- **Claude:** merges [claude/settings.json](claude/settings.json) (model, effort, plugins, TUI prefs — no secrets, no machine paths) over `~/.claude/settings.json`, keeping machine-local `permissions` and Orca's `hooks`; installs [claude/statusline-command.sh](claude/statusline-command.sh)
- **OpenAI:** `install.sh` symlinks [codex/config.toml](codex/config.toml) (session model + `[agents.*]` roles) to `~/.codex/config.toml` and `AGENTS.md` to `~/.codex/AGENTS.md`
- adds the [ponytail](https://github.com/DietrichGebert/ponytail) and [i-have-adhd](https://github.com/ayghri/i-have-adhd) plugins (always-on via hooks)
- runs `install.sh` for `~/.claude`, `~/.codex` and each `PROFILES` entry (`~/.claude-<name>`, sharing settings and skills with `~/.claude`)

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

A pre-existing regular-file `CLAUDE.md` is backed up to `CLAUDE.md.bak`. **Customize models:** edit `model:` / `effort:` in `agents/*.md` or `codex/config.toml` — symlinked, live at once.

## Uninstall

```sh
rm ~/.claude/CLAUDE.md ~/.claude/agents/* ~/.claude/skills/* ~/.codex/AGENTS.md ~/.codex/config.toml
claude plugin uninstall ponytail i-have-adhd
```
