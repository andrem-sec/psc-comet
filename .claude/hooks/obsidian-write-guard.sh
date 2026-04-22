#!/usr/bin/env bash
# PreToolUse: mcp__obsidian__obsidian_patch | mcp__obsidian__obsidian_append
# Blocks writes to the protected vault path configured in ~/.claude/psc-personal-path.
# If the config file does not exist, this hook is a no-op.
#
# To enable: echo "YourPersonalFolder/" > ~/.claude/psc-personal-path

set -euo pipefail

GUARD_CFG="${HOME}/.claude/psc-personal-path"

if [ ! -f "$GUARD_CFG" ]; then
    exit 0
fi

PROTECTED=$(cat "$GUARD_CFG")

if [ -z "$PROTECTED" ]; then
    exit 0
fi

INPUT=$(cat)
VAULT_PATH=$(echo "$INPUT" | grep -oP '"path"\s*:\s*"\K[^"]+' 2>/dev/null | head -1 || echo "")

if [ -z "$VAULT_PATH" ]; then
    exit 0
fi

if echo "$VAULT_PATH" | grep -qE "^${PROTECTED}"; then
    echo "BLOCKED: Write to '$VAULT_PATH' rejected." >&2
    echo "Path matches protected prefix '${PROTECTED}' in ~/.claude/psc-personal-path." >&2
    echo "To allow this write, explicitly tell Claude to do so in this session." >&2
    exit 2
fi

exit 0
