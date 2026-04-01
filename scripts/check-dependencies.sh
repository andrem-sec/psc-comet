#!/usr/bin/env bash
# Phase 8 Dependency Checker
# Detects Python, validates it's real (not stub), checks version

set -euo pipefail

check_python() {
    local python_cmd="$1"

    # Check if command exists
    if ! command -v "$python_cmd" &>/dev/null; then
        return 1
    fi

    # Validate it's real Python (not Windows stub)
    # Windows stub fails on --version with specific error
    if ! "$python_cmd" --version &>/dev/null; then
        return 1
    fi

    # Check version >= 3.6 (minimum), compatible up to 3.12+
    # Use % formatting (not f-strings) for 3.5 compatibility during check
    local version=$("$python_cmd" -c "import sys; print('%d.%d' % (sys.version_info.major, sys.version_info.minor))" 2>/dev/null || echo "0.0")
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)

    # Accept Python 3.6 through 3.x (forward compatible)
    if [ "$major" -eq 3 ] && [ "$minor" -ge 6 ]; then
        echo "$python_cmd"
        return 0
    fi

    # Accept Python 4+ when it exists (future-proof)
    if [ "$major" -ge 4 ]; then
        echo "$python_cmd"
        return 0
    fi

    return 1
}

# Try python3 first (Linux standard), then python (Windows common)
PYTHON_CMD=""
for cmd in python3 python; do
    if PYTHON_CMD=$(check_python "$cmd"); then
        break
    fi
done

# Fallback: Check common Windows Python locations
if [ -z "$PYTHON_CMD" ]; then
    # Common Windows installation paths
    WIN_PATHS=(
        "$HOME/AppData/Local/Python/bin/python.exe"
        "$HOME/AppData/Local/Programs/Python/Python*/python.exe"
        "/c/Python*/python.exe"
    )

    for pattern in "${WIN_PATHS[@]}"; do
        # Expand glob patterns
        for python_path in $pattern; do
            if [ -f "$python_path" ]; then
                if PYTHON_CMD=$(check_python "$python_path"); then
                    break 2
                fi
            fi
        done
    done
fi

if [ -z "$PYTHON_CMD" ]; then
    echo "ERROR: Python 3.6+ not found" >&2
    echo "Install: https://www.python.org/downloads/" >&2
    echo "" >&2
    echo "Or add Python to PATH if already installed." >&2
    exit 1
fi

echo "PYTHON_CMD=$PYTHON_CMD"
echo "PYTHON_VERSION=$($PYTHON_CMD --version)"
exit 0
