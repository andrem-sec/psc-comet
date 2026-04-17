#!/usr/bin/env bash
# Stop hook (opt-in) -- blocks if source files were modified but /code-review has not run.
#
# Enable by creating:  .claude/context/.review-gate
# Disable by deleting: .claude/context/.review-gate
#
# Marker written by code-review skill: .claude/context/.review-done
#
# When enabled: if source files are modified and .review-done was not written
# within the last 2 hours, outputs {"decision":"block","reason":"..."} to
# re-enter the loop and prompt the user to run /code-review.

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$HOOK_DIR")"
CONTEXT_DIR="$ROOT_DIR/context"

GUARD_FLAG="$CONTEXT_DIR/.review-gate"
REVIEW_MARKER="$CONTEXT_DIR/.review-done"

# Discard stdin
cat > /dev/null

# Opt-in check -- disabled by default
if [[ ! -f "$GUARD_FLAG" ]]; then
    exit 0
fi

# Check if code-review was run recently (within 2 hours)
review_recent() {
    [[ -f "$REVIEW_MARKER" ]] || return 1
    MTIME=$(stat -c %Y "$REVIEW_MARKER" 2>/dev/null || stat -f %m "$REVIEW_MARKER" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    [[ $(( NOW - MTIME )) -lt 7200 ]]
}

if review_recent; then
    exit 0
fi

# Check for modified source files
SOURCE_CHANGES=$(git -C "$ROOT_DIR" diff --name-only HEAD 2>/dev/null \
    | grep -E '\.(ts|tsx|js|jsx|py|go|rb|rs|java|kt|sh|bash)$' \
    | head -1 || true)

if [[ -z "$SOURCE_CHANGES" ]]; then
    exit 0
fi

# Block and re-enter the loop
printf '{"decision":"block","reason":"Source files were modified this session but /code-review has not been run. Please run /code-review before ending."}\n'
exit 0
