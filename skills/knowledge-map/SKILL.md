---
name: knowledge-map
description: Machine-local map of the user's repos. One knowledge file per git repo, written by an Opus reader through knowledge-scan.sh, plus a per-folder graph of which repos call, publish to, consume, read, write or deploy which. Use when a session opens with a `knowledge:` line, when asked what a repo depends on or connects to, or when asked to map, rescan or refresh project knowledge.
---

# Knowledge map

The map answers "what is this repo, and which other repos does a change here touch" before any PRD is drafted. A shell controller (`~/ai-harness/knowledge-scan.sh`) lists the git repos directly under each folder the user picked and runs one read-only `claude -p` reader per repo on Opus (`KNOWLEDGE_MODEL` overrides). The controller never summarizes a repo itself, and neither do you.

## Where the files live

Everything is under `$CLAUDE_CONFIG_DIR/knowledge/` (default `~/.claude/knowledge/`), never inside ai-harness or a scanned repo.

- `roots.json`: `{"roots": ["/Users/me/wisesight", "/Users/me/me"]}`, the folders whose direct git subdirectories are repos.
- `<root-basename>/<repo-basename>.md`: YAML frontmatter `repo`, `path`, `mapped_sha`, `mapped_at`, then the reader's markdown with the sections `What it is`, `Stack and entry points`, `Depends on`, `Provides`, `Config that names other systems`, `Unknowns`, `Edges`.
- `<root-basename>/graph.json`: `nodes` (one per mapped repo) and `edges` `{from, to, kind, via, evidence}` where `kind` is one of `calls`, `publishes`, `consumes`, `reads`, `writes`, `deploys`. A rescan of a repo replaces only the edges whose `from` is that repo.

The `knowledge-context` SessionStart hook prints `knowledge: <md path> · neighbors: a, b` when the session starts inside a mapped repo, a second line `knowledge: stale by <n> commits` when HEAD moved since the scan, or `knowledge: <repo> is not mapped` with the command to run.

## What to do with it

1. Session opened with a `knowledge:` line: read that file, then the neighbors' files in the same folder, before drafting the PRD. Name the chain of repos the change touches.
2. The map is stale or missing: run `~/ai-harness/knowledge-scan.sh <repo path>` and read the result. `--force` rescans a repo mapped at the current HEAD; `--root <dir>` scans one folder; no arguments scans every folder in `roots.json`; `KNOWLEDGE_PARALLEL=4` runs four readers at once.
3. Never write or edit a knowledge file or `graph.json` by hand. A wrong line in the map is fixed by rescanning the repo, so the file and the graph stay a record of what the reader observed with its `path:line` citations.
4. Treat every line the reader tagged `inference` or `unknown` as a question to settle in the repo, not as a fact.
