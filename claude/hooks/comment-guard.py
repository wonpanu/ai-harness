"""PostToolUse hook (Edit / Write / MultiEdit): lists every comment line the edit added so the
comment pass happens at write time, not at review. Exit 0 always; stdout goes to Claude."""
import json
import os
import re
import sys

CODE_EXTENSIONS = {".go", ".ts", ".tsx", ".js", ".jsx", ".mjs", ".py", ".sh", ".sql", ".css", ".scss", ".rs", ".java", ".kt", ".swift", ".rb", ".php", ".c", ".h", ".cpp", ".hpp"}
COMMENT_LINE = re.compile(r"^\s*(//|#(?!!)|/\*|\*\s|--\s)")
ALLOWED = re.compile(
    r"^\s*(//|#)\s*(Arrange|Act|Assert)\s*$"
    r"|//\s*nolint|//\s*go:|//\s*eslint|//\s*@ts-|//\s*prettier|//\s*biome"
    r"|#\s*(noqa|type:|pragma|fmt:|pylint|ruff)"
    r"|^\s*#!"
    r"|^\s*///?\s*<reference"
    r"|^\s*#\s*(define|include|if|ifdef|ifndef|else|endif|pragma)\b"
)


def added_text(tool_name, tool_input):
    if tool_name == "Write":
        return tool_input.get("content", "")
    if tool_name == "MultiEdit":
        return "\n".join(edit.get("new_string", "") for edit in tool_input.get("edits", []))
    return tool_input.get("new_string", "")


def comment_lines(text):
    for line in text.splitlines():
        if not COMMENT_LINE.match(line):
            continue
        if ALLOWED.search(line):
            continue
        yield line.strip()


def main():
    payload = json.load(sys.stdin)
    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {})
    path = tool_input.get("file_path", "")
    if os.path.splitext(path)[1] not in CODE_EXTENSIONS:
        return 0
    found = list(comment_lines(added_text(tool_name, tool_input)))
    if not found:
        return 0
    shown = "\n".join(f"  {line[:120]}" for line in found[:8])
    more = f"\n  … and {len(found) - 8} more" if len(found) > 8 else ""
    print(
        f"comment-guard: {len(found)} comment line(s) added to {os.path.basename(path)}. Keep one only for a business rule "
        f"or external constraint the code cannot show (one line); a doc comment that restates the name, route or signature, "
        f"a route-order note, or what a field holds is deleted before you report done.\n{shown}{more}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
