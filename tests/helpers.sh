#!/usr/bin/env bash
# tests/helpers.sh -- shared test utilities for PSC test scripts

PASS_COUNT=0
FAIL_COUNT=0

assert_exit() {
    local expected=$1 actual=$2 label=$3
    if [ "$actual" -eq "$expected" ]; then
        echo "PASS: $label"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "FAIL: $label (expected exit $expected, got $actual)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

assert_output_contains() {
    local needle="$1" output="$2" label="$3"
    if echo "$output" | grep -q "$needle"; then
        echo "PASS: $label"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "FAIL: $label (expected '$needle' in output)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

test_summary() {
    echo ""
    echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
    [ $FAIL_COUNT -eq 0 ] && return 0 || return 1
}

# Build a minimal but valid PSC structure in the given directory.
# Satisfies all 7 floor checks in psc-health-check.sh.
make_minimal_psc() {
    local root="$1"
    mkdir -p \
        "$root/.claude/agents" \
        "$root/.claude/hooks" \
        "$root/.claude/skills/core/heartbeat" \
        "$root/.claude/skills/workflow/wrap-up"

    # CLAUDE.md: under 200 lines, with valid Skill and Agent Registry tables
    cat > "$root/.claude/CLAUDE.md" << 'EOF'
# Test PSC

## Skill Registry

| Skill | Level | Trigger |
|-------|-------|---------|
| heartbeat | 1 | session start |
| wrap-up | 1 | session end |

## Agent Registry

| Agent | Constraint | Role |
|-------|-----------|------|
| researcher | read-only | research |
EOF

    # settings.json: valid JSON, references one hook
    cat > "$root/.claude/settings.json" << 'EOF'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/test-hook.sh",
            "description": "test hook"
          }
        ]
      }
    ]
  }
}
EOF

    # Hook file
    printf '#!/usr/bin/env bash\n' > "$root/.claude/hooks/test-hook.sh"

    # Agent file with required frontmatter
    cat > "$root/.claude/agents/researcher.md" << 'EOF'
---
name: researcher
description: Research and synthesis
tools: Read, Grep, Glob
---
EOF

    # core SKILL.md with required frontmatter
    cat > "$root/.claude/skills/core/heartbeat/SKILL.md" << 'EOF'
---
name: heartbeat
description: Session start check
version: 0.1.0
level: 1
triggers:
  - session start
---
EOF

    # workflow SKILL.md with required frontmatter
    cat > "$root/.claude/skills/workflow/wrap-up/SKILL.md" << 'EOF'
---
name: wrap-up
description: Session end wrap
version: 0.1.0
level: 1
triggers:
  - session end
---
EOF
}
