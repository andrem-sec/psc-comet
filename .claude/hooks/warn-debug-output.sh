#!/usr/bin/env bash
# PostToolUse: Edit, Write
# Warns when debug output is found in source files after editing.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Only check source files
if ! echo "$FILE_PATH" | grep -qE "\.(ts|tsx|js|jsx|py|go|rb|rs|java|kt|swift|cpp|c)$"; then
    exit 0
fi

# Debug output patterns by language
DEBUG_PATTERNS=(
    "console\.log("
    "console\.debug("
    "console\.warn("
    "print("
    "fmt\.Print"
    "fmt\.Println"
    "System\.out\.print"
    "debugger;"
    "binding\.pry"
    "byebug"
    "^\s*pp[\s(]"
)

FOUND=()
for pattern in "${DEBUG_PATTERNS[@]}"; do
    if grep -qE "$pattern" "$FILE_PATH" 2>/dev/null; then
        FOUND+=("$pattern")
    fi
done

if [ ${#FOUND[@]} -gt 0 ]; then
    echo "WARNING: Debug output in $FILE_PATH — ${FOUND[*]}" >&2
    echo "Remove before committing." >&2
fi

# Always exit 0 — this is a warning, not a block
exit 0
