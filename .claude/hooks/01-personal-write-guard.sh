#!/usr/bin/env bash
# PreToolUse: mcp__obsidian__obsidian_patch | mcp__obsidian__obsidian_append
# Blocks writes to 01. Personal/ in the Obsidian vault.
# Claude may read anywhere but may only write to 02. AI-Vault/ unless explicitly told otherwise.

set -euo pipefail

INPUT=$(cat)

# Extract the vault path from tool_input.path
# Uses grep with PCRE to pull the value out of JSON without requiring python3
VAULT_PATH=$(echo "$INPUT" | grep -oP '"path"\s*:\s*"\K[^"]+' 2>/dev/null | head -1 || echo "")

if [ -z "$VAULT_PATH" ]; then
    exit 0
fi

if echo "$VAULT_PATH" | grep -qE "^01\. Personal/"; then
    echo "BLOCKED: Write to '$VAULT_PATH' rejected." >&2
    echo "Claude may not write to '01. Personal/' -- read-only by default." >&2
    echo "To allow a specific write, explicitly tell Claude to do so in this session." >&2
    exit 2
fi

exit 0
