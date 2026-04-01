#!/usr/bin/env bash
# PreCompact hook — writes session memory snapshot before context compaction.
#
# Fires whenever Claude Code is about to compact the context window.
# Outputs a reminder to Claude to write context/session-memory.md before
# the compaction erases in-progress state.
#
# This approximates the Claude Code internal auto-trigger (10k token init +
# 5k growth + 3 tool calls) using the only available hook point: PreCompact.
#
# Exit 0 always — never blocks compaction.

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$HOOK_DIR")"
SESSION_MEMORY="$ROOT_DIR/context/session-memory.md"

# Discard stdin
cat > /dev/null

echo ""
echo "PRE-COMPACT: Write session memory before context is compacted."
echo ""

if [[ -f "$SESSION_MEMORY" ]]; then
    LAST_MODIFIED=$(stat -c %Y "$SESSION_MEMORY" 2>/dev/null || stat -f %m "$SESSION_MEMORY" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    AGE_MINUTES=$(( (NOW - LAST_MODIFIED) / 60 ))
    echo "context/session-memory.md exists (last updated ${AGE_MINUTES}m ago)."
    echo "Update it now with current state before compaction if anything has changed."
else
    echo "context/session-memory.md does not exist."
    echo "Write it now using the 8-section format (Current State / Task / Files /"
    echo "Workflow / Errors / Learnings / Key Results / Worklog) before compacting."
fi

echo ""
echo "After updating session-memory.md, proceed with compaction."
echo ""

exit 0
