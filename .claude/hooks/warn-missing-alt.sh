#!/usr/bin/env bash
# PostToolUse: Edit, Write
# Warns when img elements are written without alt attributes.
# Missing alt text is a WCAG 1.1.1 violation (Level A — minimum standard).

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

# Only check markup files
if ! echo "$FILE_PATH" | grep -qE "\.(html|tsx|jsx|svelte|vue|erb|haml|slim)$"; then
    exit 0
fi

FINDINGS=""

# Detect <img> tags without alt attribute
# Pattern: <img followed by characters that don't include alt= before the closing >
IMG_NO_ALT=$(grep -nE "<img[^>]*>" "$FILE_PATH" 2>/dev/null | grep -v 'alt=' || true)

if [ -n "$IMG_NO_ALT" ]; then
    COUNT=$(echo "$IMG_NO_ALT" | wc -l | tr -d ' ')
    EXAMPLES=$(echo "$IMG_NO_ALT" | head -3 | awk '{print "    " $0}')
    FINDINGS="$FINDINGS\n  - $COUNT <img> element(s) missing alt attribute:\n$EXAMPLES"
fi

# Also check for Next.js Image component without alt
NEXT_IMG_NO_ALT=$(grep -nE "<Image[^>]*>" "$FILE_PATH" 2>/dev/null | grep -v 'alt=' || true)

if [ -n "$NEXT_IMG_NO_ALT" ]; then
    COUNT=$(echo "$NEXT_IMG_NO_ALT" | wc -l | tr -d ' ')
    EXAMPLES=$(echo "$NEXT_IMG_NO_ALT" | head -3 | awk '{print "    " $0}')
    FINDINGS="$FINDINGS\n  - $COUNT <Image> component(s) missing alt attribute:\n$EXAMPLES"
fi

if [ -z "$FINDINGS" ]; then
    exit 0
fi

echo ""
echo "warn-missing-alt: WCAG 1.1.1 violation — images without alt text in $FILE_PATH"
echo -e "$FINDINGS"
echo ""
echo "  All <img> elements require an alt attribute."
echo "  - Informative images: alt=\"[description of what the image shows]\""
echo "  - Decorative images: alt=\"\" (empty string, not omitted)"
echo ""

# Exit 0 — warning only (allows the write to proceed so work is not lost)
# Developers should fix before commit — warn-missing-alt surfaces the issue
exit 0
