#!/usr/bin/env bash
# PostToolUse: Edit, Write
# Warns when outline: none or outline: 0 is written without a replacement focus style.
# Removing the focus ring without replacement is a WCAG 2.4.7 violation (keyboard navigation).

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

# Detect outline: none or outline: 0 on :focus selectors
OUTLINE_NONE=$(grep -nE ":focus[^{]*\{[^}]*outline:\s*(none|0)" "$FILE_PATH" 2>/dev/null || true)
if [ -n "$OUTLINE_NONE" ]; then
    COUNT=$(echo "$OUTLINE_NONE" | wc -l | tr -d ' ')
    EXAMPLES=$(echo "$OUTLINE_NONE" | head -3 | awk '{print "    " $0}')
    FINDINGS="$FINDINGS\n  - $COUNT :focus rule(s) remove outline without replacement:\n$EXAMPLES"
fi

# Detect outline: none applied broadly (not scoped to :focus)
BROAD_OUTLINE=$(grep -nE "^\s*outline:\s*(none|0)\s*;" "$FILE_PATH" 2>/dev/null || true)
if [ -n "$BROAD_OUTLINE" ]; then
    COUNT=$(echo "$BROAD_OUTLINE" | wc -l | tr -d ' ')
    EXAMPLES=$(echo "$BROAD_OUTLINE" | head -3 | awk '{print "    " $0}')
    FINDINGS="$FINDINGS\n  - $COUNT broad outline: none rule(s) (affects keyboard focus visibility):\n$EXAMPLES"
fi

# Check for Tailwind outline-none class on focusable elements
TAILWIND_OUTLINE=$(grep -nE "\boutline-none\b" "$FILE_PATH" 2>/dev/null || true)
if [ -n "$TAILWIND_OUTLINE" ]; then
    COUNT=$(echo "$TAILWIND_OUTLINE" | wc -l | tr -d ' ')
    EXAMPLES=$(echo "$TAILWIND_OUTLINE" | head -3 | awk '{print "    " $0}')
    FINDINGS="$FINDINGS\n  - $COUNT use(s) of Tailwind outline-none — verify focus-visible replacement exists:\n$EXAMPLES"
fi

if [ -z "$FINDINGS" ]; then
    exit 0
fi

echo ""
echo "warn-outline-none: focus ring removal detected in $FILE_PATH"
echo -e "$FINDINGS"
echo ""
echo "  Keyboard users rely on the focus ring to know where they are on the page."
echo "  Never remove it without providing a visible replacement."
echo ""
echo "  Replace with:"
echo "    button:focus-visible {"
echo "      outline: 2px solid var(--color-primary);"
echo "      outline-offset: 2px;"
echo "    }"
echo ""
echo "  Using :focus-visible instead of :focus hides the ring for mouse users"
echo "  while keeping it visible for keyboard users."
echo ""

# Exit 0 — warning only
exit 0
