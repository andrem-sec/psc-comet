#!/usr/bin/env bash
# PostToolUse: Edit|Write
# Records a SHA-256 attribution snapshot after every file modification.
#
# Output: .claude/attribution.jsonl
# Each line: {"ts":"...","session_id":"...","tool":"...","file":"...","sha256":"..."}
#
# Used for: audit trails, compliance, session post-mortems.
# No content is logged — only the file path and hash.

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$HOOK_DIR")"
ATTRIBUTION_LOG="$ROOT_DIR/attribution.jsonl"

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_name', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

SESSION_ID=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('session_id', 'unknown'))
except Exception:
    print('unknown')
" 2>/dev/null || echo "unknown")

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Hash the file content — not logged, only the hash
# sha256sum = Linux/Windows (Git Bash); shasum -a 256 = macOS fallback
SHA=$(sha256sum "$FILE_PATH" 2>/dev/null | cut -d' ' -f1 \
  || shasum -a 256 "$FILE_PATH" 2>/dev/null | cut -d' ' -f1 \
  || echo "unavailable")
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Sanitize file path — strip home dir prefix to avoid leaking absolute paths
SAFE_PATH="${FILE_PATH/$HOME/~}"

printf '{"ts":"%s","session_id":"%s","tool":"%s","file":"%s","sha256":"%s"}\n' \
    "$TS" \
    "$SESSION_ID" \
    "$TOOL_NAME" \
    "$SAFE_PATH" \
    "$SHA" \
    >> "$ATTRIBUTION_LOG"

exit 0
