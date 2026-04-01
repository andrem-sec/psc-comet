#!/usr/bin/env bash
# PostToolUse: Edit, Write
# Warns when raw hex color values appear in component files instead of token references.
# Token definition files are excluded — they legitimately contain raw values.

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

# Only check UI component/style files
if ! echo "$FILE_PATH" | grep -qE "\.(css|scss|sass|less|tsx|jsx|html|svelte|vue)$"; then
    exit 0
fi

# Skip token definition files — they are the source of truth for raw values
if echo "$FILE_PATH" | grep -qE "(tokens|design-system|variables|theme|primitives|global)\.(css|scss|ts|js)$"; then
    exit 0
fi

# Skip tailwind config — this IS the token layer for Tailwind projects
if echo "$FILE_PATH" | grep -qE "tailwind\.config\.(js|ts|mjs)$"; then
    exit 0
fi

FINDINGS=""
COUNT=0

# Detect raw hex values in component files
HEX_COUNT=$(grep -cE "#[0-9a-fA-F]{3,6}([^0-9a-fA-F]|$)" "$FILE_PATH" 2>/dev/null || echo 0)

if [ "$HEX_COUNT" -gt 0 ]; then
    # Extract the first few occurrences for the warning
    EXAMPLES=$(grep -nE "#[0-9a-fA-F]{3,6}([^0-9a-fA-F]|$)" "$FILE_PATH" 2>/dev/null | head -3 | awk '{print "    " $0}')
    FINDINGS="$FINDINGS\n  - $HEX_COUNT raw hex value(s) found (first 3 shown):\n$EXAMPLES"
    COUNT=$((COUNT + HEX_COUNT))
fi

# Detect arbitrary Tailwind color values
ARB_COLOR_COUNT=$(grep -cE "bg-\[#|text-\[#|border-\[#|fill-\[#|stroke-\[#" "$FILE_PATH" 2>/dev/null || echo 0)

if [ "$ARB_COLOR_COUNT" -gt 0 ]; then
    EXAMPLES=$(grep -nE "bg-\[#|text-\[#|border-\[#|fill-\[#|stroke-\[#" "$FILE_PATH" 2>/dev/null | head -2 | awk '{print "    " $0}')
    FINDINGS="$FINDINGS\n  - $ARB_COLOR_COUNT arbitrary Tailwind color(s) bypass the token layer:\n$EXAMPLES"
    COUNT=$((COUNT + ARB_COLOR_COUNT))
fi

if [ -z "$FINDINGS" ]; then
    exit 0
fi

echo ""
echo "warn-token-violation: $COUNT raw color value(s) detected in component file: $FILE_PATH"
echo -e "$FINDINGS"
echo ""
echo "  Component files should reference design tokens (CSS custom properties or Tailwind theme values)."
echo "  Run /design-token-guard for a full token audit and remediation."
echo ""

# Exit 0 — warning only, does not block the write
exit 0
