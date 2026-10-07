#!/usr/bin/env bash
# Read-only: deletion stays a human-gated step in playbooks/worktree-cleanup.md.
# Usage: worktree-audit.sh [--no-chats] [repo-path]   (defaults to the current repo)
set -u

scan_chats=yes
if [ "${1:-}" = "--no-chats" ]; then scan_chats=no; shift; fi

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -z "$repo" ] && { echo "not in a git repo; pass a repo path" >&2; exit 1; }
cd "$repo" || exit 1

main_wt=$(git worktree list --porcelain | awk '/^worktree /{sub(/^worktree /, ""); print; exit}')

trunk=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
git fetch origin "${trunk#origin/}" --quiet 2>/dev/null || echo "warn: could not fetch $trunk; merged column may be stale" >&2

prs=$(mktemp)
gh pr list --author "@me" --state all --limit 1000 \
	--json number,state,headRefName 2>/dev/null > "$prs" || echo "[]" > "$prs"

claude_projects="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects"
codex_sessions="$HOME/.codex/sessions"

# Claude Code names a project's transcript dir after its cwd with every non-alphanumeric byte turned into "-".
project_dir() { printf '%s/%s' "$claude_projects" "$(printf '%s' "$1" | sed 's#[^A-Za-z0-9]#-#g')"; }

sessions_mentioning() {
	if command -v rg >/dev/null 2>&1; then
		rg -l -F -e "$2/" -e "$2\"" -e "$2\\" -e "$2 " "$1" 2>/dev/null
		return
	fi
	grep -rlF -e "$2/" -e "$2\"" -e "$2\\" -e "$2 " "$1" 2>/dev/null
}

if [ "$scan_chats" = yes ] && [ ! -d "$claude_projects" ] && [ ! -d "$codex_sessions" ]; then
	echo "warn: no Claude Code or Codex session store found; LAST_CHAT is unknown for every row" >&2
	scan_chats=no
fi
[ "$scan_chats" = no ] && echo "warn: session scan off; rows that would be safe or review come back verify-chat-unknown" >&2

main_transcripts=$(project_dir "$main_wt")
now=$(date +%s)

printf "SIZE\tAGE\tMERGED\tDIRTY\tREMOTE\tPR\tLAST_CHAT\tBUCKET\tWORKTREE\n"

git worktree list --porcelain | awk '/^worktree /{sub(/^worktree /, ""); print}' | while read -r wt; do
	[ "$wt" = "$main_wt" ] && continue

	size=$(du -sh "$wt" 2>/dev/null | awk '{print $1}')
	head=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
	head_ts=$(git -C "$wt" log -1 --format='%ct' HEAD 2>/dev/null || echo 0)
	age=$([ "$head_ts" -gt 0 ] 2>/dev/null && echo "$(( (now - head_ts) / 86400 ))d" || echo "?")

	# Squash merges never make the head an ancestor of trunk, so PR state is the real merge signal.
	git merge-base --is-ancestor "$head" "$trunk" 2>/dev/null && merged=YES || merged=no

	porcelain=$(git -C "$wt" status --porcelain 2>/dev/null)
	if [ -z "$porcelain" ]; then dirty=clean
	elif printf '%s\n' "$porcelain" | grep -qv '^??'; then
		dirty="wip:$(printf '%s\n' "$porcelain" | grep -cv '^??')"
	else dirty="scratch:$(printf '%s\n' "$porcelain" | grep -c '^??')"; fi

	branch=$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")
	if [ -z "$branch" ]; then remote=detached
	elif git -C "$wt" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
		[ "$(git -C "$wt" rev-parse "origin/$branch" 2>/dev/null)" = "$head" ] \
			&& remote=pushed \
			|| remote="ahead$(git -C "$wt" rev-list --count "origin/$branch..HEAD" 2>/dev/null)"
	else remote=no-remote; fi

	pr=$([ -n "$branch" ] && jq -r --arg b "$branch" \
		'.[] | select(.headRefName==$b) | "#\(.number)/\(.state)"' "$prs" 2>/dev/null | head -1)
	[ -z "$pr" ] && pr="-"

	# Match the path followed by a boundary byte so glint-482 does not match glint-482-r37.
	last="-"; last_ts=0; recent=unknown
	if [ "$scan_chats" = yes ]; then
		newest=$( {
			find "$(project_dir "$wt")" -name '*.jsonl' 2>/dev/null
			[ -d "$main_transcripts" ] && sessions_mentioning "$main_transcripts" "$wt"
			[ -d "$codex_sessions" ] && sessions_mentioning "$codex_sessions" "$wt"
		} | tr '\n' '\0' | xargs -0 stat -f '%m %N' 2>/dev/null | sort -rn | head -1)
		if [ -n "$newest" ]; then last_ts=$(echo "$newest" | awk '{print $1}')
			last=$(date -r "$last_ts" '+%Y-%m-%d' 2>/dev/null); fi
		recent=$([ "$last_ts" -gt 0 ] && [ $(( (now - last_ts) / 86400 )) -le 4 ] && echo yes || echo no)
	fi

	case "$dirty" in wip:*) bucket=hold-wip ;; *)
		case "$pr" in *OPEN*) bucket=hold-open-pr ;; *)
			if [ "$recent" = yes ]; then bucket=verify-recent-chat
			elif [ "$recent" = unknown ]; then bucket=verify-chat-unknown
			elif [ "$merged" = YES ] || [ "$pr" != "-" ]; then bucket=safe
			else bucket=review; fi ;;
		esac ;;
	esac

	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
		"$size" "$age" "$merged" "$dirty" "$remote" "$pr" "$last" "$bucket" "$wt"
done | sort -t$'\t' -k1,1 -rh

rm -f "$prs"
