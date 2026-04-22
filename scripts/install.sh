#!/usr/bin/env bash
# PSC Install Script
# Patches .claude/settings.json hook paths to absolute paths for this machine.
# Run once after cloning: bash scripts/install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETTINGS="$PROJECT_ROOT/.claude/settings.json"

TEMPLATE="$PROJECT_ROOT/.claude/settings.template.json"

echo "[psc-install] Project root: $PROJECT_ROOT"

if [ ! -f "$TEMPLATE" ]; then
  echo "[psc-install] ERROR: $TEMPLATE not found"
  exit 1
fi

# Skip if settings.json already exists and has no {{PSC_ROOT}} placeholders
if [ -f "$SETTINGS" ] && ! grep -q '{{PSC_ROOT}}' "$SETTINGS" 2>/dev/null; then
  echo "[psc-install] Hook paths already patched for this machine -- nothing to do"
  exit 0
fi

# On Windows/Git Bash, convert path to forward slashes for JSON compatibility
if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32"* ]]; then
  PROJECT_ROOT_JSON=$(echo "$PROJECT_ROOT" | sed 's|\\|/|g')
else
  PROJECT_ROOT_JSON="$PROJECT_ROOT"
fi

echo "[psc-install] Generating settings.json from template..."
cp "$TEMPLATE" "$SETTINGS"
sed -i.bak "s|{{PSC_ROOT}}|$PROJECT_ROOT_JSON|g" "$SETTINGS"
rm -f "$SETTINGS.bak"

PATCHED_COUNT=$(grep -c "\"bash $PROJECT_ROOT_JSON/.claude/hooks/" "$SETTINGS" 2>/dev/null || true)
echo "[psc-install] Patched $PATCHED_COUNT hook paths -> $PROJECT_ROOT_JSON/.claude/hooks/"

# ── Statusline scripts ─────────────────────────────────────────────────────

STATUSLINE_SRC="$SCRIPT_DIR/statusline"
CLAUDE_HOME="$HOME/.claude"

if [ -d "$STATUSLINE_SRC" ]; then
    cp "$STATUSLINE_SRC/statusline-command.sh"  "$CLAUDE_HOME/statusline-command.sh"
    cp "$STATUSLINE_SRC/subagent-statusline.sh" "$CLAUDE_HOME/subagent-statusline.sh"
    chmod +x "$CLAUDE_HOME/statusline-command.sh" "$CLAUDE_HOME/subagent-statusline.sh"
    echo "[psc-install] Copied statusline scripts -> $CLAUDE_HOME/"

    if [ ! -f "$CLAUDE_HOME/psc-vault-path" ]; then
        cp "$STATUSLINE_SRC/psc-vault-path.example" "$CLAUDE_HOME/psc-vault-path"
        echo "[psc-install] Created $CLAUDE_HOME/psc-vault-path -- update with your vault path"
    fi

    GLOBAL_SETTINGS="$CLAUDE_HOME/settings.json"
    if [ -f "$GLOBAL_SETTINGS" ] && command -v jq >/dev/null 2>&1; then
        if ! jq -e '.statusLine' "$GLOBAL_SETTINGS" >/dev/null 2>&1; then
            jq --arg home "$HOME" '. + {
                "statusLine": {"type": "command", "command": ("bash " + $home + "/.claude/statusline-command.sh")},
                "subagentStatusLine": {"type": "command", "command": ("bash " + $home + "/.claude/subagent-statusline.sh")}
            }' "$GLOBAL_SETTINGS" > "${GLOBAL_SETTINGS}.tmp" && mv "${GLOBAL_SETTINGS}.tmp" "$GLOBAL_SETTINGS"
            echo "[psc-install] Registered statusLine in $GLOBAL_SETTINGS"
        else
            echo "[psc-install] statusLine already registered -- skipping"
        fi
    else
        echo "[psc-install] NOTE: statusLine not auto-registered (jq unavailable or settings.json missing)"
        echo "[psc-install]   Add manually: statusLine.command = bash \$HOME/.claude/statusline-command.sh"
    fi
else
    echo "[psc-install] NOTE: scripts/statusline/ not found -- skipping statusline install"
fi

echo "[psc-install] Done. Restart Claude Code for changes to take effect."
