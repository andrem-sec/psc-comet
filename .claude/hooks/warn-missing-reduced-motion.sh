#!/usr/bin/env bash
# PostToolUse: Edit, Write
# Warns when CSS animation or transition declarations are written to a file
# that does not include a prefers-reduced-motion media query.
# Missing reduced-motion support is a WCAG 2.3.3 / accessibility best practice violation.

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

# Only check CSS and style files (not component JSX — JS animation check is separate)
if ! echo "$FILE_PATH" | grep -qE "\.(css|scss|sass|less)$"; then
    exit 0
fi

# Check if file contains any animation or transition declarations
HAS_ANIMATION=$(grep -cE "@keyframes|animation:|transition:" "$FILE_PATH" 2>/dev/null || echo 0)

if [ "$HAS_ANIMATION" -eq 0 ]; then
    exit 0
fi

# Check if file includes a prefers-reduced-motion media query
HAS_REDUCED_MOTION=$(grep -c "prefers-reduced-motion" "$FILE_PATH" 2>/dev/null || echo 0)

if [ "$HAS_REDUCED_MOTION" -gt 0 ]; then
    exit 0
fi

# Count animation-related declarations for context
KEYFRAME_COUNT=$(grep -c "@keyframes" "$FILE_PATH" 2>/dev/null || echo 0)
TRANSITION_COUNT=$(grep -c "transition:" "$FILE_PATH" 2>/dev/null || echo 0)

echo ""
echo "warn-missing-reduced-motion: animation without prefers-reduced-motion in $FILE_PATH"
echo ""
echo "  Found: $KEYFRAME_COUNT @keyframes, $TRANSITION_COUNT transition declarations"
echo "  Missing: @media (prefers-reduced-motion: reduce) { ... }"
echo ""
echo "  Users with vestibular disorders or motion sensitivity set this preference in their OS."
echo "  Without it, animated content runs regardless of accessibility settings."
echo ""
echo "  Add at the end of $FILE_PATH:"
echo "    @media (prefers-reduced-motion: reduce) {"
echo "      * {"
echo "        animation-duration: 0.01ms !important;"
echo "        animation-iteration-count: 1 !important;"
echo "        transition-duration: 0.01ms !important;"
echo "      }"
echo "    }"
echo ""
echo "  Or scope to specific selectors for finer control."
echo "  Run /animation-safe for a full motion audit."
echo ""

# Exit 0 — warning only
exit 0
