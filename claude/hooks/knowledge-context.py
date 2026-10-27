"""SessionStart hook: when cwd is inside a repo under a mapped root, prints where its knowledge file is,
which repos it is connected to, and whether the map is stale. Prints nothing elsewhere."""
import json
import os
import subprocess
import sys

SCAN_COMMAND = "~/ai-harness/knowledge-scan.sh"


def locate_repo(cwd, roots):
    for root in roots:
        relative = os.path.relpath(cwd, os.path.realpath(root))
        if relative == "." or relative.startswith(".."):
            continue
        return root, os.path.join(root, relative.split(os.sep)[0])
    return None


def mapped_sha(md_path):
    with open(md_path) as handle:
        for line in handle:
            if line.startswith("mapped_sha: "):
                return line[len("mapped_sha: "):].strip()
    return ""


def neighbors(graph_path, repo):
    if not os.path.exists(graph_path):
        return []
    graph = json.load(open(graph_path))
    known = {node["id"] for node in graph.get("nodes", [])}
    found = set()
    for edge in graph.get("edges", []):
        ends = {edge.get("from"), edge.get("to")}
        if repo in ends:
            found |= ends - {repo}
    return sorted(found & known)


def commits_since(repo_path, sha):
    result = subprocess.run(["git", "-C", repo_path, "rev-list", "--count", f"{sha}..HEAD"], capture_output=True, text=True)
    if result.returncode != 0:
        return None
    return int(result.stdout.strip())


def main():
    payload = json.load(sys.stdin)
    cwd = os.path.realpath(payload.get("cwd") or os.getcwd())
    knowledge_dir = os.path.join(os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude"), "knowledge")
    roots_path = os.path.join(knowledge_dir, "roots.json")
    if not os.path.exists(roots_path):
        return 0
    located = locate_repo(cwd, json.load(open(roots_path)).get("roots", []))
    if located is None:
        return 0
    root, repo_path = located
    repo = os.path.basename(repo_path)
    root_dir = os.path.join(knowledge_dir, os.path.basename(root))
    md_path = os.path.join(root_dir, f"{repo}.md")
    if not os.path.exists(md_path):
        print(f"knowledge: {repo} is not mapped. Run: {SCAN_COMMAND} {repo_path}")
        return 0
    print(f"knowledge: {md_path} · neighbors: {', '.join(neighbors(os.path.join(root_dir, 'graph.json'), repo)) or 'none'}")
    behind = commits_since(repo_path, mapped_sha(md_path))
    if behind == 0:
        return 0
    print(f"knowledge: stale by {'unknown' if behind is None else behind} commits. Run: {SCAN_COMMAND} {repo_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
