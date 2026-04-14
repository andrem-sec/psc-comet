#!/usr/bin/env bash
# PreToolUse: Bash
# Blocks destructive commands that require explicit user confirmation.

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$CMD" ]; then
    exit 0
fi

# Patterns that require explicit confirmation
DESTRUCTIVE_PATTERNS=(
    "rm -rf"
    "git push --force"
    "git push -f"
    "drop table"
    "drop database"
    "truncate table"
    "DELETE FROM"
    "git reset --hard"
    "git clean -f"
)

for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
    if echo "$CMD" | grep -qi "$pattern"; then
        echo "BLOCKED: '$pattern' requires explicit user confirmation before running." >&2
        echo "State what this command does and why it is necessary, then ask the user to confirm." >&2
        exit 2
    fi
done

exit 0
