#!/usr/bin/env bash
# PostToolUse: Edit, Write
# Warns when AI slop color patterns are written to UI files.
# Detects: AI violet/purple/pink hex palette and unanchored gradient patterns.

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

# Only check UI source files
if ! echo "$FILE_PATH" | grep -qE "\.(css|scss|sass|less|tsx|jsx|html|svelte|vue)$"; then
    exit 0
fi

# Skip token definition files — these legitimately define color values
if echo "$FILE_PATH" | grep -qE "(tokens|design-system|variables|theme)\.(css|scss|ts|js)$"; then
    exit 0
fi

FINDINGS=""

# Hard-block: AI violet/purple/pink hex palette
SLOP_COLORS=(
    "#7c3aed"
    "#8b5cf6"
    "#6366f1"
    "#a855f7"
    "#ec4899"
    "#7C3AED"
    "#8B5CF6"
    "#6366F1"
    "#A855F7"
    "#EC4899"
)

for COLOR in "${SLOP_COLORS[@]}"; do
    if grep -qi "$COLOR" "$FILE_PATH" 2>/dev/null; then
        FINDINGS="$FINDINGS\n  - AI slop color: $COLOR found in $FILE_PATH"
    fi
done

# Warn: unanchored gradient patterns
if grep -qE "linear-gradient\(135deg" "$FILE_PATH" 2>/dev/null; then
    FINDINGS="$FINDINGS\n  - Unanchored gradient: linear-gradient(135deg) — default angle, verify design intent"
fi

if grep -qE "linear-gradient\(to right.*#[789a-fA-F]" "$FILE_PATH" 2>/dev/null; then
    FINDINGS="$FINDINGS\n  - AI gradient pattern: linear-gradient(to right, purple-range) — check brand brief"
fi

if [ -z "$FINDINGS" ]; then
    exit 0
fi

echo ""
echo "warn-ai-slop: potential AI slop patterns detected in $FILE_PATH"
echo -e "$FINDINGS"
echo ""
echo "  If these values are documented in the design brief or brand tokens, this warning can be ignored."
echo "  Run /ui-slop-guard for a full audit."
echo ""

# Exit 0 — warning only, does not block the write
exit 0
