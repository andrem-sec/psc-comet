#!/usr/bin/env bash
# PostToolUse: Edit, Write
# Warns when 'transition: all' is written to CSS or component files.
# transition: all triggers layout recalculation on every CSS property change,
# including layout-triggering properties (width, height, padding, margin).

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

# Only check style and component files
if ! echo "$FILE_PATH" | grep -qE "\.(css|scss|sass|less|tsx|jsx|svelte|vue|html)$"; then
    exit 0
fi

FINDINGS=""

# Detect transition: all patterns
TRANS_ALL_COUNT=$(grep -cE "transition:\s*(all|all [0-9])" "$FILE_PATH" 2>/dev/null || echo 0)

if [ "$TRANS_ALL_COUNT" -gt 0 ]; then
    EXAMPLES=$(grep -nE "transition:\s*(all|all [0-9])" "$FILE_PATH" 2>/dev/null | head -3 | awk '{print "    " $0}')
    FINDINGS="$FINDINGS\n  - $TRANS_ALL_COUNT instance(s) of transition: all:\n$EXAMPLES"
fi

# Also check Tailwind transition-all class
TAILWIND_TRANS_ALL=$(grep -cnE "className=[\"'][^\"']*transition-all[^\"']*[\"']|\btransition-all\b" "$FILE_PATH" 2>/dev/null || echo 0)

if [ "$TAILWIND_TRANS_ALL" -gt 0 ]; then
    EXAMPLES=$(grep -nE "\btransition-all\b" "$FILE_PATH" 2>/dev/null | head -2 | awk '{print "    " $0}')
    FINDINGS="$FINDINGS\n  - $TAILWIND_TRANS_ALL use(s) of Tailwind transition-all:\n$EXAMPLES"
fi

if [ -z "$FINDINGS" ]; then
    exit 0
fi

echo ""
echo "warn-transition-all: broad transition detected in $FILE_PATH"
echo -e "$FINDINGS"
echo ""
echo "  'transition: all' animates every CSS property including layout-triggering ones"
echo "  (width, height, padding, margin), causing layout recalculation on every frame."
echo ""
echo "  Replace with specific properties:"
echo "    transition: background-color 0.2s ease, box-shadow 0.2s ease, transform 0.15s ease;"
echo ""
echo "  Run /animation-safe for a full animation audit."
echo ""

# Exit 0 — warning only
exit 0
