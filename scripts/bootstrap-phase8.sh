#!/usr/bin/env bash
# Phase 8 Bootstrap - Automated dependency installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")/.claude"
REQUIREMENTS="$SCRIPT_DIR/requirements.txt"

echo "=== Phase 8 Bootstrap ==="
echo ""

# Step 1: Detect Python
echo "[1/4] Detecting Python..."
if ! PYTHON_INFO=$(bash "$SCRIPT_DIR/check-dependencies.sh" 2>&1); then
    echo "$PYTHON_INFO"
    echo ""
    echo "Phase 8 requires Python 3.6+. Install from:"
    echo "  Windows: https://www.python.org/downloads/"
    echo "  Linux: sudo apt install python3 python3-pip"
    echo "  macOS: brew install python3"
    exit 1
fi

PYTHON_CMD=$(echo "$PYTHON_INFO" | grep "PYTHON_CMD=" | cut -d= -f2)
echo "[OK] Found: $PYTHON_CMD"
echo ""

# Step 2: Check/Install pip
echo "[2/4] Checking pip..."
if ! "$PYTHON_CMD" -m pip --version &>/dev/null; then
    echo "pip not found. Installing..."
    "$PYTHON_CMD" -m ensurepip --default-pip || {
        echo "ERROR: Failed to install pip" >&2
        exit 1
    }
fi
echo "[OK] pip available"
echo ""

# Step 3: Install dependencies
echo "[3/4] Installing Phase 8 dependencies..."
"$PYTHON_CMD" -m pip install --user -q -r "$REQUIREMENTS" || {
    echo "ERROR: Failed to install dependencies" >&2
    echo "Try manually: $PYTHON_CMD -m pip install -r $REQUIREMENTS" >&2
    exit 1
}
echo "[OK] Dependencies installed"
echo ""

# Step 4: Validate installation
echo "[4/4] Validating installation..."
"$PYTHON_CMD" "$SCRIPT_DIR/continuous-learning-v2/instinct-cli.py" --version || {
    echo "ERROR: instinct-cli.py validation failed" >&2
    exit 1
}
echo "[OK] Phase 8 ready"
echo ""

echo "Bootstrap complete! Phase 8 features available."
echo "Run: /instinct-status to view learned instincts"
exit 0
