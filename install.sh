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

for agent in "$HARNESS_DIR"/agents/*.md; do
    ln -sf "$agent" "$CLAUDE_DIR/agents/$(basename "$agent")"
done

for skill in "$HARNESS_DIR"/skills/*/; do
    name=$(basename "$skill")
    # replace a real directory from an old copy-based install with the symlink
    [ -d "$CLAUDE_DIR/skills/$name" ] && [ ! -L "$CLAUDE_DIR/skills/$name" ] && rm -rf "$CLAUDE_DIR/skills/$name"
    ln -sfn "${skill%/}" "$CLAUDE_DIR/skills/$name"
done

echo "installed: CLAUDE.md -> AGENTS.md, $(ls "$HARNESS_DIR"/agents/*.md | wc -l | tr -d ' ') agents, $(ls -d "$HARNESS_DIR"/skills/*/ | wc -l | tr -d ' ') skills into $CLAUDE_DIR"
echo "other AI tools: point them at $HARNESS_DIR/AGENTS.md (most read AGENTS.md from a project root automatically)"
