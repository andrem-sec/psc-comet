#!/usr/bin/env bash
# Stop hook — logs skill usage to a local JSONL file for session retrospectives.
# No data leaves the machine. No remote sync. Local visibility only.
#
# Output: context/telemetry/skill-usage.jsonl
# Each line: {"ts":"...","event":"session_end","duration_s":...,"outcome":"..."}
#
# Called by the Stop hook in settings.json after every Claude response.

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$HOOK_DIR")"
TELEMETRY_DIR="$ROOT_DIR/context/telemetry"
LOG_FILE="$TELEMETRY_DIR/skill-usage.jsonl"

# Read Stop hook input from stdin (JSON with session info)
INPUT="$(cat)"

# Extract fields from hook input if present
SESSION_ID="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id','unknown'))" 2>/dev/null || echo "unknown")"
STOP_REASON="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('stop_reason','unknown'))" 2>/dev/null || echo "unknown")"

# Map stop reason to outcome
case "$STOP_REASON" in
  end_turn) OUTCOME="success" ;;
  max_tokens) OUTCOME="truncated" ;;
  error) OUTCOME="error" ;;
  *) OUTCOME="unknown" ;;
esac

# Enrich: git branch and modified file count
if git -C "$ROOT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    GIT_BRANCH="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "none")"
    MODIFIED_FILES="$(git -C "$ROOT_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ' || echo "0")"
else
    GIT_BRANCH="none"
    MODIFIED_FILES="0"
fi

# Enrich: session duration from ember.lock mtime (seconds since last consolidation as proxy)
EMBER_LOCK="$ROOT_DIR/context/ember.lock"
if [[ -f "$EMBER_LOCK" ]]; then
  LOCK_MTIME="$(stat -c %Y "$EMBER_LOCK" 2>/dev/null || stat -f %m "$EMBER_LOCK" 2>/dev/null || echo "0")"
  NOW_S="$(date +%s)"
  DURATION_S=$(( NOW_S - LOCK_MTIME ))
else
  DURATION_S=0
fi

# Ensure telemetry directory exists
mkdir -p "$TELEMETRY_DIR"

# Write JSONL record
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
printf '{"ts":"%s","event":"session_end","session_id":"%s","outcome":"%s","os":"%s","arch":"%s","git_branch":"%s","modified_files":%s,"duration_s":%s}\n' \
  "$TS" \
  "$SESSION_ID" \
  "$OUTCOME" \
  "$(uname -s)" \
  "$(uname -m)" \
  "$GIT_BRANCH" \
  "$MODIFIED_FILES" \
  "$DURATION_S" \
  >> "$LOG_FILE"

# Signal Claude Code to suppress this hook's output from the conversation.
# This hook writes to a JSONL file only -- nothing to surface to the user.
printf '{"suppressOutput":true}\n'

exit 0
