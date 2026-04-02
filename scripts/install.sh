#!/usr/bin/env bash
# PSC Install Script
# Patches .claude/settings.json hook paths to absolute paths for this machine.
# Run once after cloning: bash scripts/install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETTINGS="$PROJECT_ROOT/.claude/settings.json"

echo "[psc-install] Project root: $PROJECT_ROOT"

if [ ! -f "$SETTINGS" ]; then
  echo "[psc-install] ERROR: $SETTINGS not found"
  exit 1
fi

# Count relative hook paths before patching
RELATIVE_COUNT=$(grep -c '"bash \.claude/hooks/' "$SETTINGS" 2>/dev/null || true)

if [ "$RELATIVE_COUNT" -eq 0 ]; then
  echo "[psc-install] Hook paths already absolute — nothing to patch"
  exit 0
fi

# On Windows/Git Bash, convert path to forward slashes for JSON compatibility
if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32"* ]]; then
  # Convert C:\path\to -> C:/path/to
  PROJECT_ROOT_JSON=$(echo "$PROJECT_ROOT" | sed 's|\\|/|g')
else
  PROJECT_ROOT_JSON="$PROJECT_ROOT"
fi

# Patch: replace "bash .claude/hooks/ with "bash /absolute/path/.claude/hooks/
sed -i.bak "s|\"bash \\.claude/hooks/|\"bash $PROJECT_ROOT_JSON/.claude/hooks/|g" "$SETTINGS"

PATCHED_COUNT=$(grep -c "\"bash $PROJECT_ROOT_JSON/.claude/hooks/" "$SETTINGS" 2>/dev/null || true)
echo "[psc-install] Patched $PATCHED_COUNT hook paths -> $PROJECT_ROOT_JSON/.claude/hooks/"

# Clean up backup
rm -f "$SETTINGS.bak"

echo "[psc-install] Done. Restart Claude Code for changes to take effect."
