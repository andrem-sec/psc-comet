#!/usr/bin/env bash
# Stop hook (opt-in) -- blocks if session has changes but /wrap-up has not run.
#
# Enable by creating:  .claude/context/.wrap-guard
# Disable by deleting: .claude/context/.wrap-guard
#
# Marker written by wrap-up skill: .claude/context/.wrapup-done
#
# When enabled: if git changes exist and .wrapup-done was not written within
# the last 2 hours, outputs {"decision":"block","reason":"..."} to re-enter
# the loop and prompt the user to run /wrap-up.

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$HOOK_DIR")"
CONTEXT_DIR="$ROOT_DIR/context"

GUARD_FLAG="$CONTEXT_DIR/.wrap-guard"
WRAPUP_MARKER="$CONTEXT_DIR/.wrapup-done"

# Discard stdin
cat > /dev/null

# Opt-in check -- disabled by default
if [[ ! -f "$GUARD_FLAG" ]]; then
    exit 0
fi

# Check if wrap-up was run recently (within 2 hours)
wrapup_recent() {
    [[ -f "$WRAPUP_MARKER" ]] || return 1
    MTIME=$(stat -c %Y "$WRAPUP_MARKER" 2>/dev/null || stat -f %m "$WRAPUP_MARKER" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    [[ $(( NOW - MTIME )) -lt 7200 ]]
}

if wrapup_recent; then
    exit 0
fi

# Check for any git changes relative to HEAD
HAS_CHANGES=$(git -C "$ROOT_DIR" diff --name-only HEAD 2>/dev/null | head -1 || true)

if [[ -z "$HAS_CHANGES" ]]; then
    exit 0
fi

# Block and re-enter the loop
printf '{"decision":"block","reason":"Session has uncommitted changes but /wrap-up has not been run. Please run /wrap-up to record learnings and update the handoff before ending."}\n'
exit 0
