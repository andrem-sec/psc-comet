#!/usr/bin/env bash
# Stop hook
# When Claude stops, checks if code files were modified this session.
# If yes, reminds to run security-gate and code-review before committing.

set -euo pipefail

# Check for modified source files in git working tree
MODIFIED=$(git diff --name-only 2>/dev/null | grep -E "\.(ts|tsx|js|jsx|py|go|rb|rs|java|kt)$" || true)
STAGED=$(git diff --cached --name-only 2>/dev/null | grep -E "\.(ts|tsx|js|jsx|py|go|rb|rs|java|kt)$" || true)

ALL_MODIFIED=$(printf '%s\n%s' "$MODIFIED" "$STAGED" | sort -u | grep -v '^$' || true)

if [ -n "$ALL_MODIFIED" ]; then
    COUNT=$(echo "$ALL_MODIFIED" | wc -l | tr -d ' ')
    echo "" >&2
    echo "[$COUNT source file(s) modified]" >&2
    echo "Before committing: run code-review skill, then security-gate skill." >&2
    echo "End of session: run /wrap-up to commit learnings." >&2
fi

exit 0
