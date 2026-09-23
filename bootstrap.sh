#!/bin/sh
# One-shot machine setup from this repo. Idempotent — safe to re-run.
# Usage: ./bootstrap.sh            (PROFILES="work other" adds one extra Claude config dir ~/.claude-<name> per extra Claude account)
set -eu
HARNESS_DIR=$(cd "$(dirname "$0")" && pwd)

command -v brew >/dev/null || { echo "install Homebrew first: https://brew.sh"; exit 1; }
command -v node >/dev/null || brew install node
command -v jq   >/dev/null || brew install jq
command -v gh   >/dev/null || brew install gh
command -v claude >/dev/null || npm install -g @anthropic-ai/claude-code
command -v codex  >/dev/null || npm install -g @openai/codex

# Claude settings: merge the versioned snapshot over the live file, keeping machine-local keys (permissions, hooks Orca writes)
mkdir -p "$HOME/.claude"
python3 - "$HARNESS_DIR/claude/settings.json" "$HOME/.claude/settings.json" <<'PY'
import json,sys,os
snap=json.load(open(sys.argv[1])); path=sys.argv[2]
live=json.load(open(path)) if os.path.exists(path) else {}
live.update(snap)
live["statusLine"]["command"]=os.path.expanduser(live["statusLine"]["command"])
json.dump(live,open(path,"w"),indent=2); open(path,"a").write("\n")
PY
cp "$HARNESS_DIR/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh" && chmod +x "$HOME/.claude/statusline-command.sh"

# plugins (both always-on via SessionStart hooks; enabledPlugins comes from the snapshot above)
claude plugin marketplace add DietrichGebert/ponytail >/dev/null 2>&1 || true
claude plugin marketplace add ayghri/i-have-adhd      >/dev/null 2>&1 || true
claude plugin install ponytail@ponytail       >/dev/null 2>&1 || true
claude plugin install i-have-adhd@i-have-adhd >/dev/null 2>&1 || true

# harness symlinks: ~/.claude, ~/.codex, plus optional extra profiles that share settings/skills with ~/.claude
"$HARNESS_DIR/install.sh"
for p in ${PROFILES:-}; do
    dir="$HOME/.claude-$p"
    mkdir -p "$dir"
    ln -sfn "$HOME/.claude/settings.json" "$dir/settings.json"
    ln -sfn "$HOME/.claude/skills" "$dir/skills"
    CLAUDE_DIR="$dir" "$HARNESS_DIR/install.sh"
done

cat <<TODO

done. Manual steps left (logins and the Orca app cannot be scripted):
  1. claude              → sign in (Claude subscription)
  2. codex login         → sign in with ChatGPT (Plus is enough)
  3. gh auth login
  4. Orca: download https://www.onorca.dev, open it, add your Claude and/or OpenAI account in-app.
     It writes its own hooks into ~/.claude/settings.json and ~/.orca/agent-hooks on first launch.
  Extra Claude account: re-run with PROFILES="<name>" and start Claude with CLAUDE_CONFIG_DIR=~/.claude-<name>
TODO
