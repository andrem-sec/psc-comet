#!/usr/bin/env bash
# Stop hook — scans modified files for debug output patterns
# Complements warn-debug-output.sh (PostToolUse) by catching Bash-created files
# and providing batch scanning at session boundaries.

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$HOOK_DIR")")"
TELEMETRY_DIR="$ROOT_DIR/.claude/context/telemetry"
LOG_FILE="$TELEMETRY_DIR/debug-warnings.jsonl"

# Debug output patterns (from warn-debug-output.sh extended)
DEBUG_PATTERNS=(
    "console\.log\("
    "console\.debug\("
    "console\.warn\("
    "console\.error\("
    "console\.trace\("
    "print\("
    "println\("
    "fmt\.Print"
    "fmt\.Println"
    "fmt\.Printf"
    "System\.out\.print"
    "System\.err\.print"
    "debugger;"
    "binding\.pry"
    "byebug"
    "^\s*pp[\s(]"
    "pdb\.set_trace"
    "breakpoint\(\)"
    "NSLog\("
)

# Supported file extensions
FILE_EXTENSIONS="\.(ts|tsx|js|jsx|py|go|rb|rs|java|kt|kts|swift|cpp|c|cc|cxx|h|hpp)$"

# Get modified files (git-aware with fallback)
MODIFIED=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    # Git repository: use git diff
    MODIFIED=$(git diff --name-only HEAD 2>/dev/null || true)
    STAGED=$(git diff --cached --name-only 2>/dev/null || true)
    MODIFIED=$(printf '%s\n%s' "$MODIFIED" "$STAGED" | sort -u | grep -v '^$' || true)
else
    # Non-git: scan recently modified files (last 5 minutes)
    # Use absolute path for find
    MODIFIED=$(find "$ROOT_DIR" -type f -mmin -5 \( \
        -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
        -o -name "*.py" -o -name "*.go" -o -name "*.rb" -o -name "*.rs" \
        -o -name "*.java" -o -name "*.kt" -o -name "*.kts" -o -name "*.swift" \
        -o -name "*.cpp" -o -name "*.c" -o -name "*.cc" -o -name "*.cxx" \
        -o -name "*.h" -o -name "*.hpp" \
    \) 2>/dev/null | grep -E "$FILE_EXTENSIONS" || true)
fi

if [ -z "$MODIFIED" ]; then
    # No files to scan
    exit 0
fi

# Scan each file for debug patterns
mkdir -p "$TELEMETRY_DIR"
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

TOTAL_WARNINGS=0
while IFS= read -r file; do
    [ -z "$file" ] && continue
    [ ! -f "$file" ] && continue

    FOUND_PATTERNS=()
    LINE_COUNT=0

    for pattern in "${DEBUG_PATTERNS[@]}"; do
        if matches=$(grep -E "$pattern" "$file" 2>/dev/null); then
            FOUND_PATTERNS+=("$pattern")
            count=$(echo "$matches" | wc -l | tr -d ' ')
            LINE_COUNT=$((LINE_COUNT + count))
        fi
    done

    if [ ${#FOUND_PATTERNS[@]} -gt 0 ]; then
        # Log to JSONL
        # Try Python first, fallback to bash if unavailable
        patterns_json=$(printf '%s\n' "${FOUND_PATTERNS[@]}" | python3 -c "
import sys, json
patterns = [line.strip() for line in sys.stdin if line.strip()]
print(json.dumps(patterns))
" 2>/dev/null)

        # Fallback to bash JSON encoding if Python failed
        if [ -z "$patterns_json" ]; then
            # Escape quotes and build JSON array manually
            patterns_json="["
            first=true
            for pattern in "${FOUND_PATTERNS[@]}"; do
                escaped=$(echo "$pattern" | sed 's/"/\\"/g')
                if [ "$first" = true ]; then
                    patterns_json+="\"$escaped\""
                    first=false
                else
                    patterns_json+=",\"$escaped\""
                fi
            done
            patterns_json+="]"
        fi

        printf '{"ts":"%s","file":"%s","patterns":%s,"line_count":%d,"source":"stop-hook"}\n' \
            "$TS" \
            "$file" \
            "$patterns_json" \
            "$LINE_COUNT" \
            >> "$LOG_FILE"

        TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))

        # Also emit warning to stderr
        echo "WARNING: Debug output in $file — ${FOUND_PATTERNS[*]}" >&2
    fi
done <<< "$MODIFIED"

if [ $TOTAL_WARNINGS -gt 0 ]; then
    echo "" >&2
    echo "[$TOTAL_WARNINGS file(s) with debug output detected]" >&2
    echo "Review and remove before committing." >&2
    echo "Details: .claude/context/telemetry/debug-warnings.jsonl" >&2
fi

exit 0
