#!/bin/sh
# Read-only access to Claude Code and Codex transcripts for reflect, correct and automate-me.
set -eu

CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CODEX_HOME_SESSIONS="${CODEX_HOME:-$HOME/.codex}/sessions"
DEFAULT_CODEX_SESSIONS="$HOME/.codex/sessions"
# English and Thai phrasings the operator uses when correcting an agent; hits are candidates to read, not verdicts.
CORRECTION_PATTERN='\b(no|nope|don.?t|do not|stop|wrong|again|instead|I said|I told|already (said|told)|not what I)\b|ไม่ใช่|เคยบอก|บอกแล้ว|บอกไป|อย่า|ผิด|อีกแล้ว|ทำไม.*ยัง|ไม่สื่อ'

VIEW_FILTER='
if .type == "user" and (.isMeta | not) then
  (.message.content
   | if type == "string" then "USER: " + .
     else (.[] | if .type == "text" then "USER: " + .text
                 elif .type == "tool_result" then "RESULT: " + (.content | tostring | .[0:400])
                 else empty end)
     end)
elif .type == "assistant" then
  (.message.content[]
   | if .type == "text" then "ASSISTANT: " + .text
     elif .type == "tool_use" then "TOOL " + .name + ": " + (.input | tostring | .[0:600])
     else empty end)
elif .type == "attachment" and .attachment.type == "skill_listing" then
  "SKILLS LISTED: " + (.attachment.names | join(", "))
else empty end'

PROMPT_FILTER='
[ .[]
  | select(.type == "user" and (.isMeta | not))
  | { time: ((.timestamp // "")[0:16]),
      text: (.message.content | if type == "string" then . else (map(select(.type == "text") | .text) | join(" ")) end),
      isHuman: (.origin.kind == "human") }
  | select(.isHuman or (.text | startswith("[Request interrupted"))) ]
| . as $prompts
| range(0; length) as $index
| $prompts[$index]
| select(.text | startswith("[Request interrupted") | not)
| ($index > 0 and ($prompts[$index - 1].text | startswith("[Request interrupted"))) as $isAfterInterrupt
| select($mode == "prompts" or $isAfterInterrupt or (.text | test($pattern; "i")))
| "\(.time) \($session) \(if $isAfterInterrupt then "[after interrupt] " else "" end)\(.text | gsub("\\s+"; " ") | .[0:300])"'

CODEX_PROMPT_FILTER='
(map(select(.type == "session_meta"))[0].payload.cwd // "") as $cwd
| select($cwd | startswith($project))
| .[]
| select(.type == "response_item" and .payload.type == "message" and .payload.role == "user")
| (.timestamp // "")[0:16] as $time
| .payload.content[]
| select(.type == "input_text")
| .text
| select((startswith("<") or startswith("# AGENTS.md")) | not)
| "\($time) \($session) \(gsub("\\s+"; " ") | .[0:300])"'

usage() {
    cat >&2 <<'USAGE'
usage: transcripts.sh current                              this Claude Code session's transcript path
       transcripts.sh dirs [project-path]                  transcript dirs for a project (default: pwd)
       transcripts.sh view <transcript.jsonl>              readable USER / ASSISTANT / TOOL / RESULT lines
       transcripts.sh prompts <days> <transcript-dir>...   operator prompts, oldest first
       transcripts.sh corrections <days> <transcript-dir>...  prompts that look like corrections
       transcripts.sh codex <days> [project-path]          operator prompts from Codex sessions in that project
USAGE
    exit 2
}

print_current() {
    if [ -z "${CLAUDE_CODE_SESSION_ID:-}" ]; then
        echo "CLAUDE_CODE_SESSION_ID is unset (not inside Claude Code). Run 'dirs', then 'view' the newest file there." >&2
        exit 1
    fi
    for transcript in "$CLAUDE_HOME"/projects/*/"$CLAUDE_CODE_SESSION_ID".jsonl; do
        if [ -f "$transcript" ]; then
            echo "$transcript"
            return
        fi
    done
    echo "no $CLAUDE_CODE_SESSION_ID.jsonl under $CLAUDE_HOME/projects" >&2
    exit 1
}

print_dirs() {
    project_path="${1:-$(pwd)}"
    slug=$(printf '%s' "$project_path" | sed 's/[^A-Za-z0-9]/-/g')
    found=0
    for dir in "$CLAUDE_HOME/projects/$slug" "$CLAUDE_HOME/projects/$slug"-*; do
        if [ -d "$dir" ]; then
            echo "$dir"
            found=1
        fi
    done
    if [ "$found" -eq 0 ]; then
        echo "no transcript dir for $project_path under $CLAUDE_HOME/projects (sessions launched from a parent dir land in that parent's dir)" >&2
        exit 1
    fi
}

print_prompts() {
    mode=$1
    days=$2
    shift 2
    for dir in "$@"; do
        if [ ! -d "$dir" ]; then
            echo "skipping $dir: not a directory" >&2
            continue
        fi
        find "$dir" -maxdepth 1 -name '*.jsonl' -mtime -"$days" | while read -r transcript; do
            jq -rs --arg mode "$mode" --arg pattern "$CORRECTION_PATTERN" \
                --arg session "$(basename "$transcript" .jsonl)" "$PROMPT_FILTER" "$transcript"
        done
    done | sort
}

print_codex_prompts() {
    days=$1
    project_path="${2:-$(pwd)}"
    for sessions_dir in "$CODEX_HOME_SESSIONS" "$DEFAULT_CODEX_SESSIONS"; do
        if [ -d "$sessions_dir" ]; then
            find "$sessions_dir" -name 'rollout-*.jsonl' -mtime -"$days"
        fi
    done | sort -u | while read -r rollout; do
        jq -rs --arg project "$project_path" --arg session "$(basename "$rollout" .jsonl)" \
            "$CODEX_PROMPT_FILTER" "$rollout"
    done | sort
}

if [ $# -eq 0 ]; then
    usage
fi

command=$1
shift
case "$command" in
    current) print_current ;;
    dirs) print_dirs "$@" ;;
    view) [ $# -eq 1 ] || usage; jq -r "$VIEW_FILTER" "$1" ;;
    prompts) [ $# -ge 2 ] || usage; print_prompts prompts "$@" ;;
    corrections) [ $# -ge 2 ] || usage; print_prompts corrections "$@" ;;
    codex) [ $# -ge 1 ] || usage; print_codex_prompts "$@" ;;
    *) usage ;;
esac
