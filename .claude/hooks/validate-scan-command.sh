#!/usr/bin/env bash
# PreToolUse: Bash (docker-sandbox agent only)
# Validates Bash commands in the docker-sandbox context.
# Blocks destructive operations and data exfiltration attempts.
# Allows security scanning tools and read operations.

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$CMD" ]; then
    exit 0
fi

# --- Block: Destructive filesystem operations ---
DESTRUCTIVE_PATTERNS=(
    "rm -rf"
    "rm -r /"
    "dd if="
    "mkfs"
    "shred"
    "> /dev/"
    "chmod -R 777 /"
    "chown -R"
)

for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
    if echo "$CMD" | grep -qi "$pattern"; then
        echo "BLOCKED: Destructive operation '$pattern' is not permitted in docker-sandbox." >&2
        exit 2
    fi
done

# --- Block: Git write operations (no commits or pushes from sandbox) ---
GIT_WRITE_PATTERNS=(
    "git push"
    "git commit"
    "git rebase"
    "git reset --hard"
    "git clean -f"
    "git tag"
    "git merge"
)

for pattern in "${GIT_WRITE_PATTERNS[@]}"; do
    if echo "$CMD" | grep -qi "$pattern"; then
        echo "BLOCKED: Git write operation '$pattern' is not permitted in docker-sandbox." >&2
        echo "Sandbox agents may read git history but must not modify it." >&2
        exit 2
    fi
done

# --- Block: Outbound data exfiltration ---
EXFIL_PATTERNS=(
    "curl.*-d"
    "curl.*--data"
    "curl.*--upload"
    "wget.*--post"
    "nc -e"
    "bash -i"
    "python.*-c.*socket"
)

for pattern in "${EXFIL_PATTERNS[@]}"; do
    if echo "$CMD" | grep -qiP "$pattern" 2>/dev/null || echo "$CMD" | grep -qi "$pattern"; then
        echo "BLOCKED: Potential data exfiltration pattern detected: '$pattern'" >&2
        echo "Use read-only curl/wget for fetching content only." >&2
        exit 2
    fi
done

# --- Block: Package installation outside scanning tools ---
INSTALL_BLOCK_PATTERNS=(
    "apt-get install"
    "apt install"
    "pip install"
    "npm install -g"
    "gem install"
    "curl.*sh | bash"
    "curl.*sh | sh"
    "wget.*sh | bash"
)

for pattern in "${INSTALL_BLOCK_PATTERNS[@]}"; do
    if echo "$CMD" | grep -qi "$pattern"; then
        echo "BLOCKED: Package installation '$pattern' is not permitted in docker-sandbox." >&2
        echo "Only pre-installed scanning tools are available." >&2
        exit 2
    fi
done

exit 0
