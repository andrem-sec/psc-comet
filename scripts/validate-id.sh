#!/usr/bin/env bash
# Utility: validate_bridge_id
#
# Validates that a server-provided or externally-sourced identifier contains
# only safe characters before it is interpolated into a URL, file path, or
# shell command. Prevents path traversal and injection via untrusted ID values.
#
# Usage:
#   source scripts/validate-id.sh
#   validate_bridge_id "$SESSION_ID" "session ID" || exit 1
#   validate_bridge_id "$WORK_ID" "work unit ID" || exit 1
#
# Pattern: [a-zA-Z0-9_-]+ (same as Claude Code's validateBridgeId)
# Max length: 128 characters

validate_bridge_id() {
    local id="$1"
    local label="${2:-ID}"
    local max_len="${3:-128}"

    if [[ -z "$id" ]]; then
        echo "VALIDATION ERROR: $label is empty." >&2
        return 1
    fi

    if [[ ${#id} -gt $max_len ]]; then
        echo "VALIDATION ERROR: $label '${id:0:20}...' exceeds max length ($max_len chars)." >&2
        return 1
    fi

    if [[ ! "$id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "VALIDATION ERROR: $label '$id' contains invalid characters." >&2
        echo "  Allowed: [a-zA-Z0-9_-]" >&2
        echo "  Received: $id" >&2
        return 1
    fi

    return 0
}

# Validate a worktree slug (stricter: also validates length for git compat)
validate_worktree_slug() {
    local slug="$1"

    if [[ -z "$slug" ]]; then
        echo "VALIDATION ERROR: Worktree slug is empty." >&2
        return 1
    fi

    if [[ ${#slug} -gt 64 ]]; then
        echo "VALIDATION ERROR: Worktree slug '${slug:0:20}...' exceeds 64 chars." >&2
        return 1
    fi

    # Block path traversal segments
    if [[ "$slug" =~ (^|/)\.\.(\/|$) ]] || [[ "$slug" == "." ]] || [[ "$slug" == ".." ]]; then
        echo "VALIDATION ERROR: Worktree slug contains path traversal." >&2
        return 1
    fi

    if [[ ! "$slug" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "VALIDATION ERROR: Worktree slug '$slug' contains invalid characters." >&2
        echo "  Allowed: [a-zA-Z0-9._-]" >&2
        return 1
    fi

    return 0
}

# Flatten a slash-separated slug to a safe single-segment name
# "user/feature" → "user+feature" (injective, no collision)
flatten_slug() {
    local slug="$1"
    echo "${slug//\//$'+'}"
}
