#!/usr/bin/env bash

input=$(cat)

# Claude account name from the active Claude config (display name, else email).
# Resolve the config dir from CLAUDE_CONFIG_DIR so the statusline matches the
# config the session is actually running under (e.g. ~/.claude-fenrir).
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
account=$(jq -r '.oauthAccount.displayName // .oauthAccount.emailAddress // empty' "$config_dir/.claude.json" 2>/dev/null)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
branch=$(git --no-optional-locks -C "$cwd" branch --show-current 2>/dev/null)
repo_root=$(git --no-optional-locks -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
repo=""
[ -n "$repo_root" ] && repo=$(basename "$repo_root")


five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour | (.resets_at // .reset_at // .resets // empty)')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day | (.resets_at // .reset_at // .resets // empty)')

# Normalize a reset value (Unix epoch seconds, epoch milliseconds, or an
# ISO-8601 string) to a Unix epoch in seconds. Echoes nothing on failure.
to_epoch() {
  local v="$1"
  [ -z "$v" ] && return
  if [[ "$v" =~ ^[0-9]+$ ]]; then
    # Treat 13-digit values as milliseconds.
    if [ "${#v}" -ge 13 ]; then
      echo $(( v / 1000 ))
    else
      echo "$v"
    fi
  else
    # ISO-8601 string -> epoch (macOS/BSD date). Strip fractional seconds/zone.
    local s="${v%%.*}"
    s="${s%Z}"
    date -j -u -f "%Y-%m-%dT%H:%M:%S" "$s" +%s 2>/dev/null
  fi
}

# Format a reset value as a human-readable local time.
# Within 24 h: show "HH:MM"; otherwise show "Mon DD HH:MM".
fmt_reset() {
  local epoch
  epoch=$(to_epoch "$1")
  [ -z "$epoch" ] && return
  local now diff
  now=$(date +%s)
  diff=$(( epoch - now ))
  if [ "$diff" -le 86400 ]; then
    date -r "$epoch" +"%H:%M"
  else
    date -r "$epoch" +"%b %d %H:%M"
  fi
}

# Colors
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
DIM='\033[2m'

line=""

# Claude account name
if [ -n "$account" ]; then
  line="${line}$(printf "${BOLD}${CYAN}%s${RESET}" "$account")"
fi

# Model name (from stdin JSON)
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
if [ -n "$model_name" ]; then
  [ -n "$line" ] && line="${line} "
  line="${line}$(printf "${DIM}%s${RESET}" "$model_name")"
fi

# Advisor model (from settings.json in the active config dir)
advisor_model=$(jq -r '.advisorModel // empty' "$config_dir/settings.json" 2>/dev/null)
if [ -n "$advisor_model" ]; then
  [ -n "$line" ] && line="${line} "
  line="${line}$(printf "${DIM}[advisor: %s]${RESET}" "$advisor_model")"
fi

# git repo
if [ -n "$repo" ]; then
  [ -n "$line" ] && line="${line} "
  line="${line}$(printf "${GREEN}%s${RESET}" "$repo")"
fi

# git branch
if [ -n "$branch" ]; then
  [ -n "$line" ] && line="${line} "
  line="${line}$(printf "${MAGENTA}%s${RESET}" "$branch")"
fi

# Context window usage: "ctx 84k (42%)".
# Prefer a real token count from the JSON; fall back to pct * 200k window.
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_tokens=$(echo "$input" | jq -r '.context_window | (.used_tokens // .used // .tokens // empty)')
if [ -n "$ctx_used" ]; then
  [ -n "$line" ] && line="${line} "
  if [ -z "$ctx_tokens" ]; then
    ctx_tokens=$(echo "$ctx_used" | awk '{printf "%d", $1 / 100 * 200000}')
  fi
  ctx_k=$(echo "$ctx_tokens" | awk '{printf "%.0f", $1 / 1000}')
  line="${line}$(printf "ctx %sk ($(printf '%.0f' "$ctx_used")%%)" "$ctx_k")"
fi

# 5h rate limit
if [ -n "$five_pct" ]; then
  reset_str=$(fmt_reset "$five_resets")
  reset_label=""
  [ -n "$reset_str" ] && reset_label=" $(printf "${DIM}resets %s${RESET}" "$reset_str")"
  line="${line} $(printf "${YELLOW}5h${RESET} $(printf '%.0f' "$five_pct")%%${reset_label}")"
fi

# 7d rate limit
if [ -n "$week_pct" ]; then
  reset_str=$(fmt_reset "$week_resets")
  reset_label=""
  [ -n "$reset_str" ] && reset_label=" $(printf "${DIM}resets %s${RESET}" "$reset_str")"
  line="${line} $(printf "${YELLOW}7d${RESET} $(printf '%.0f' "$week_pct")%%${reset_label}")"
fi

printf "%b\n" "$line"
