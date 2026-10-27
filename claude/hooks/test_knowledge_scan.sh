#!/bin/sh
# Runs knowledge-scan.sh against fixture repos with a stub claude; exit 1 on the first failed case.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
SCAN="$HERE/../../knowledge-scan.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"; mkdir -p "$HOME"
export CLAUDE_DIR="$TMP/home/.claude"
export KNOWLEDGE_CLAUDE="$TMP/claude-stub"
export STUB_CALLS="$TMP/calls"
KNOWLEDGE="$CLAUDE_DIR/knowledge"
ROOT="$TMP/work"
mkdir -p "$KNOWLEDGE" "$ROOT/alpha" "$ROOT/beta" "$ROOT/notes"
git init -q "$ROOT/alpha"; git init -q "$ROOT/beta"
git -C "$ROOT/alpha" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$ROOT/beta" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
printf '{"roots": ["%s"]}' "$ROOT" > "$KNOWLEDGE/roots.json"
cat > "$KNOWLEDGE_CLAUDE" <<'EOF'
#!/bin/sh
echo "$(basename "$PWD")" >> "$STUB_CALLS"
echo "## What it is"
echo ""
echo "A fixture service (observation)."
[ "${STUB_MODE:-}" = "noedges" ] && exit 0
echo ""
echo "## Edges"
echo ""
echo '```json'
echo '[{"from": "'"$(basename "$PWD")"'", "to": "beta", "kind": "calls", "via": "HTTP /v1", "evidence": "main.go:12"}]'
echo '```'
EOF
chmod +x "$KNOWLEDGE_CLAUDE"

expect() { # $1 label, $2 want, $3 got
  if [ "$2" = "$3" ]; then echo "ok   $1"; else printf 'FAIL %s:\n want: %s\n got:  %s\n' "$1" "$2" "$3"; exit 1; fi
}
calls() { wc -l < "$STUB_CALLS" 2>/dev/null | tr -d ' '; }
graph() { # $1 python expression over g, the parsed graph.json
  python3 -I -c "import json,sys; g=json.load(open(sys.argv[1])); print($1)" "$KNOWLEDGE/work/graph.json"
}

# Arrange
HEAD_SHA=$(git -C "$ROOT/alpha" rev-parse HEAD)
# Act
OUT=$(sh "$SCAN" "$ROOT/alpha" 2>&1)
# Assert
expect "first run reports mapped" "mapped alpha" "$OUT"
expect "first run writes the md with mapped_sha at HEAD" "mapped_sha: $HEAD_SHA" "$(grep '^mapped_sha:' "$KNOWLEDGE/work/alpha.md")"
expect "md frontmatter names the repo and path" "repo: alpha
path: $ROOT/alpha" "$(grep -E '^(repo|path):' "$KNOWLEDGE/work/alpha.md")"
expect "md body is the reader output" "A fixture service (observation)." "$(grep 'fixture service' "$KNOWLEDGE/work/alpha.md")"
expect "graph holds the edge from alpha" "alpha beta calls HTTP /v1 main.go:12" \
  "$(graph "' '.join(g['edges'][0][key] for key in ('from', 'to', 'kind', 'via', 'evidence'))")"
expect "graph holds the alpha node at HEAD" "alpha $HEAD_SHA" \
  "$(graph "g['nodes'][0]['id'] + ' ' + g['nodes'][0]['mapped_sha']")"
expect "stub called once" "1" "$(calls)"

# Act
OUT=$(sh "$SCAN" "$ROOT/alpha" 2>&1)
# Assert
expect "second run at the same sha skips" "skip alpha (unchanged)" "$OUT"
expect "stub not called again on skip" "1" "$(calls)"

# Act
OUT=$(sh "$SCAN" --force "$ROOT/alpha" 2>&1)
# Assert
expect "--force maps again" "mapped alpha" "$OUT"
expect "--force calls the stub again" "2" "$(calls)"

# Arrange
GRAPH_BEFORE=$(cat "$KNOWLEDGE/work/graph.json")
# Act
OUT=$(STUB_MODE=noedges sh "$SCAN" --force "$ROOT/alpha" 2>&1)
# Assert
expect "output without an Edges block still maps, with a warning" "warning: alpha: no Edges json block parsed; graph unchanged
mapped alpha" "$OUT"
expect "md records that no edges were parsed" "## Edges

none parsed" "$(sed -n '/^## Edges/,$p' "$KNOWLEDGE/work/alpha.md")"
expect "graph unchanged when no edges parsed" "$GRAPH_BEFORE" "$(cat "$KNOWLEDGE/work/graph.json")"

# Act
OUT=$(sh "$SCAN" --root "$ROOT" 2>&1)
# Assert
expect "root scan maps the unmapped repo, skips the mapped one, ignores non-repos" "skip alpha (unchanged)
mapped beta" "$OUT"
expect "root scan wrote beta.md" "repo: beta" "$(grep '^repo:' "$KNOWLEDGE/work/beta.md")"
expect "beta edge joins the graph beside alpha's" "alpha,beta" "$(graph "','.join(sorted(edge['from'] for edge in g['edges']))")"

# Act
OUT=$(sh "$SCAN" "$ROOT/notes" 2>&1; echo "exit=$?")
# Assert
expect "a directory without .git fails" "fail notes (not a git repo)
exit=1" "$OUT"
echo "all cases passed"
