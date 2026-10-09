"""UserPromptSubmit hook: when the user's own message asks for a commit/push/PR, writes a 30-minute grant
file that commit-guard.py accepts. A message that forbids it ("don't commit", "ห้าม push") grants nothing."""
import hashlib
import json
import os
import re
import sys

ASKS = re.compile(r"(?<![a-z])(commit|push|pr|pull request|merge)(?![a-z])", re.IGNORECASE)
FORBIDS = re.compile(r"(don'?t|do not|never|without|not yet|stop|อย่า|ห้าม|ยังไม่|ไม่ให้|ไม่ต้อง|ทำไม)", re.IGNORECASE)


def grant_path(project_dir):
    key = hashlib.sha256(os.path.realpath(project_dir).encode()).hexdigest()[:16]
    return os.path.join(os.path.expanduser("~/.claude/commit-grants"), key)


def main():
    payload = json.load(sys.stdin)
    prompt = payload.get("prompt", "")
    if not ASKS.search(prompt) or FORBIDS.search(prompt):
        return 0
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR") or payload.get("cwd") or os.getcwd()
    path = grant_path(project_dir)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as handle:
        handle.write(prompt[:200])
    print("commit-guard: the user asked for a commit/push in this message; git commit/push/gh pr are allowed for 30 minutes, for the repo they named only.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
