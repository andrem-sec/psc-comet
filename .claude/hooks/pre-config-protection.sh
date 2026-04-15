#!/usr/bin/env bash
# PreToolUse: Write, Edit
# Blocks modifications to linter and formatter configuration files.
# Prevents accidental weakening of code quality standards.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Protected config file patterns (43 patterns total)
CONFIG_PATTERNS=(
    "\.eslintrc$"
    "\.eslintrc\.json$"
    "\.eslintrc\.js$"
    "\.eslintrc\.cjs$"
    "\.eslintrc\.yaml$"
    "\.eslintrc\.yml$"
    "eslint\.config\.js$"
    "eslint\.config\.mjs$"
    "eslint\.config\.cjs$"
    "\.prettierrc$"
    "\.prettierrc\.json$"
    "\.prettierrc\.js$"
    "\.prettierrc\.cjs$"
    "\.prettierrc\.yaml$"
    "\.prettierrc\.yml$"
    "\.prettierrc\.toml$"
    "prettier\.config\.js$"
    "prettier\.config\.cjs$"
    "biome\.json$"
    "biome\.jsonc$"
    "\.ruff\.toml$"
    "ruff\.toml$"
    "\.shellcheckrc$"
    "\.pylintrc$"
    "pylintrc$"
    "\.flake8$"
    "\.mypy\.ini$"
    "mypy\.ini$"
    "tslint\.json$"
    "\.stylelintrc$"
    "\.stylelintrc\.json$"
    "\.rubocop\.yml$"
    "\.golangci\.yml$"
    "\.golangci\.yaml$"
    "clippy\.toml$"
    "\.clippy\.toml$"
)

# Exception: pyproject.toml allowed (contains dependencies, not just lint config)
if echo "$FILE_PATH" | grep -qE "pyproject\.toml$"; then
    exit 0
fi

# Check against patterns
for pattern in "${CONFIG_PATTERNS[@]}"; do
    if echo "$FILE_PATH" | grep -qE "$pattern"; then
        echo "BLOCKED: Writing to '$FILE_PATH' — protected linter/formatter config." >&2
        echo "These configs enforce code quality standards." >&2
        echo "Modify manually or update config-protection hook if intentional." >&2
        exit 2
    fi
done

exit 0
