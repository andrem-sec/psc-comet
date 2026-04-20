#!/usr/bin/env bash
# psc-health-check.sh -- binary floor checks for PSC harness integrity
#
# Exit 0: all checks pass
# Exit 1: one or more floors failed
#
# Usage: bash scripts/psc-health-check.sh
#        PSC_ROOT=/path/to/repo bash scripts/psc-health-check.sh

set -euo pipefail

# Resolve PSC_ROOT from script location if not set
if [ -z "${PSC_ROOT:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PSC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

CLAUDE_DIR="$PSC_ROOT/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
AGENTS_DIR="$CLAUDE_DIR/agents"
SKILLS_DIR="$CLAUDE_DIR/skills"
HOOKS_DIR="$CLAUDE_DIR/hooks"

failed=0

fail() { echo "FAIL: $1"; failed=1; }
pass() { echo "PASS: $1"; }

# Detect available JSON validator (python3 preferred for CI, python/node fallback for Windows)
# python3/python check: verify it actually runs (Windows Store alias exists but is non-functional)
_py_works() { "$1" --version 2>&1 | grep -qE "^Python [0-9]+\.[0-9]+"; }
json_valid() {
    local file="$1"
    # Convert path for Windows-native tools (cygpath available in Git Bash)
    local native_path="$file"
    command -v cygpath > /dev/null 2>&1 && native_path=$(cygpath -m "$file")

    if command -v python3 > /dev/null 2>&1 && _py_works python3; then
        python3 -m json.tool "$file" > /dev/null 2>&1
    elif command -v python > /dev/null 2>&1 && _py_works python; then
        python -m json.tool "$file" > /dev/null 2>&1
    elif command -v node > /dev/null 2>&1; then
        node -e "JSON.parse(require('fs').readFileSync('$native_path','utf8'))" > /dev/null 2>&1
    else
        echo "SKIP: No JSON validator available (python3, python, or node required)"
        return 0
    fi
}

echo "PSC health check -- $PSC_ROOT"
echo ""

# Floor 1: CLAUDE.md exists and is under 200 lines
echo "Floor 1: CLAUDE.md line count"
if [ ! -f "$CLAUDE_MD" ]; then
    fail "CLAUDE.md not found at $CLAUDE_MD"
else
    lines=$(wc -l < "$CLAUDE_MD")
    if [ "$lines" -gt 200 ]; then
        fail "CLAUDE.md exceeds 200 lines ($lines/200)"
    else
        pass "CLAUDE.md present, $lines lines"
    fi
fi
echo ""

# Floor 2: settings.json exists and is valid JSON
echo "Floor 2: settings.json validity"
if [ ! -f "$SETTINGS" ]; then
    fail "settings.json not found at $SETTINGS"
else
    if json_valid "$SETTINGS"; then
        pass "settings.json is valid JSON"
    else
        fail "settings.json is not valid JSON"
    fi
fi
echo ""

# Floor 3: All hooks referenced in settings.json exist on disk
# Extract .sh basenames from "command" lines only (avoids matching .sh in description strings)
echo "Floor 3: Hook files on disk"
if [ -f "$SETTINGS" ]; then
    hook_names=$(grep '"command"' "$SETTINGS" | grep -o '[a-zA-Z0-9_-]*\.sh' | sort -u)
    if [ -z "$hook_names" ]; then
        pass "No hook .sh files referenced in settings.json"
    else
        hook_failures=0
        while IFS= read -r hook_name; do
            [ -z "$hook_name" ] && continue
            if [ ! -f "$HOOKS_DIR/$hook_name" ]; then
                fail "Hook '$hook_name' in settings.json not found at $HOOKS_DIR/$hook_name"
                hook_failures=1
            fi
        done <<< "$hook_names"
        if [ $hook_failures -eq 0 ]; then
            pass "All hook files referenced in settings.json exist on disk"
        fi
    fi
fi
echo ""

# Floor 4: All agents in registry have files
# Parses context/agents-registry.md (extracted from CLAUDE.md via B-14)
echo "Floor 4: Agent files"
AGENTS_REGISTRY="$CLAUDE_DIR/context/agents-registry.md"
if [ -f "$AGENTS_REGISTRY" ] && [ -d "$AGENTS_DIR" ]; then
    agent_names=$(awk -F'|' '/^\| [^-]/ && !/^\| Agent/ { gsub(/ /,"",$2); if ($2 != "") print $2 }' "$AGENTS_REGISTRY")
    agent_failures=0
    while IFS= read -r agent; do
        [ -z "$agent" ] && continue
        if [ ! -f "$AGENTS_DIR/$agent.md" ]; then
            fail "Agent '$agent' in registry has no file at $AGENTS_DIR/$agent.md"
            agent_failures=1
        fi
    done <<< "$agent_names"
    if [ $agent_failures -eq 0 ]; then
        pass "All registered agents have files on disk"
    fi
else
    [ ! -f "$AGENTS_REGISTRY" ] && fail "agents-registry.md missing at $AGENTS_REGISTRY"
    [ ! -d "$AGENTS_DIR" ] && fail "agents directory missing at $AGENTS_DIR"
fi
echo ""

# Floor 5: All skills in registry have directories
# Parses context/skills-registry.md (extracted from CLAUDE.md via B-14)
echo "Floor 5: Skill directories"
SKILLS_REGISTRY="$CLAUDE_DIR/context/skills-registry.md"
if [ -f "$SKILLS_REGISTRY" ] && [ -d "$SKILLS_DIR" ]; then
    skill_names=$(awk -F'|' '/^\| [^-]/ && !/^\| Skill/ { gsub(/ /,"",$2); if ($2 != "") print $2 }' "$SKILLS_REGISTRY")
    skill_failures=0
    while IFS= read -r skill; do
        [ -z "$skill" ] && continue
        if ! find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -type d -name "$skill" | grep -q .; then
            fail "Skill '$skill' in registry has no directory under $SKILLS_DIR"
            skill_failures=1
        fi
    done <<< "$skill_names"
    if [ $skill_failures -eq 0 ]; then
        pass "All registered skills have directories on disk"
    fi
else
    [ ! -f "$SKILLS_REGISTRY" ] && fail "skills-registry.md missing at $SKILLS_REGISTRY"
    [ ! -d "$SKILLS_DIR" ] && fail "skills directory missing at $SKILLS_DIR"
fi
echo ""

# Floor 6: No agent file missing required frontmatter
echo "Floor 6: Agent frontmatter"
if [ -d "$AGENTS_DIR" ]; then
    frontmatter_failures=0
    for f in "$AGENTS_DIR"/*.md; do
        [ -f "$f" ] || continue
        for field in name description tools; do
            if ! grep -q "^$field:" "$f"; then
                fail "$(basename "$f") missing '$field:' frontmatter"
                frontmatter_failures=1
            fi
        done
    done
    if [ $frontmatter_failures -eq 0 ]; then
        pass "All agent files have required frontmatter"
    fi
else
    fail "agents directory missing -- cannot check frontmatter"
fi
echo ""

# Floor 7: No core/ or workflow/ SKILL.md missing required frontmatter
# Scoped to PSC-maintained skill categories; ui/ and external repos use different standards
echo "Floor 7: Skill frontmatter (core/ and workflow/)"
if [ -d "$SKILLS_DIR" ]; then
    skill_frontmatter_failures=0
    while IFS= read -r f; do
        for field in name description version level triggers; do
            if ! grep -q "^$field:" "$f"; then
                fail "$f missing '$field:' frontmatter"
                skill_frontmatter_failures=1
            fi
        done
    done < <(find "$SKILLS_DIR/core" "$SKILLS_DIR/workflow" -name "SKILL.md" 2>/dev/null)
    if [ $skill_frontmatter_failures -eq 0 ]; then
        pass "All core/ and workflow/ SKILL.md files have required frontmatter"
    fi
else
    fail "skills directory missing -- cannot check frontmatter"
fi
echo ""

# Summary
if [ $failed -eq 1 ]; then
    echo "PSC health check FAILED -- fix all failures before merging."
    exit 1
else
    echo "PSC health check PASSED -- all floors cleared."
    exit 0
fi
