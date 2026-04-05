#!/usr/bin/env bash
# psc-score.sh -- deployer-configured scoring framework for PSC harness quality
#
# Reads scripts/scoring/rubric.yaml (deployer-provided, gitignored).
# Always runs psc-health-check.sh first -- a floor failure scores 0 and exits.
# Outputs a JSON summary to stdout.
#
# Usage: bash scripts/scoring/psc-score.sh
#        PSC_ROOT=/path/to/repo bash scripts/scoring/psc-score.sh
#
# Prerequisites: python3 or python (for YAML parsing and JSON output)

set -euo pipefail

# Detect working Python interpreter (python3 Store alias on Windows is non-functional)
_py_works() { "$1" --version 2>&1 | grep -qE "^Python [0-9]+\.[0-9]+"; }
if command -v python3 > /dev/null 2>&1 && _py_works python3; then
    PYTHON=python3
elif command -v python > /dev/null 2>&1 && _py_works python; then
    PYTHON=python
else
    echo "ERROR: python3 or python is required but not available." >&2
    exit 1
fi

if [ -z "${PSC_ROOT:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PSC_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

RUBRIC="$PSC_ROOT/scripts/scoring/rubric.yaml"
HEALTH_CHECK="$PSC_ROOT/scripts/psc-health-check.sh"

# Guard: rubric.yaml must exist
if [ ! -f "$RUBRIC" ]; then
    echo "ERROR: rubric.yaml not found at $RUBRIC" >&2
    echo "Copy scripts/scoring/rubric-template.yaml to scripts/scoring/rubric.yaml and configure your metrics." >&2
    exit 1
fi

# Guard: acknowledgment required
if ! grep -q "^acknowledged: true" "$RUBRIC"; then
    echo "ERROR: Risk acknowledgment required." >&2
    echo "Read the risk section in rubric.yaml, then set acknowledged: true." >&2
    exit 1
fi

# Floor check: must pass before scoring runs
echo "Running floor checks..." >&2
floor_pass=true
if ! bash "$HEALTH_CHECK" > /dev/null 2>&1; then
    floor_pass=false
fi

if [ "$floor_pass" = false ]; then
    $PYTHON - <<'EOF'
import json
print(json.dumps({
    "floor_pass": False,
    "score": 0.0,
    "note": "Hard floor check failed. Score is 0 regardless of rubric. Run psc-health-check.sh for details.",
    "dimensions": []
}, indent=2))
EOF
    exit 1
fi

# Run rubric dimensions
$PYTHON - "$RUBRIC" <<'EOF'
import json
import subprocess
import sys

rubric_path = sys.argv[1]

# Minimal YAML parser for the rubric format (no external deps required)
def parse_rubric(path):
    dimensions = []
    current = None
    in_dimensions = False

    with open(path) as f:
        for line in f:
            stripped = line.rstrip()
            if stripped.startswith("dimensions:"):
                in_dimensions = True
                continue
            if not in_dimensions:
                continue
            if stripped.startswith("  - name:"):
                if current:
                    dimensions.append(current)
                current = {"name": stripped.split(":", 1)[1].strip(), "description": "", "command": "", "weight": 1.0}
            elif current is not None:
                if stripped.startswith("    description:"):
                    current["description"] = stripped.split(":", 1)[1].strip().strip('"')
                elif stripped.startswith("    command:"):
                    current["command"] = stripped.split(":", 1)[1].strip().strip('"')
                elif stripped.startswith("    weight:"):
                    try:
                        current["weight"] = float(stripped.split(":", 1)[1].strip())
                    except ValueError:
                        pass

    if current:
        dimensions.append(current)

    return dimensions

dimensions = parse_rubric(rubric_path)

if not dimensions:
    print(json.dumps({
        "floor_pass": True,
        "score": 0.0,
        "note": "No dimensions defined in rubric.yaml. Configure at least one metric.",
        "dimensions": []
    }, indent=2))
    sys.exit(0)

total_weight = sum(d["weight"] for d in dimensions)
results = []
weighted_score = 0.0

for dim in dimensions:
    try:
        result = subprocess.run(
            dim["command"],
            shell=True,
            capture_output=True,
            text=True,
            timeout=30
        )
        passed = result.returncode == 0
    except subprocess.TimeoutExpired:
        passed = False
        result = type("r", (), {"stdout": "", "stderr": "timeout"})()

    score = 1.0 if passed else 0.0
    weighted_score += score * (dim["weight"] / total_weight)

    results.append({
        "name": dim["name"],
        "description": dim["description"],
        "passed": passed,
        "score": score,
        "weight": dim["weight"]
    })

print(json.dumps({
    "floor_pass": True,
    "score": round(weighted_score, 4),
    "dimensions": results
}, indent=2))
EOF
