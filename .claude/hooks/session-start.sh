#!/usr/bin/env bash
# InstructionsLoaded hook (fires when CLAUDE.md is loaded at session start)
# Validates that required context files exist and are populated.
# Reminds user to run /heartbeat if context files are empty.

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT_DIR="$(dirname "$HOOK_DIR")/context"

ISSUES=()

# user.md is gitignored — check it exists (i.e. user has run /start-here)
if [ ! -f "$CONTEXT_DIR/user.md" ]; then
    ISSUES+=("context/user.md not found — run /start-here to create your local profile")
fi

# Check if project.md is still a template
if [ -f "$CONTEXT_DIR/project.md" ]; then
    if grep -q "\[e.g.," "$CONTEXT_DIR/project.md" 2>/dev/null; then
        ISSUES+=("context/project.md is unpopulated — update it for this project")
    fi
fi

if [ ${#ISSUES[@]} -gt 0 ]; then
    echo "" >&2
    echo "============================================" >&2
    echo " [Session Start] Action required:" >&2
    echo "============================================" >&2
    for issue in "${ISSUES[@]}"; do
        echo "  - $issue" >&2
    done
    echo "" >&2
    echo "  Run /start-here for first-time setup." >&2
    echo "  Run /heartbeat to orient an existing session." >&2
    echo "============================================" >&2
fi

# Frontload core behavioral skills so they survive context compaction
SKILLS_DIR="$(dirname "$HOOK_DIR")/skills"

FRONTLOAD_SKILLS=(
    "$SKILLS_DIR/workflow/plan-first/SKILL.md"
    "$SKILLS_DIR/core/roe/SKILL.md"
    "$SKILLS_DIR/workflow/intent-router/SKILL.md"
    "$SKILLS_DIR/core/security-gate/SKILL.md"
)

echo "" >&2
echo "[Session Start] Loading core behavioral skills:" >&2
for skill in "${FRONTLOAD_SKILLS[@]}"; do
    if [ -f "$skill" ]; then
        echo "  + $(basename "$(dirname "$skill")")" >&2
        cat "$skill" >&2
    fi
done

exit 0
