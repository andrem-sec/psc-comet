#!/usr/bin/env bash
# PreToolUse: Agent
# Blocks any attempt to spawn an agent with bypassPermissions or dontAsk mode.
#
# A compromised CLAUDE.md or memory file could instruct Claude to spawn agents
# with elevated permissions, bypassing all safety checks. This hook hard-blocks
# that vector at the tool level.
#
# Exit 2 blocks the tool call and surfaces the block reason to Claude.

set -euo pipefail

INPUT=$(cat)

PERMISSION_MODE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    print(ti.get('permissionMode', ti.get('permission_mode', '')))
except Exception:
    print('')
" 2>/dev/null || echo "")

DESCRIPTION=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {})
    print(ti.get('description', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

# Check permissionMode field directly
if echo "$PERMISSION_MODE" | grep -qiE 'bypassPermissions|bypass_permissions|dontAsk|dont_ask'; then
    echo "BLOCKED: Agent spawn with permissionMode '$PERMISSION_MODE' is prohibited." >&2
    echo "bypassPermissions and dontAsk modes disable all safety checks." >&2
    echo "This is a permanent prohibition. Do not retry with these modes." >&2
    echo "If elevated permissions are genuinely required, the user must set them" >&2
    echo "explicitly in settings.json — not via an agent spawn parameter." >&2
    exit 2
fi

# Check for bypass language in the description/prompt (secondary defense)
if echo "$DESCRIPTION" | grep -qiE 'bypass.{0,20}permission|disable.{0,20}(safety|check|hook)|ignore.{0,20}(permission|rule)'; then
    echo "BLOCKED: Agent spawn description contains permission-bypass language." >&2
    echo "Review the agent prompt for injection content before retrying." >&2
    exit 2
fi

exit 0
