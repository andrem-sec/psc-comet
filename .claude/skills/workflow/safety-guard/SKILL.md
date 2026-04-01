---
name: safety-guard
description: Three-mode safety guardrail for autonomous operations with action logging
version: 0.1.0
level: 2
triggers:
  - "enable safety guard"
  - "careful mode"
  - "freeze writes"
  - "autonomous safety"
context_files:
  - context/learnings.md
steps:
  - name: Mode Selection
    description: Choose Careful (warn), Freeze (lock), or Guard (both)
  - name: Hook Configuration
    description: Enable PreToolUse hooks for protected operations
  - name: Operation Monitoring
    description: Intercept and evaluate destructive commands
  - name: Action Logging
    description: Log blocked and warned actions to ~/.claude/safety-guard.log
  - name: User Notification
    description: Alert user when guard blocks or warns on operation
---

# Safety Guard Skill

Three-mode safety guardrail system for autonomous agent sessions. Prevents destructive operations and logs all interventions.

## What Claude Gets Wrong Without This Skill

Without safety guardrails, autonomous agents:
1. Execute destructive commands (rm -rf, DROP TABLE) without confirmation
2. Force push to protected branches, losing commit history
3. Run unrestricted operations in production environments
4. Bypass safety hooks (--no-verify flags) without justification
5. Provide no audit trail of potentially dangerous actions

Safety guard ensures autonomous operations remain safe and auditable.

## Three Modes

### Careful Mode (Warn)
**Behavior:** Warns on destructive commands but allows execution after user confirmation.

**Use When:** Standard development, trusted environments, human oversight available.

**Protected Operations:** rm -rf, git push --force, git reset --hard, DROP TABLE/DATABASE, docker system prune, kubectl delete, chmod 777, sudo rm, npm/cargo publish, --no-verify flags.

### Freeze Mode (Lock Writes)
**Behavior:** Blocks write operations to specific paths. Config: `FREEZE_PATHS="/etc/,~/.ssh/"`. Blocks Write, Edit, and Bash ops to frozen paths.

### Guard Mode (Careful + Freeze)
**Behavior:** Warns on destructive ops AND locks write paths. Use for: autonomous agents, docker-sandbox, permissionMode: dontAsk sessions.

## Hook Implementation Pattern

Safety guard extends existing hooks with additional checks.

**PreToolUse Bash Hook Enhancement:**

```bash
# Add to existing block-destructive.sh or create safety-guard-bash.sh
SAFETY_MODE="${SAFETY_GUARD_MODE:-off}"  # off | careful | freeze | guard
LOG_FILE="${HOME}/.claude/safety-guard.log"

if [ "$SAFETY_MODE" = "off" ]; then
  exit 0  # Safety guard disabled
fi

COMMAND="$1"  # Tool input from stdin

# Careful mode: destructive operation detection
if [[ "$SAFETY_MODE" =~ (careful|guard) ]]; then
  if echo "$COMMAND" | grep -qE "rm\s+-rf|git push.*--force|git reset --hard|DROP (TABLE|DATABASE)|docker system prune|kubectl delete|chmod 777|sudo rm|--no-verify"; then
    echo "$(date -Iseconds) WARN: $COMMAND" >> "$LOG_FILE"
    echo "⚠️  SAFETY GUARD: Destructive operation detected"
    echo "Command: $COMMAND"
    echo "Continue? (y/N):"
    # Exit 1 to prompt user, or exit 0 if user confirms
  fi
fi

# Freeze mode: write path locking
if [[ "$SAFETY_MODE" =~ (freeze|guard) ]]; then
  FREEZE_PATHS="${FREEZE_PATHS:-}"
  if [ -n "$FREEZE_PATHS" ]; then
    # Check if command affects frozen paths
    # Implementation depends on command parser
  fi
fi
```

**PreToolUse Write/Edit Hook Enhancement:**

```bash
# Check if write target matches frozen paths
SAFETY_MODE="${SAFETY_GUARD_MODE:-off}"
TARGET_FILE="$1"

if [[ "$SAFETY_MODE" =~ (freeze|guard) ]]; then
  FREEZE_PATHS="${FREEZE_PATHS:-}"
  for frozen_path in ${FREEZE_PATHS//,/ }; do
    if [[ "$TARGET_FILE" == "$frozen_path"* ]]; then
      echo "$(date -Iseconds) BLOCK: Write to $TARGET_FILE (frozen path)" >> ~/.claude/safety-guard.log
      echo "❌ SAFETY GUARD: Write blocked"
      echo "Path: $TARGET_FILE is frozen"
      exit 2  # Block operation
    fi
  done
fi
```

## Action Logging

All interventions logged to `~/.claude/safety-guard.log` with ISO timestamp, action (WARN/BLOCK), command, reason, outcome. Rotate at session start if >10KB.

## Mode Activation

Via env vars: `SAFETY_GUARD_MODE=guard` and `FREEZE_PATHS="/etc/,~/.ssh/"`. Or in agent frontmatter. Unset to disable.

## Integration with Existing Hooks

**Complements:**
- block-destructive.sh: Safety guard extends this with logging and mode flexibility
- block-secrets-write.sh: Freeze mode adds pattern-based path protection

**Does NOT replace:**
- Existing hooks remain active
- Safety guard adds layer of user-controlled protection
- Hook order: existing blocks first, then safety guard warnings

## Anti-Patterns

**Always-on Guard mode**: Guard mode for routine development slows workflow. Use Careful mode for normal work.

**Freezing entire project**: Freeze mode for / blocks all writes. Be specific with frozen paths.

**Ignoring warnings repeatedly**: If you're clicking through 10 safety warnings, the guard is misconfigured for your task.

**No log review**: Safety log accumulates warnings. Review monthly to identify risky patterns.

## Mandatory Checklist

1. Verify mode selected matches risk profile (Careful for dev, Guard for autonomous)
2. Verify if Freeze or Guard: FREEZE_PATHS specified and tested
3. Verify hook implementation added to PreToolUse: Bash, Write, Edit
4. Verify log file location created at ~/.claude/safety-guard.log
5. Verify warning format includes command, risk, and mode
6. Verify blocked operations exit with code 2 (block)
7. Verify environment variables documented in activation instructions
