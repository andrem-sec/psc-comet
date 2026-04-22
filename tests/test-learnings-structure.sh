#!/usr/bin/env bash
# tests/test-learnings-structure.sh
#
# Validates the new learnings structure introduced in the Nanobot-inspired refactor:
#   - context/handoff-template.md has required sections
#   - context/learnings-index.md has required structure
#   - context/learnings/ directory exists with all starter tag files
#   - reflect SKILL.md exists and has required frontmatter
#   - wrap-up SKILL.md references learnings-index.md
#   - heartbeat SKILL.md references learnings-index.md
#   - commands/reflect.md and commands/distill.md exist with name/description frontmatter
#   - observe-instinct.sh exits 0 (is a clean no-op)
#
# Usage: bash tests/test-learnings-structure.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

ROOT="$SCRIPT_DIR/.."

echo "=== learnings structure tests ==="
echo ""

# --- handoff-template.md ---

HANDOFF_TEMPLATE="$ROOT/.claude/context/handoff-template.md"

if [ -f "$HANDOFF_TEMPLATE" ]; then
    echo "PASS: handoff-template.md exists"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: handoff-template.md missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if grep -q "## Part 1" "$HANDOFF_TEMPLATE" 2>/dev/null; then
    echo "PASS: handoff-template.md has Part 1 section"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: handoff-template.md missing '## Part 1' section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if grep -q "## Part 2" "$HANDOFF_TEMPLATE" 2>/dev/null; then
    echo "PASS: handoff-template.md has Part 2 section"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: handoff-template.md missing '## Part 2' section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- learnings-index.md ---

LEARNINGS_INDEX="$ROOT/.claude/context/learnings-index.md"

if [ -f "$LEARNINGS_INDEX" ]; then
    echo "PASS: learnings-index.md exists"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: learnings-index.md missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if grep -q "## Tags" "$LEARNINGS_INDEX" 2>/dev/null; then
    echo "PASS: learnings-index.md has Tags section"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: learnings-index.md missing '## Tags' section"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if grep -q "Tag Usage Log" "$LEARNINGS_INDEX" 2>/dev/null; then
    echo "PASS: learnings-index.md has Tag Usage Log"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: learnings-index.md missing Tag Usage Log"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- context/learnings/ directory and starter files ---

LEARNINGS_DIR="$ROOT/.claude/context/learnings"

if [ -d "$LEARNINGS_DIR" ]; then
    echo "PASS: context/learnings/ directory exists"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: context/learnings/ directory missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

for tag in workflow hook bug decision security tool meta platform; do
    if [ -f "$LEARNINGS_DIR/$tag.md" ]; then
        echo "PASS: learnings/$tag.md exists"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "FAIL: learnings/$tag.md missing"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

# --- reflect SKILL.md ---

REFLECT_SKILL="$ROOT/.claude/skills/workflow/reflect/SKILL.md"

if [ -f "$REFLECT_SKILL" ]; then
    echo "PASS: skills/workflow/reflect/SKILL.md exists"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: skills/workflow/reflect/SKILL.md missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

for field in "^name:" "^description:" "^version:" "^level:" "^triggers:"; do
    if grep -q "$field" "$REFLECT_SKILL" 2>/dev/null; then
        echo "PASS: reflect SKILL.md has $field"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "FAIL: reflect SKILL.md missing $field"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

if grep -q "Mandatory Checklist" "$REFLECT_SKILL" 2>/dev/null; then
    echo "PASS: reflect SKILL.md has Mandatory Checklist"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: reflect SKILL.md missing Mandatory Checklist"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- wrap-up SKILL.md references learnings-index.md ---

WRAPUP_SKILL="$ROOT/.claude/skills/core/wrap-up/SKILL.md"

if grep -q "learnings-index.md" "$WRAPUP_SKILL" 2>/dev/null; then
    echo "PASS: wrap-up SKILL.md references learnings-index.md"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: wrap-up SKILL.md does not reference learnings-index.md"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if grep -q "[Rr]eflect" "$WRAPUP_SKILL" 2>/dev/null; then
    echo "PASS: wrap-up SKILL.md references reflect step"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: wrap-up SKILL.md missing reflect step reference"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- heartbeat SKILL.md references learnings-index.md ---

HEARTBEAT_SKILL="$ROOT/.claude/skills/core/heartbeat/SKILL.md"

if grep -q "learnings-index.md" "$HEARTBEAT_SKILL" 2>/dev/null; then
    echo "PASS: heartbeat SKILL.md references learnings-index.md"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: heartbeat SKILL.md does not reference learnings-index.md"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- commands/reflect.md and commands/distill.md frontmatter ---

for cmd in reflect distill; do
    CMD_FILE="$ROOT/.claude/commands/$cmd.md"
    if [ -f "$CMD_FILE" ]; then
        echo "PASS: commands/$cmd.md exists"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "FAIL: commands/$cmd.md missing"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    if grep -q "^name:" "$CMD_FILE" 2>/dev/null; then
        echo "PASS: commands/$cmd.md has name: field"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "FAIL: commands/$cmd.md missing name: field"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    if grep -q "^description:" "$CMD_FILE" 2>/dev/null; then
        echo "PASS: commands/$cmd.md has description: field"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "FAIL: commands/$cmd.md missing description: field"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

# --- observe-instinct.sh is a clean no-op ---

OBS_HOOK="$ROOT/.claude/hooks/observe-instinct.sh"

if [ -f "$OBS_HOOK" ]; then
    actual_exit=0
    bash "$OBS_HOOK" < /dev/null > /dev/null 2>&1 || actual_exit=$?
    assert_exit 0 "$actual_exit" "observe-instinct.sh exits 0 (clean no-op)"
else
    echo "FAIL: observe-instinct.sh missing"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if grep -q "RETIRED" "$OBS_HOOK" 2>/dev/null; then
    echo "PASS: observe-instinct.sh is documented as retired"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: observe-instinct.sh missing RETIRED documentation"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- CLAUDE.md line count ---

CLAUDE_MD="$ROOT/.claude/CLAUDE.md"
lines=$(wc -l < "$CLAUDE_MD")
if [ "$lines" -le 200 ]; then
    echo "PASS: CLAUDE.md is $lines lines (within 200-line limit)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: CLAUDE.md is $lines lines (exceeds 200-line limit)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- reflect in CLAUDE.md registry ---

if grep -q "reflect" "$CLAUDE_MD" 2>/dev/null; then
    echo "PASS: CLAUDE.md skill registry includes reflect"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL: CLAUDE.md skill registry missing reflect"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""
test_summary
