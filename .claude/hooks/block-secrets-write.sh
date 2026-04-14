#!/usr/bin/env bash
# PreToolUse: Write
# Blocks writes to credential and secrets files.

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

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Patterns for files that should not be written without explicit intent
SENSITIVE_PATTERNS=(
    "\.env$"
    "\.env\.local$"
    "\.env\.production$"
    "\.env\.staging$"
    "credentials\.json$"
    "secrets\.json$"
    "\.pem$"
    "\.key$"
    "id_rsa$"
    "id_ed25519$"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if echo "$FILE_PATH" | grep -qE "$pattern"; then
        echo "BLOCKED: Writing to '$FILE_PATH' — this file may contain secrets." >&2
        echo "Verify this is intentional. If writing a template or example, confirm explicitly." >&2
        exit 2
    fi
done

exit 0
