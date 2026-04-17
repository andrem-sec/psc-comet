#!/usr/bin/env bash
# Stop hook — Ember gate: automatic memory consolidation trigger.
#
# Checks two gates after every session stop:
#   Gate 1 (time): hours since last consolidation >= MIN_HOURS (default: 24)
#   Gate 2 (sessions): sessions since last consolidation >= MIN_SESSIONS (default: 5)
#
# If both gates pass: writes .claude/context/ember-due flag.
# The heartbeat skill reads this flag at next session start and
# prompts the user to run /distill for memory consolidation.
#
# Lock file: .claude/context/ember.lock
#   - body: PID of last writer
#   - mtime: timestamp of last successful consolidation (dual-purpose)
#
# Counter file: .claude/context/ember.count
#   - body: integer session count since last consolidation

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$HOOK_DIR")"
CONTEXT_DIR="$ROOT_DIR/context"

LOCK_FILE="$CONTEXT_DIR/ember.lock"
COUNT_FILE="$CONTEXT_DIR/ember.count"
DUE_FILE="$CONTEXT_DIR/ember-due"

MIN_HOURS=24
MIN_SESSIONS=5

# Discard stdin
cat > /dev/null

mkdir -p "$CONTEXT_DIR"

# --- Session counter ---
CURRENT_COUNT=0
if [[ -f "$COUNT_FILE" ]]; then
    CURRENT_COUNT=$(cat "$COUNT_FILE" 2>/dev/null || echo "0")
    CURRENT_COUNT=$(echo "$CURRENT_COUNT" | tr -dc '0-9' || echo "0")
fi
CURRENT_COUNT=$(( CURRENT_COUNT + 1 ))
echo "$CURRENT_COUNT" > "$COUNT_FILE"

# --- Time gate ---
NOW=$(date +%s)
LAST_CONSOLIDATION=0

if [[ -f "$LOCK_FILE" ]]; then
    # mtime of lock file IS the last consolidation timestamp (dual-purpose pattern)
    LAST_CONSOLIDATION=$(stat -c %Y "$LOCK_FILE" 2>/dev/null || stat -f %m "$LOCK_FILE" 2>/dev/null || echo "0")
fi

HOURS_ELAPSED=$(( (NOW - LAST_CONSOLIDATION) / 3600 ))
TIME_GATE_PASSED=false
if [[ $HOURS_ELAPSED -ge $MIN_HOURS ]]; then
    TIME_GATE_PASSED=true
fi

# --- Session gate ---
SESSION_GATE_PASSED=false
if [[ $CURRENT_COUNT -ge $MIN_SESSIONS ]]; then
    SESSION_GATE_PASSED=true
fi

# --- Both gates must pass ---
if [[ "$TIME_GATE_PASSED" == true && "$SESSION_GATE_PASSED" == true ]]; then
    # Write due flag (heartbeat reads this at next session start)
    echo "$CURRENT_COUNT sessions, ${HOURS_ELAPSED}h since last consolidation" > "$DUE_FILE"

    # Acquire lock — write PID, update mtime to NOW (marks consolidation as triggered)
    echo "$$" > "$LOCK_FILE"

    # Reset session counter
    echo "0" > "$COUNT_FILE"

    # Ember triggered -- do NOT suppress output so the user sees the consolidation notice.
    printf '{"suppressOutput":false}\n'
else
    # No trigger -- nothing to surface to the user.
    printf '{"suppressOutput":true}\n'
fi

exit 0
