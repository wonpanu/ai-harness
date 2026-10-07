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

echo "installed: CLAUDE.md -> AGENTS.md, $(ls "$HARNESS_DIR"/agents/*.md | wc -l | tr -d ' ') agents, $(ls -d "$HARNESS_DIR"/skills/*/ | wc -l | tr -d ' ') skills into $CLAUDE_DIR and $CROSS_TOOL_SKILLS_DIR; codex: ~/.codex/AGENTS.md + config.toml"
echo "other AI tools: point them at $HARNESS_DIR/AGENTS.md (most read AGENTS.md from a project root automatically)"
