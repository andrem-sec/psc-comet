#!/usr/bin/env bash
# tests/test-psc-health-check.sh -- tests for scripts/psc-health-check.sh
#
# Each test creates an isolated temp dir, mutates one thing, and checks exit code.
# Usage: bash tests/test-psc-health-check.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

HEALTH_CHECK="$SCRIPT_DIR/../scripts/psc-health-check.sh"

# Run health check against a temp dir, capture exit code
run_check() {
    local code
    PSC_ROOT="$1" bash "$HEALTH_CHECK" > /dev/null 2>&1 && code=0 || code=$?
    echo "$code"
}

echo "=== psc-health-check.sh tests ==="
echo ""

# --- Happy path ---

t=$(mktemp -d); make_minimal_psc "$t"
actual=$(run_check "$t"); assert_exit 0 "$actual" "valid PSC structure -> exit 0"
rm -rf "$t"

# --- Floor 1: CLAUDE.md ---

t=$(mktemp -d); make_minimal_psc "$t"
rm -f "$t/.claude/CLAUDE.md"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 1: missing CLAUDE.md -> exit 1"
rm -rf "$t"

t=$(mktemp -d); make_minimal_psc "$t"
# Generate a 201-line CLAUDE.md (valid content, just too long)
cat "$t/.claude/CLAUDE.md" > "$t/.claude/CLAUDE.md.tmp"
for i in $(seq 1 200); do echo "# padding line $i"; done >> "$t/.claude/CLAUDE.md.tmp"
mv "$t/.claude/CLAUDE.md.tmp" "$t/.claude/CLAUDE.md"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 1: CLAUDE.md over 200 lines -> exit 1"
rm -rf "$t"

# --- Floor 2: settings.json ---

t=$(mktemp -d); make_minimal_psc "$t"
rm -f "$t/.claude/settings.json"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 2: missing settings.json -> exit 1"
rm -rf "$t"

t=$(mktemp -d); make_minimal_psc "$t"
echo "not valid json {{{" > "$t/.claude/settings.json"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 2: invalid settings.json -> exit 1"
rm -rf "$t"

# --- Floor 3: hooks on disk ---

t=$(mktemp -d); make_minimal_psc "$t"
rm -f "$t/.claude/hooks/test-hook.sh"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 3: hook file missing from disk -> exit 1"
rm -rf "$t"

# --- Floor 4: agent files ---

t=$(mktemp -d); make_minimal_psc "$t"
rm -f "$t/.claude/agents/researcher.md"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 4: registered agent has no file -> exit 1"
rm -rf "$t"

# --- Floor 5: skill directories ---

t=$(mktemp -d); make_minimal_psc "$t"
rm -rf "$t/.claude/skills/core/heartbeat"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 5: registered skill has no directory -> exit 1"
rm -rf "$t"

# --- Floor 6: agent frontmatter ---

t=$(mktemp -d); make_minimal_psc "$t"
sed -i '/^name:/d' "$t/.claude/agents/researcher.md"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 6: agent missing name: -> exit 1"
rm -rf "$t"

t=$(mktemp -d); make_minimal_psc "$t"
sed -i '/^description:/d' "$t/.claude/agents/researcher.md"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 6: agent missing description: -> exit 1"
rm -rf "$t"

t=$(mktemp -d); make_minimal_psc "$t"
sed -i '/^tools:/d' "$t/.claude/agents/researcher.md"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 6: agent missing tools: -> exit 1"
rm -rf "$t"

# --- Floor 7: skill frontmatter ---

t=$(mktemp -d); make_minimal_psc "$t"
sed -i '/^version:/d' "$t/.claude/skills/core/heartbeat/SKILL.md"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 7: SKILL.md missing version: -> exit 1"
rm -rf "$t"

t=$(mktemp -d); make_minimal_psc "$t"
sed -i '/^level:/d' "$t/.claude/skills/core/heartbeat/SKILL.md"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 7: SKILL.md missing level: -> exit 1"
rm -rf "$t"

t=$(mktemp -d); make_minimal_psc "$t"
sed -i '/^triggers:/d' "$t/.claude/skills/workflow/wrap-up/SKILL.md"
actual=$(run_check "$t"); assert_exit 1 "$actual" "Floor 7: SKILL.md missing triggers: -> exit 1"
rm -rf "$t"

test_summary
