#!/usr/bin/env bash
# PSC statusLine -- two-line format
# Requires: jq, awk, git (optional)

input=$(cat)

# -- Extract fields --
cwd=$(printf '%s'          "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // ""')
model=$(printf '%s'        "$input" | jq -r '.model.display_name // ""')
used_pct=$(printf '%s'     "$input" | jq -r '.context_window.used_percentage // empty')
ctx_in=$(printf '%s'       "$input" | jq -r '.context_window.total_input_tokens // 0')
ctx_out=$(printf '%s'      "$input" | jq -r '.context_window.total_output_tokens // 0')
ctx_size=$(printf '%s'     "$input" | jq -r '.context_window.context_window_size // 0')
cost=$(printf '%s'         "$input" | jq -r '.cost.total_cost_usd // empty')
dur_ms=$(printf '%s'       "$input" | jq -r '.cost.total_duration_ms // 0')
lines_add=$(printf '%s'    "$input" | jq -r '.cost.total_lines_added // 0')
lines_rem=$(printf '%s'    "$input" | jq -r '.cost.total_lines_removed // 0')
rate_5h=$(printf '%s'      "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rate_5h_reset=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rate_7d=$(printf '%s'      "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
session_id=$(printf '%s'   "$input" | jq -r '.session_id // ""')

# -- Derived values --
project=$(basename "$cwd")
branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || echo "")

# -- ANSI colors (24-bit truecolor) --
G='\033[38;2;0;200;80m'
C='\033[38;2;0;200;200m'
M='\033[38;2;180;80;200m'
Y='\033[38;2;220;180;0m'
R='\033[0m'
DIM='\033[2m'
BOLD='\033[1m'
SEP="${DIM}|${R}"

# -- Context bar (20 blocks, color shifts at 60/80%) --
ctx_bar() {
    local pct=${1:-0}
    local filled=$(( pct * 20 / 100 ))
    local r g b
    if   [ "$pct" -lt 60 ]; then r=0;   g=200; b=80
    elif [ "$pct" -lt 80 ]; then r=220; g=180; b=0
    else                          r=220; g=60;  b=40; fi
    local i=1
    while [ "$i" -le 20 ]; do
        if [ "$i" -le "$filled" ]; then
            printf '\033[38;2;%d;%d;%dm#' "$r" "$g" "$b"
        else
            printf '%b' "${DIM}.${R}"
        fi
        i=$(( i + 1 ))
    done
    printf '%b' "$R"
}

# -- Formatters --
fmt_k() {
    awk -v n="$1" 'BEGIN {
        if (n >= 1000000) printf "%.1fM", n/1000000
        else if (n >= 1000) printf "%.1fk", n/1000
        else printf "%d", n
    }'
}

fmt_dur() {
    local s=$(( ${1:-0} / 1000 ))
    if   [ "$s" -ge 3600 ]; then printf "%dh %dm" $(( s/3600 )) $(( (s%3600)/60 ))
    elif [ "$s" -ge   60 ]; then printf "%dm %ds"  $(( s/60 ))   $(( s%60 ))
    else printf "%ds" "$s"; fi
}

fmt_reset() {
    date -d "$1" '+%H:%M' 2>/dev/null || date -j -f '%Y-%m-%dT%H:%M:%S' "$1" '+%H:%M' 2>/dev/null || echo ""
}

# -- Vault detection --
vault_label=""
vault_cfg="${HOME}/.claude/psc-vault-path"
if [ -f "$vault_cfg" ]; then
    vault_path=$(cat "$vault_cfg")
    vault_label=$(basename "$vault_path")
elif jq -e '.mcpServers.obsidian' "${HOME}/.claude/settings.json" >/dev/null 2>&1; then
    vault_label="vault"
fi

# -- Agent count (written by subagent-statusline.sh each update) --
agent_count=""
if [ -n "$session_id" ]; then
    agent_file="/tmp/psc-agents-${session_id}"
    [ -f "$agent_file" ] && agent_count=$(cat "$agent_file")
fi

# ============================================================================
# LINE 1: (project)-[branch]  model  | tokens/ctx  | bar  | agents
# ============================================================================

printf '%b' "${G}(${BOLD}${project}${R}${G})"
[ -n "$branch" ] && printf '%b' "${G}-[${C}${branch}${G}]${R}" || printf '%b' "$R"

[ -n "$model" ] && printf '%b' "  [m] ${M}${model}${R}"

total=$(( ctx_in + ctx_out ))
if [ "$total" -gt 0 ] && [ "$ctx_size" -gt 0 ]; then
    printf "  %b  %s/%s" "$SEP" "$(fmt_k "$total")" "$(fmt_k "$ctx_size")"
fi

if [ -n "$used_pct" ]; then
    used_int=$(printf '%.0f' "$used_pct")
    if [ "$used_int" -ge 80 ]; then ctx_sym="!"; else ctx_sym="o"; fi
    printf "  %b  [%s] " "$SEP" "$ctx_sym"
    ctx_bar "$used_int"
    printf ' %d%%' "$used_int"
fi

if [ -n "$agent_count" ] && [ "$agent_count" -gt 0 ] 2>/dev/null; then
    printf "  %b  [a] %s" "$SEP" "$agent_count"
fi

printf '\n'

# ============================================================================
# LINE 2: cost  | rate limits  | lines  | duration  | vault
# ============================================================================

first2=true
sep2() { $first2 || printf "  %b  " "$SEP"; first2=false; }

if [ -n "$cost" ]; then
    sep2
    cost_fmt=$(awk -v c="$cost" 'BEGIN { printf "%.3f", c }')
    printf '%b' "[$] ${Y}\$${cost_fmt}${R}"
fi

if [ -n "$rate_5h" ]; then
    sep2
    r5=$(printf '%.0f' "$rate_5h")
    printf "[r] 5h: %s%%" "$r5"
    [ -n "$rate_7d" ] && printf "  7d: %s%%" "$(printf '%.0f' "$rate_7d")"
    if [ -n "$rate_5h_reset" ]; then
        rt=$(fmt_reset "$rate_5h_reset")
        [ -n "$rt" ] && printf "  resets %s" "$rt"
    fi
fi

if [ "$lines_add" -gt 0 ] || [ "$lines_rem" -gt 0 ]; then
    sep2
    printf '[e] '
    [ "$lines_add" -gt 0 ] && printf '\033[38;2;0;200;80m+%d%b' "$lines_add" "$R"
    [ "$lines_rem" -gt 0 ] && printf ' \033[38;2;220;60;40m-%d%b' "$lines_rem" "$R"
fi

if [ "$dur_ms" -gt 0 ]; then
    sep2
    printf '[t] %s' "$(fmt_dur "$dur_ms")"
fi

if [ -n "$vault_label" ]; then
    sep2
    printf '[v] %b%s%b' "$C" "$vault_label" "$R"
fi

printf '\n'
