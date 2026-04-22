#!/usr/bin/env bash
# Stop hook — cost and token tracking (STUB - NOT FUNCTIONAL)
#
# BLOCKER: Stop hooks do not receive token counts or model info from Claude Code.
# This stub logs "NOT_IMPLEMENTED" until upstream enhancement is available.
#
# Required data (not available in hook input):
# - input_tokens, output_tokens (from API response)
# - model name (from session context)
#
# Output: context/telemetry/costs.jsonl (stub records)

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$HOOK_DIR")"
TELEMETRY_DIR="$ROOT_DIR/context/telemetry"
LOG_FILE="$TELEMETRY_DIR/costs.jsonl"

# Read Stop hook input
INPUT="$(cat)"

# Extract available fields
SESSION_ID="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id','unknown'))" 2>/dev/null || echo "unknown")"

# Ensure telemetry directory exists
mkdir -p "$TELEMETRY_DIR"

# Write stub record
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
printf '{"ts":"%s","session_id":"%s","status":"NOT_IMPLEMENTED","note":"Stop hooks lack token/cost data - requires upstream enhancement"}\n' \
  "$TS" \
  "$SESSION_ID" \
  >> "$LOG_FILE"

# Signal Claude Code to suppress this hook's output from the conversation.
# This hook is a stub that writes to a JSONL file only.
printf '{"suppressOutput":true}\n'

exit 0
