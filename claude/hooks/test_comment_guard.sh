#!/bin/sh
# Runs comment-guard.py against inline edits; exit 1 on the first failed case.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

guard() { # $1 tool, $2 file, $3 json-escaped new text -> prints stdout line count
  printf '{"hook_event_name":"PostToolUse","tool_name":"%s","tool_input":{"file_path":"%s","new_string":"%s","content":"%s"}}' "$1" "$2" "$3" "$3" \
    | python3 -I "$HERE/comment-guard.py" 2>"$TMP/err" | tee "$TMP/out" | grep -c . ; }
expect() { # $1 label, $2 want-lines, $3 got-lines
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: want $2 lines, got $3"; cat "$TMP/out" "$TMP/err" 2>/dev/null; exit 1; fi
}

expect "code without comments is silent"           0 "$(guard Edit a.go 'func f() int {\n\treturn 1\n}')"
expect "a doc comment is reported (header + line)" 2 "$(guard Edit a.go '// UpdateMemberRole handles PATCH /x\nfunc (h *H) UpdateMemberRole() {}')"
expect "AAA markers are allowed"                   0 "$(guard Edit a_test.go '\t// Arrange\n\tx := 1\n\t// Act\n\t// Assert')"
expect "nolint and go: directives are allowed"     0 "$(guard Edit a.go '//nolint:staticcheck\n//go:generate mockery')"
expect "shebang and noqa are allowed"              0 "$(guard Write s.py '#!/usr/bin/env python3\nimport os  # noqa')"
expect "python comment is reported"                2 "$(guard Write s.py '# load the config\ncfg = 1')"
expect "non-code files are ignored"                0 "$(guard Write README.md '# Title\n// not code')"
expect "three comments list three lines"           4 "$(guard Edit a.ts '// a\n// b\n// c\nconst x = 1')"
echo "all comment-guard cases passed"
