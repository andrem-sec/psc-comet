#!/usr/bin/env bash
# PreToolUse: Write|Edit
# Captures a diagnostic baseline for shell scripts before they are modified.
#
# If shellcheck is available and the target file is a .sh script, runs shellcheck
# and saves the result to .claude/baselines/<filename>.txt so post-edit-check.sh
# can diff for regressions.
#
# Silently skips non-.sh files or when shellcheck is not installed.
# Never blocks — exit 0 always.

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

# Only process files that already exist (Write to new file: no baseline needed)
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Only run if shellcheck is available
if ! command -v shellcheck &>/dev/null; then
    exit 0
fi

mkdir -p "$BASELINE_DIR"

BASENAME="$(basename "$FILE_PATH")"
BASELINE_FILE="$BASELINE_DIR/${BASENAME}.baseline.txt"

# Run shellcheck, capture output (exit code may be non-zero — that's fine)
shellcheck --format=gcc "$FILE_PATH" > "$BASELINE_FILE" 2>&1 || true

exit 0
