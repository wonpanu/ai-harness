#!/bin/sh
# Runs commit-guard.py / commit-grant.py against fixture repos; exit 1 on the first failed case.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"; mkdir -p "$HOME"
export HARNESS_DIR="$TMP/home/ai-harness"
git init -q "$HARNESS_DIR"; git init -q "$TMP/product"
export CLAUDE_PROJECT_DIR="$TMP/product"

guard() { # $1 cwd, $2 command -> prints exit code
  printf '{"session_id":"s1","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" "$2" \
    | python3 -I "$HERE/commit-guard.py" >/dev/null 2>"$TMP/err"; echo $?
}
grant() { # $1 prompt
  printf '{"session_id":"s1","cwd":"%s","hook_event_name":"UserPromptSubmit","prompt":"%s"}' "$CLAUDE_PROJECT_DIR" "$1" \
    | python3 -I "$HERE/commit-grant.py" >/dev/null 2>&1
}
expect() { # $1 label, $2 want, $3 got
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: want exit $2, got $3"; cat "$TMP/err" 2>/dev/null; exit 1; fi
}

expect "plain command passes"                 0 "$(guard "$TMP/product" "git status")"
expect "git commit in product repo blocked"   2 "$(guard "$TMP/product" "git commit -m x")"
expect "git push in product repo blocked"     2 "$(guard "$TMP/product" "git push origin feature/x")"
expect "gh pr create in product repo blocked" 2 "$(guard "$TMP/product" "gh pr create --base main")"
expect "cd into product then commit blocked"  2 "$(guard "$HARNESS_DIR" "cd $TMP/product && git commit -m x")"
expect "git -C product commit blocked"        2 "$(guard "$HARNESS_DIR" "git -C $TMP/product commit -m x")"
expect "commit in ai-harness allowed"         0 "$(guard "$HARNESS_DIR" "git commit -m x")"
expect "push in ai-harness allowed"           0 "$(guard "$HARNESS_DIR" "git push origin fix/x")"
expect "cd into ai-harness from product cwd allowed" 0 "$(guard "$TMP/product" "cd $HARNESS_DIR && git commit -m x && git push -u origin fix/x")"
expect "harness and product in one command blocked" 2 "$(guard "$TMP/product" "git -C $TMP/product commit -m x; cd $HARNESS_DIR && git push")"
grep -q "ask the user" "$TMP/err" 2>/dev/null; true

grant "ทำไมถึง commit แล้ว push โดยไม่ถาม ห้ามทำอีก"
expect "negated prompt grants nothing"        2 "$(guard "$TMP/product" "git commit -m x")"
grant "ok commit ได้เลย"
expect "prompt saying commit grants"          0 "$(guard "$TMP/product" "git commit -m x")"
expect "grant also covers push"               0 "$(guard "$TMP/product" "git push origin feature/x")"
find "$HOME/.claude/commit-grants" -type f -exec touch -t 202001010000 {} \;
expect "expired grant blocks again"           2 "$(guard "$TMP/product" "git commit -m x")"
echo "all cases passed"
