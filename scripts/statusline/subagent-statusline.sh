#!/usr/bin/env bash
# PSC subagentStatusLine -- formats agent panel rows
# Also writes running agent count to /tmp for main statusLine bar

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // ""')

# Write running count so statusline-command.sh can show agents: N
if [ -n "$session_id" ]; then
    running=$(printf '%s' "$input" | jq '[.tasks[]? | select(.status == "running")] | length')
    printf '%s' "$running" > "/tmp/psc-agents-${session_id}"
fi

# Format each task as a row in the agent panel
printf '%s' "$input" | jq -r '
    .tasks[]? |
    (.status) as $s |
    (if   $s == "running"   then "▶ "
     elif $s == "completed" then "✓ "
     elif $s == "failed"    then "✗ "
     else                        "· " end) as $prefix |
    (.name // "agent") as $name |
    (.description // "") as $desc |
    (.tokenCount // 0) as $tok |
    $prefix + $name +
    (if $desc != "" then "  " + $desc else "" end) +
    (if $tok > 0
     then "  [" + (if $tok >= 1000 then (($tok / 1000 * 10 | floor) / 10 | tostring) + "k" else ($tok | tostring) end) + " tok]"
     else "" end)
' 2>/dev/null || true
