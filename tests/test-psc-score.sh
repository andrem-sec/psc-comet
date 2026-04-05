#!/usr/bin/env bash
# tests/test-psc-score.sh -- tests for scripts/scoring/psc-score.sh
#
# Uses PSC_ROOT pointing to the actual repo (health check must pass against it).
# rubric.yaml is gitignored so temp files in scripts/scoring/ are safe.
# Usage: bash tests/test-psc-score.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/helpers.sh
source "$SCRIPT_DIR/helpers.sh"

PSC_SCORE="$SCRIPT_DIR/../scripts/scoring/psc-score.sh"
PSC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUBRIC="$PSC_ROOT/scripts/scoring/rubric.yaml"

# Ensure rubric.yaml is cleaned up even if tests fail
cleanup() { rm -f "$RUBRIC"; }
trap cleanup EXIT

run_score() {
    local code
    PSC_ROOT="$PSC_ROOT" bash "$PSC_SCORE" > /dev/null 2>/dev/null && code=0 || code=$?
    echo "$code"
}

echo "=== psc-score.sh tests ==="
echo ""

# --- Guard: rubric.yaml must exist ---

cleanup
actual=$(run_score); assert_exit 1 "$actual" "missing rubric.yaml -> exit 1"

# --- Guard: acknowledgment required ---

cat > "$RUBRIC" << 'EOF'
acknowledged: false
dimensions:
  - name: test
    description: "test"
    command: "exit 0"
    weight: 1.0
EOF
actual=$(run_score); assert_exit 1 "$actual" "acknowledged false -> exit 1"

# --- Happy path: all pass ---

cat > "$RUBRIC" << 'EOF'
acknowledged: true
dimensions:
  - name: always-pass
    description: "always passes"
    command: "exit 0"
    weight: 1.0
EOF
actual=$(run_score)
assert_exit 0 "$actual" "valid rubric, passing dimension -> exit 0"

# Verify output contains floor_pass: true and score > 0
output=$(PSC_ROOT="$PSC_ROOT" bash "$PSC_SCORE" 2>/dev/null)
assert_output_contains '"floor_pass": true' "$output" "output contains floor_pass: true"
assert_output_contains '"score":' "$output" "output contains score field"

# --- Failing dimension: score < 1 but exit 0 (scoring still runs) ---

cat > "$RUBRIC" << 'EOF'
acknowledged: true
dimensions:
  - name: always-fail
    description: "always fails"
    command: "exit 1"
    weight: 1.0
EOF
output=$(PSC_ROOT="$PSC_ROOT" bash "$PSC_SCORE" 2>/dev/null)
assert_output_contains '"score": 0.0' "$output" "failing dimension -> score 0.0"

# --- No dimensions defined ---

cat > "$RUBRIC" << 'EOF'
acknowledged: true
dimensions:
EOF
output=$(PSC_ROOT="$PSC_ROOT" bash "$PSC_SCORE" 2>/dev/null)
assert_output_contains 'No dimensions defined' "$output" "empty dimensions -> note in output"

test_summary
