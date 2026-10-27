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
FLOW_LINE='{"components": [{"id": ".", "kind": "service", "entry": "main.go:1", "does": "publishes orders"}], "flows": [{"from": ".", "to": "sqs:orders", "kind": "publishes", "via": "ORDERS_QUEUE", "evidence": "pub.go:9"}]}'
printf -- '---\nrepo: alpha\npath: %s\nmapped_sha: abc1234def\nmapped_at: 2026-10-27\n---\n## What it is\nAlpha publishes `orders` (observation, `pub.go:9`).\n\n## Flow\n```json\n%s\n```\n\n## Edges\n```json\n[]\n```\n' "$ROOT/alpha" "$FLOW_LINE" > "$KNOWLEDGE/work/alpha.md"
printf -- '---\nrepo: gamma\npath: %s\nmapped_sha: 0123456789\nmapped_at: 2026-10-27\n---\n## What it is\nGamma has no flow yet.\n\n## Edges\n```json\n[]\n```\n' "$ROOT/gamma" > "$KNOWLEDGE/work/gamma.md"
cat > "$KNOWLEDGE/work/graph.json" <<JSON
{"nodes": [{"id": "alpha", "path": "$ROOT/alpha", "mapped_sha": "abc1234def"}, {"id": "gamma", "path": "$ROOT/gamma", "mapped_sha": "0123456789"}],
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
expect "page data carries alpha's flow block, components first" yes "$(contains "$OUT" '"flows": {"alpha": {"components": [{"id": ".", "kind": "service", "entry": "main.go:1", "does": "publishes orders"}], "flows": [{"from": ".", "to": "sqs:orders", "kind": "publishes", "via": "ORDERS_QUEUE", "evidence": "pub.go:9"}]}')"
expect "page data has no flow key for a repo whose md lacks a Flow block" no "$(contains "$OUT" '"gamma": {"components"')"
expect "flow json block is dropped from the notes" no "$(contains "$OUT" '<h3>Flow<\/h3>')"

# Act
sed -n '/^<script>$/,/^<\/script>$/p' "$OUT" | sed '1d;$d' > "$TMP/inline.js"
node --check "$TMP/inline.js" 2>"$TMP/err"; status=$?
# Assert
expect "the page's inline script parses" 0 "$status"
expect "the page script draws the per-repo flow diagram" yes "$(contains "$TMP/inline.js" 'drawFlow(')"

# Act
python3 -I "$HERE/../../knowledge-render.py" --root missing >/dev/null 2>"$TMP/err"; status=$?
# Assert
expect "unknown folder fails" 1 "$status"
echo "all cases passed"
