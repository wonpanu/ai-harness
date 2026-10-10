#!/bin/sh
# Installs this harness into the local machine's Claude Code config via symlinks,
# so a `git pull` here updates the live setting — nothing is maintained twice.
# Usage: ./install.sh            (installs into ~/.claude)
#        CLAUDE_DIR=~/.claude-x ./install.sh
set -eu

HARNESS_DIR=$(cd "$(dirname "$0")" && pwd)
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills"

# back up a pre-existing regular-file CLAUDE.md once; symlinks are just replaced
if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && [ ! -L "$CLAUDE_DIR/CLAUDE.md" ]; then
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
    echo "backed up existing CLAUDE.md -> CLAUDE.md.bak"
fi

ln -sf "$HARNESS_DIR/AGENTS.md" "$CLAUDE_DIR/CLAUDE.md"

# i-have-adhd plugin: flag makes its SessionStart hook load the full ruleset every session
touch "$CLAUDE_DIR/.i-have-adhd-always"

# agents symlinked like skills — edit agents/*.md frontmatter to change model/effort
for agent in "$HARNESS_DIR"/agents/*.md; do
    ln -sf "$agent" "$CLAUDE_DIR/agents/$(basename "$agent")"
done

# hooks: commit-guard blocks git commit/push and gh pr outside this repo unless the user asked this turn (commit-grant)
mkdir -p "$CLAUDE_DIR/hooks"
for hook in "$HARNESS_DIR"/claude/hooks/*.py; do
    ln -sf "$hook" "$CLAUDE_DIR/hooks/$(basename "$hook")"
done
# settings.json is a real file Claude Code rewrites, so the harness hooks are merged in, never symlinked
HARNESS_DIR="$HARNESS_DIR" CLAUDE_DIR="$CLAUDE_DIR" python3 - <<'PY'
import json, os
live_path = os.path.join(os.environ["CLAUDE_DIR"], "settings.json")
live = json.load(open(live_path)) if os.path.exists(live_path) else {}
harness = json.load(open(os.path.join(os.environ["HARNESS_DIR"], "claude", "settings.json")))
live_hooks = live.setdefault("hooks", {})
for event, groups in harness["hooks"].items():
    live_groups = live_hooks.setdefault(event, [])
    present = {hook["command"] for group in live_groups for hook in group.get("hooks", [])}
    for group in groups:
        missing = [hook for hook in group["hooks"] if hook["command"] not in present]
        if missing:
            live_groups.append({**group, "hooks": missing})
live.setdefault("permissions", {}).setdefault("deny", [])
for rule in harness["permissions"]["deny"]:
    if rule not in live["permissions"]["deny"]:
        live["permissions"]["deny"].append(rule)
json.dump(live, open(live_path, "w"), indent=2)
PY

# Codex CLI: same rules + role/model tiers mirrored in codex/config.toml
mkdir -p "$HOME/.codex"
ln -sf "$HARNESS_DIR/AGENTS.md" "$HOME/.codex/AGENTS.md"
[ -f "$HOME/.codex/config.toml" ] && [ ! -L "$HOME/.codex/config.toml" ] && cp "$HOME/.codex/config.toml" "$HOME/.codex/config.toml.bak"
ln -sf "$HARNESS_DIR/codex/config.toml" "$HOME/.codex/config.toml"

# Agent Skills standard dir: Codex and Gemini CLI discover skills here, so every skill works outside Claude Code
CROSS_TOOL_SKILLS_DIR="$HOME/.agents/skills"
mkdir -p "$CROSS_TOOL_SKILLS_DIR"

for skill in "$HARNESS_DIR"/skills/*/; do
    name=$(basename "$skill")
    # a real directory of the same name (old copy-based install, or a skill from elsewhere) moves out of skills/ so Claude Code stops loading it, never deleted
    if [ -d "$CLAUDE_DIR/skills/$name" ] && [ ! -L "$CLAUDE_DIR/skills/$name" ]; then
        mkdir -p "$CLAUDE_DIR/skills-backup"
        mv "$CLAUDE_DIR/skills/$name" "$CLAUDE_DIR/skills-backup/$name"
        echo "backed up existing skills/$name -> skills-backup/$name"
    fi
    ln -sfn "${skill%/}" "$CLAUDE_DIR/skills/$name"
    ln -sfn "${skill%/}" "$CROSS_TOOL_SKILLS_DIR/$name"
done

echo "installed: CLAUDE.md -> AGENTS.md, hooks merged into settings.json, $(ls "$HARNESS_DIR"/agents/*.md | wc -l | tr -d ' ') agents, $(ls -d "$HARNESS_DIR"/skills/*/ | wc -l | tr -d ' ') skills into $CLAUDE_DIR and $CROSS_TOOL_SKILLS_DIR; codex: ~/.codex/AGENTS.md + config.toml"
echo "other AI tools: point them at $HARNESS_DIR/AGENTS.md (most read AGENTS.md from a project root automatically)"
