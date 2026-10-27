#!/bin/sh
# Runs knowledge-context.py against fixture repos under a fixture root; exit 1 on the first failed case.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"; mkdir -p "$HOME"
export CLAUDE_CONFIG_DIR="$TMP/home/.claude"
KNOWLEDGE="$CLAUDE_CONFIG_DIR/knowledge"
ROOT="$TMP/work"
mkdir -p "$KNOWLEDGE/work" "$ROOT/alpha/sub" "$ROOT/beta" "$TMP/elsewhere"
git init -q "$ROOT/alpha"; git init -q "$ROOT/beta"
git -C "$ROOT/alpha" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$ROOT/beta" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
printf '{"roots": ["%s"]}' "$ROOT" > "$KNOWLEDGE/roots.json"

context() { # $1 cwd -> prints hook stdout
  printf '{"session_id":"s1","cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "$1" \
    | python3 -I "$HERE/knowledge-context.py" 2>"$TMP/err"
}
expect() { # $1 label, $2 want, $3 got
  if [ "$2" = "$3" ]; then echo "ok   $1"; else printf 'FAIL %s:\n want: %s\n got:  %s\n' "$1" "$2" "$3"; cat "$TMP/err" 2>/dev/null; exit 1; fi
}
write_map() { # $1 mapped sha
  printf -- '---\nrepo: alpha\npath: %s\nmapped_sha: %s\nmapped_at: 2026-10-27\n---\n# alpha\n' "$ROOT/alpha" "$1" > "$KNOWLEDGE/work/alpha.md"
}

# Arrange
HEAD_SHA=$(git -C "$ROOT/alpha" rev-parse HEAD)
# Act / Assert
expect "cwd outside every root prints nothing" "" "$(context "$TMP/elsewhere")"
expect "cwd at the root itself prints nothing" "" "$(context "$ROOT")"
expect "unmapped repo asks for a scan" \
  "knowledge: alpha is not mapped. Run: ~/ai-harness/knowledge-scan.sh $ROOT/alpha" \
  "$(context "$ROOT/alpha")"

# Arrange
write_map "$HEAD_SHA"
cat > "$KNOWLEDGE/work/graph.json" <<EOF
{"nodes": [{"id": "alpha", "path": "$ROOT/alpha", "mapped_sha": "$HEAD_SHA"}, {"id": "beta", "path": "$ROOT/beta", "mapped_sha": "x"}],
 "edges": [{"from": "beta", "to": "alpha", "kind": "calls", "via": "HTTP /v1", "evidence": "main.go:3"},
           {"from": "alpha", "to": "sqs:orders", "kind": "publishes", "via": "orders", "evidence": "pub.go:9"}]}
EOF
# Act / Assert
expect "mapped at HEAD prints the file and repo neighbors only" \
  "knowledge: $KNOWLEDGE/work/alpha.md · neighbors: beta" \
  "$(context "$ROOT/alpha")"
expect "cwd in a subdirectory resolves to the repo" \
  "knowledge: $KNOWLEDGE/work/alpha.md · neighbors: beta" \
  "$(context "$ROOT/alpha/sub")"

# Arrange
git -C "$ROOT/alpha" -c user.email=t@t -c user.name=t commit -q --allow-empty -m two
git -C "$ROOT/alpha" -c user.email=t@t -c user.name=t commit -q --allow-empty -m three
# Act / Assert
expect "mapped two commits ago reports stale by 2" \
  "knowledge: $KNOWLEDGE/work/alpha.md · neighbors: beta
knowledge: stale by 2 commits. Run: ~/ai-harness/knowledge-scan.sh $ROOT/alpha" \
  "$(context "$ROOT/alpha")"

# Arrange
write_map "0000000000000000000000000000000000000000"
rm "$KNOWLEDGE/work/graph.json"
# Act / Assert
expect "mapped sha unknown to git reports stale by unknown, no graph means no neighbors" \
  "knowledge: $KNOWLEDGE/work/alpha.md · neighbors: none
knowledge: stale by unknown commits. Run: ~/ai-harness/knowledge-scan.sh $ROOT/alpha" \
  "$(context "$ROOT/alpha")"
echo "all cases passed"
