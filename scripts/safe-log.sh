#!/usr/bin/env bash
# Utility: safe_log
#
# Logs an event with metadata to a JSONL file, but first validates that the
# metadata does not contain code, file paths, credentials, or other content
# that should never appear in telemetry.
#
# Mirrors the intent of Claude Code's AnalyticsMetadata_I_VERIFIED_THIS_IS_NOT_CODE_OR_FILEPATHS
# type guard — enforced at runtime via pattern matching rather than compile-time types.
#
# Usage:
#   source scripts/safe-log.sh
#   safe_log "session_end" "outcome=success" "$LOG_FILE"
#   safe_log "tool_use" "tool=Bash duration_ms=450" "$LOG_FILE"
#
# If metadata fails the content check, the event is dropped and a warning is
# written to stderr. Events are never silently dropped without a warning.

SAFE_LOG_BLOCKED_PATTERNS=(
    '\/[a-z]{2,}\/[a-z]'    # looks like a file path (/home/user, /etc/passwd)
    'import '                 # code
    'function '               # code
    'class '                  # code
    'SELECT '                 # SQL
    'INSERT '                 # SQL
    'Bearer '                 # auth token
    'sk-[a-zA-Z0-9]'         # API key pattern
    'ghp_[a-zA-Z0-9]'        # GitHub token
    'password'                # credential field
    'secret'                  # credential field
    '(access|auth|api|session|refresh|id)_token' # credential token fields only
    'api[_-]key'             # API key field name
)

safe_log() {
    local event="$1"
    local metadata="$2"
    local log_file="${3:-/dev/stderr}"

    # Validate event name — must be identifier-safe
    if [[ ! "$event" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "SAFE_LOG BLOCKED: Event name '$event' contains invalid characters." >&2
        return 1
    fi

    # Validate metadata — must not look like code or credentials
    for pattern in "${SAFE_LOG_BLOCKED_PATTERNS[@]}"; do
        if echo "$metadata" | grep -qiE "$pattern" 2>/dev/null; then
            echo "SAFE_LOG BLOCKED: Metadata for event '$event' matched sensitive pattern '$pattern'." >&2
            echo "  Review what is being logged. Metadata must not contain code, paths, or credentials." >&2
            return 1
        fi
    done

    # Truncate metadata to 200 chars
    local safe_meta="${metadata:0:200}"
    local ts
    ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    printf '{"ts":"%s","event":"%s","meta":"%s"}\n' \
        "$ts" \
        "$event" \
        "$safe_meta" \
        >> "$log_file"

    return 0
}
