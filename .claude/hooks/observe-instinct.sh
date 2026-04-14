#!/usr/bin/env bash
# Stop Hook: Observe session for instinct learning
# Cross-platform compatible (Windows/Linux/macOS)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$CLAUDE_DIR")"

# Source cross-platform utilities
if [ -f "$PROJECT_ROOT/scripts/detect-platform.sh" ]; then
    source "$PROJECT_ROOT/scripts/detect-platform.sh"
    # Use normalized paths for cross-platform compatibility
    CLI_PATH="$(normalize_path "$PROJECT_ROOT/scripts/continuous-learning-v2/instinct-cli.py")"
else
    # Fallback if detect-platform.sh not found
    CLI_PATH="$PROJECT_ROOT/scripts/continuous-learning-v2/instinct-cli.py"
fi

# Check if Python + Phase 8 available
if ! PYTHON_CMD=$(bash "$PROJECT_ROOT/scripts/check-dependencies.sh" 2>/dev/null | grep PYTHON_CMD | cut -d= -f2); then
    # Python unavailable - silent exit (no-op)
    exit 0
fi

if [ ! -f "$CLI_PATH" ]; then
    exit 0
fi

# Extract observations from session
# (Simplified - real version would analyze tool calls, patterns, etc.)

# For now: Log that observation hook ran
# Future: Parse tool call traces, identify patterns, auto-add instincts

echo "observe-instinct: Session observation complete (OS: ${DETECTED_OS:-unknown})" >&2
exit 0
