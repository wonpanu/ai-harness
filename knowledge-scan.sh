#!/bin/sh
# Controller for the project knowledge map: lists the git repos under each chosen folder, skips the ones mapped at
# their current HEAD, runs one `claude -p` reader per repo and files its output under $CLAUDE_DIR/knowledge.
# It never summarizes a repo itself, and re-renders the folder's index.html after a scan. Skill: skills/knowledge-map/SKILL.md.
# Usage: ./knowledge-scan.sh --init                       pick folders, then offer a scan
#        ./knowledge-scan.sh [--force] [--root <dir>] [<repo path>...]
# Env:   KNOWLEDGE_MODEL (opus) · KNOWLEDGE_PARALLEL (1) · KNOWLEDGE_CLAUDE (claude) · CLAUDE_DIR (~/.claude)
set -eu

HARNESS_DIR=$(cd "$(dirname "$0")" && pwd)
CLAUDE_DIR="${CLAUDE_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}}"
KNOWLEDGE_DIR="$CLAUDE_DIR/knowledge"
ROOTS_FILE="$KNOWLEDGE_DIR/roots.json"
PROMPT_FILE="$HARNESS_DIR/skills/knowledge-map/prompt.md"
READER_TOOLS="Read,Grep,Glob,Bash(git log:*),Bash(git ls-files:*),Bash(ls:*),Bash(wc:*)"

usage() {
    echo "usage: $0 --init | [--force] [--root <dir>] [<repo path>...]" >&2
    exit 2
}

configured_roots() {
    python3 -I -c 'import json, sys; print("\n".join(json.load(open(sys.argv[1]))["roots"]))' "$ROOTS_FILE"
}

repos_under() { # $1 root -> one repo path per line
    for candidate in "$1"/*/; do
        candidate="${candidate%/}"
        if [ -e "$candidate/.git" ]; then
            echo "$candidate"
        fi
    done
}

scan_all() {
    configured_roots | while read -r root; do repos_under "$root"; done | scan_list
    configured_roots | while read -r root; do render "$(basename "$root")"; done
}

render() { # $1 root basename -> index.html beside graph.json, skipped when nothing was mapped yet
    [ -f "$KNOWLEDGE_DIR/$1/graph.json" ] || return 0
    CLAUDE_CONFIG_DIR="$CLAUDE_DIR" python3 -I "$HARNESS_DIR/knowledge-render.py" --root "$1" >&2
}

scan_one() { # $1 repo path -> prints one of: mapped <repo> | skip <repo> (unchanged) | fail <repo> (<reason>)
    repo=$(cd "$1" && pwd)
    name=$(basename "$repo")
    if [ ! -e "$repo/.git" ]; then
        echo "fail $name (not a git repo)"
        return 1
    fi
    sha=$(git -C "$repo" rev-parse HEAD)
    out_dir="$KNOWLEDGE_DIR/$(basename "$(dirname "$repo")")"
    md="$out_dir/$name.md"
    if [ -z "${KNOWLEDGE_FORCE:-}" ] && [ -f "$md" ] && grep -q "^mapped_sha: $sha\$" "$md"; then
        echo "skip $name (unchanged)"
        return 0
    fi
    mkdir -p "$out_dir"
    raw=$(mktemp)
    if ! (cd "$repo" && "${KNOWLEDGE_CLAUDE:-claude}" -p --model "${KNOWLEDGE_MODEL:-opus}" \
            --add-dir "$(dirname "$repo")" \
            --append-system-prompt-file "$PROMPT_FILE" --allowedTools "$READER_TOOLS" --max-turns 60 \
            "Map this repository." > "$raw"); then
        rm -f "$raw"
        echo "fail $name (reader exited non-zero)"
        return 1
    fi
    status=0
    python3 -I - "$raw" "$md" "$out_dir/graph.json" "$name" "$repo" "$sha" <<'PY' || status=$?
import datetime, fcntl, json, os, re, sys
raw_path, md_path, graph_path, repo, repo_path, sha = sys.argv[1:]
body = open(raw_path).read().strip()


def edges_block(markdown):
    sections = re.split(r"^## Edges\s*$", markdown, maxsplit=1, flags=re.M)
    if len(sections) == 1:
        return None
    blocks = re.findall(r"```json\s*\n(.*?)\n\s*```", sections[1], re.S)
    if not blocks:
        return None
    try:
        parsed = json.loads(blocks[0])
    except ValueError:
        return None
    if not isinstance(parsed, list):
        return None
    return parsed


edges = edges_block(body)
if edges is None:
    if "## Edges" not in body:
        body += "\n\n## Edges"
    body += "\n\nnone parsed"
    print(f"warning: {repo}: no Edges json block parsed; graph unchanged", file=sys.stderr)
front = f"---\nrepo: {repo}\npath: {repo_path}\nmapped_sha: {sha}\nmapped_at: {datetime.date.today().isoformat()}\n---\n"
with open(md_path, "w") as handle:
    handle.write(front + body + "\n")
if edges is None:
    sys.exit(0)
# graph.json is shared by every repo under the root, so parallel scans take turns writing it
with open(graph_path + ".lock", "w") as lock:
    fcntl.flock(lock, fcntl.LOCK_EX)
    graph = json.load(open(graph_path)) if os.path.exists(graph_path) else {"nodes": [], "edges": []}
    graph["nodes"] = [node for node in graph["nodes"] if node["id"] != repo] + [{"id": repo, "path": repo_path, "mapped_sha": sha}]
    graph["edges"] = [edge for edge in graph["edges"] if edge.get("from") != repo] + edges
    with open(graph_path, "w") as handle:
        json.dump(graph, handle, indent=2)
PY
    rm -f "$raw"
    if [ "$status" -ne 0 ]; then
        echo "fail $name (could not write knowledge files)"
        return 1
    fi
    echo "mapped $name"
}

scan_list() { # stdin: one repo path per line
    xargs -P "${KNOWLEDGE_PARALLEL:-1}" -I'{}' sh "$0" --one '{}' || exit 1
}

init() {
    current="none"
    [ -f "$ROOTS_FILE" ] && current=$(configured_roots | tr '\n' ' ')
    printf 'Folders whose git repos to map (space-separated, ~ allowed; blank keeps: %s): ' "$current"
    read -r answer || answer=""
    if [ -n "$answer" ]; then
        mkdir -p "$KNOWLEDGE_DIR"
        ANSWER="$answer" python3 -I -c 'import json, os; print(json.dumps({"roots": [os.path.abspath(os.path.expanduser(folder)) for folder in os.environ["ANSWER"].split()]}, indent=2))' > "$ROOTS_FILE"
        echo "wrote $ROOTS_FILE"
    fi
    if [ ! -f "$ROOTS_FILE" ]; then
        echo "no folders configured; nothing to scan"
        return 1
    fi
    printf 'Scan now? [y/N] '
    read -r answer || answer=""
    case "$answer" in
        y|Y|yes) scan_all ;;
    esac
}

root=""
repos=""
while [ $# -gt 0 ]; do
    case "$1" in
        --init) init; exit $? ;;
        --one) scan_one "$2"; exit $? ;;
        --force) KNOWLEDGE_FORCE=1; export KNOWLEDGE_FORCE ;;
        --root) root="$2"; shift ;;
        -*) usage ;;
        *) repos="$repos$1
" ;;
    esac
    shift
done

if [ -n "$repos" ]; then
    printf '%s' "$repos" | scan_list
    printf '%s' "$repos" | while read -r repo; do render "$(basename "$(dirname "$(cd "$repo" && pwd)")")"; done
    exit 0
fi
if [ -n "$root" ]; then
    repos_under "$root" | scan_list
    render "$(basename "$root")"
    exit 0
fi
if [ ! -f "$ROOTS_FILE" ]; then
    echo "no folders configured; run $0 --init" >&2
    exit 1
fi
scan_all
