"""PreToolUse hook (Bash): blocks git commit / git push / gh pr create outside the harness repo
unless the user granted it this turn (see commit-grant.py). Exit 2 = block, stderr goes to Claude."""
import hashlib
import json
import os
import re
import subprocess
import sys
import time

GRANT_TTL_SECONDS = 30 * 60
GUARDED = re.compile(r"(^|[;&|(]\s*)(git\s+(-C\s+\S+\s+)?(commit|push)\b|gh\s+pr\s+(create|merge)\b)")


def harness_dir():
    return os.path.realpath(os.environ.get("HARNESS_DIR", os.path.expanduser("~/ai-harness")))


def grant_path(project_dir):
    key = hashlib.sha256(os.path.realpath(project_dir).encode()).hexdigest()[:16]
    return os.path.join(os.path.expanduser("~/.claude/commit-grants"), key)


def toplevel(path):
    try:
        out = subprocess.run(["git", "-C", path, "rev-parse", "--show-toplevel"], capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if out.returncode != 0:
        return None
    return os.path.realpath(out.stdout.strip())


def target_dirs(command, cwd):
    # a cd or git -C names the repo the command touches; the shell's starting cwd counts only when there is none
    named = [match.group(1) for match in re.finditer(r"(?:^|[;&|]\s*)cd\s+(\S+)", command)]
    named += [match.group(1) for match in re.finditer(r"git\s+-C\s+(\S+)", command)]
    if not named:
        return [cwd]
    return [os.path.expanduser(path) for path in named]


def main():
    payload = json.load(sys.stdin)
    command = payload.get("tool_input", {}).get("command", "")
    if not GUARDED.search(command):
        return 0

    cwd = payload.get("cwd") or os.getcwd()
    tops = {toplevel(d) for d in target_dirs(command, cwd)}
    tops.discard(None)
    if tops and all(top == harness_dir() for top in tops):
        return 0

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR") or cwd
    path = grant_path(project_dir)
    if os.path.exists(path) and time.time() - os.path.getmtime(path) < GRANT_TTL_SECONDS:
        return 0

    sys.stderr.write(
        "commit-guard: git commit / git push / gh pr are blocked here because the user has not asked for it this turn "
        "(only ~/ai-harness is exempt). Leave the diff in the working tree, report it as ready, and ask the user; "
        "they grant it by saying \"commit\" or \"push\" in their next message.\n"
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
