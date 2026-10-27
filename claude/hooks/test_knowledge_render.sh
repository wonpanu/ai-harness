#!/bin/sh
# Runs knowledge-render.py against a fixture knowledge folder; exit 1 on the first failed case.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"; mkdir -p "$HOME"
export CLAUDE_CONFIG_DIR="$TMP/home/.claude"
KNOWLEDGE="$CLAUDE_CONFIG_DIR/knowledge"
ROOT="$TMP/work"
mkdir -p "$KNOWLEDGE/work" "$ROOT/alpha" "$ROOT/beta" "$ROOT/notes"
git init -q "$ROOT/alpha"; git init -q "$ROOT/beta"
printf '{"roots": ["%s"]}' "$ROOT" > "$KNOWLEDGE/roots.json"
printf -- '---\nrepo: alpha\npath: %s\nmapped_sha: abc1234def\nmapped_at: 2026-10-27\n---\n## What it is\nAlpha publishes `orders` (observation, `pub.go:9`).\n\n## Edges\n```json\n[]\n```\n' "$ROOT/alpha" > "$KNOWLEDGE/work/alpha.md"
cat > "$KNOWLEDGE/work/graph.json" <<JSON
{"nodes": [{"id": "alpha", "path": "$ROOT/alpha", "mapped_sha": "abc1234def"}],
 "edges": [{"from": "alpha", "to": "sqs:orders", "kind": "publishes", "via": "orders", "evidence": "pub.go:9"}]}
JSON

expect() { # $1 label, $2 want, $3 got
  if [ "$2" = "$3" ]; then echo "ok   $1"; else printf 'FAIL %s:\n want: %s\n got:  %s\n' "$1" "$2" "$3"; cat "$TMP/err" 2>/dev/null; exit 1; fi
}
contains() { grep -qF -- "$2" "$1" && echo yes || echo no; }

# Arrange
OUT="$KNOWLEDGE/work/index.html"
# Act
python3 -I "$HERE/../../knowledge-render.py" --root work > "$TMP/out" 2>"$TMP/err"; status=$?
# Assert
expect "render exits 0" 0 "$status"
expect "render prints the output path" "rendered $OUT" "$(cat "$TMP/out")"
expect "page title names the folder" yes "$(contains "$OUT" "<title>Work Knowledge Map</title>")"
expect "page data holds the edge" yes "$(contains "$OUT" '"to": "sqs:orders"')"
expect "page data lists beta as unmapped, not the non-repo notes folder" yes "$(contains "$OUT" '"unmapped": ["beta"]')"
expect "notes are rendered to html without the Edges block" yes "$(contains "$OUT" '<h3>What it is<\/h3><p>Alpha publishes <code>orders<\/code> (observation, <code>pub.go:9<\/code>).<\/p>')"
expect "edges json block is dropped from the notes" no "$(contains "$OUT" '<h3>Edges<\/h3>')"

# Act
python3 -I "$HERE/../../knowledge-render.py" --root missing >/dev/null 2>"$TMP/err"; status=$?
# Assert
expect "unknown folder fails" 1 "$status"
echo "all cases passed"
