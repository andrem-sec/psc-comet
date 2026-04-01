#!/usr/bin/env bash
# PostToolUse: Write|Edit
# Compares shellcheck findings after a file edit against the pre-edit baseline.
#
# If the edit introduced NEW shellcheck findings (regressions), outputs a warning
# to Claude. Claude is expected to fix them before completing the task.
#
# Never blocks — exit 0 always. Warnings are advisory.

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$HOOK_DIR")"
BASELINE_DIR="$ROOT_DIR/baselines"

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

# Only process .sh files
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.sh ]]; then
    exit 0
fi

if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

if ! command -v shellcheck &>/dev/null; then
    exit 0
fi

BASENAME="$(basename "$FILE_PATH")"
BASELINE_FILE="$BASELINE_DIR/${BASENAME}.baseline.txt"

# No baseline = first write to this file, nothing to compare
if [[ ! -f "$BASELINE_FILE" ]]; then
    exit 0
fi

POST_FILE="$BASELINE_DIR/${BASENAME}.post.txt"
shellcheck --format=gcc "$FILE_PATH" > "$POST_FILE" 2>&1 || true

# Find lines in post that were not in baseline (new findings only)
NEW_FINDINGS=$(comm -13 <(sort "$BASELINE_FILE") <(sort "$POST_FILE") 2>/dev/null || echo "")

if [[ -n "$NEW_FINDINGS" ]]; then
    echo ""
    echo "DIAGNOSTIC WARNING: This edit introduced new shellcheck findings in $(basename "$FILE_PATH"):"
    echo "$NEW_FINDINGS"
    echo ""
    echo "Fix these before marking the task complete."
    echo ""
fi

# Clean up temp files
rm -f "$POST_FILE"

exit 0
