---
name: loop-operator
description: Autonomous loop management with safety defaults and escalation gates
version: 0.1.0
level: 2
triggers:
  - "/loop-start"
  - "/loop-status"
  - "autonomous loop"
  - "continuous operation"
context_files:
  - context/project.md
  - context/learnings.md
steps:
  - name: Define Loop Task
    description: Specify operation, success criteria, and max iterations
  - name: Set Safety Mode
    description: Configure safety-guard mode (Careful/Freeze/Guard)
  - name: Start Loop
    description: Initiate autonomous operation with monitoring
  - name: Monitor Progress
    description: Track iterations, success rate, and errors
  - name: Escalation Check
    description: Evaluate if human intervention needed
  - name: Report Status
    description: Provide loop metrics and completion status
---

# Loop Operator Skill

Autonomous loop management for repetitive tasks with built-in safety guardrails and automatic escalation.

## What Claude Gets Wrong Without This Skill

Without loop operator, autonomous tasks:
1. Run without safety constraints (no automatic stop on errors)
2. Have no progress visibility (can't tell if stuck or progressing)
3. Continue indefinitely on failure (no escalation to human)
4. Lack success criteria (ambiguous completion)
5. Provide no audit trail (what happened during loop)

Loop operator adds structure, safety, and observability to autonomous operations.

## Loop Anatomy

**Loop Definition:**
- **Task:** Operation to repeat (e.g., "process files in queue", "run tests until green")
- **Success Criteria:** When to stop (e.g., "queue empty", "all tests pass")
- **Max Iterations:** Hard limit (default: 10, prevents infinite loops)
- **Safety Mode:** Careful (warn), Freeze (lock paths), or Guard (both)

**Example:**
```yaml
task: Fix all TypeScript errors in src/
success_criteria: tsc --noEmit returns 0 errors
max_iterations: 5
safety_mode: Careful
```

## Three Safety Modes

### Careful Mode
**Use When:** Standard development tasks, low risk of data loss.

**Behavior:** Warns on destructive commands, allows with confirmation.

**Example:** Refactoring code, running tests, generating reports.

### Freeze Mode
**Use When:** Operations near sensitive paths (/etc/, ~/.ssh/, credentials).

**Behavior:** Blocks writes to frozen paths entirely.

**Paths:** Configured via FREEZE_PATHS env var.

**Example:** Database migrations, configuration updates, system-level changes.

### Guard Mode (Careful + Freeze)
**Use When:** Fully autonomous operations, docker-sandbox, permissionMode: dontAsk.

**Behavior:** Warns on destructive ops AND locks sensitive paths.

**Example:** Security scans, autonomous agent tasks, production deployments.

## Escalation Gates

**Trigger Conditions:**
1. **Identical Failures:** Same error 3 times consecutively
2. **Progress Stall:** No change in success metric for 3 iterations
3. **Max Iterations:** Hard limit reached without success
4. **Manual Interrupt:** User sends Stop signal

**Escalation Actions:**
- Log loop state to ~/.claude/loop-operator.log
- Surface error summary with context
- Ask user: RETRY (with new strategy), ABORT, or DEBUG

**Example:**
```
Loop: Fix TypeScript errors (iteration 3/5)
Error: Cannot find module 'foo'
Escalation: Identical error in iterations 1, 2, 3
Action: Stopping loop, awaiting user input
```

## Two Commands

### /loop-start

**Purpose:** Initiate autonomous loop with monitoring.

**Usage:**
```
/loop-start
Task: Fix all linter errors
Success: npm run lint exits 0
Max Iterations: 5
Safety Mode: Careful
```

**Process:**
1. Parse task definition
2. Enable safety-guard with specified mode
3. Start loop with iteration counter
4. Run task, check success criteria
5. Log iteration result
6. Escalate or continue

**Output:** Real-time iteration updates with success/failure status.

### /loop-status

**Purpose:** Check currently running loops.

**Output:**
- Loop ID
- Task description
- Current iteration / max
- Success rate (successful iterations / total)
- Time elapsed
- Status: Running, Paused, Escalated, Complete

**Example:**
```
Loop #1: Fix linter errors
Iteration: 3/5
Success Rate: 33% (1/3)
Elapsed: 2m 15s
Status: Running
Last Action: Fixed 5 errors in src/auth.ts
```

## Integration with Safety-Guard

Loop operator activates safety-guard automatically based on safety_mode parameter:

```bash
# Before loop starts
export SAFETY_GUARD_MODE=careful
export FREEZE_PATHS="/etc/,~/.ssh/"

# Run loop
/loop-start ...

# After loop ends
unset SAFETY_GUARD_MODE
unset FREEZE_PATHS
```

Safety-guard hooks intercept tool calls during loop, applying protections transparently.

## Integration with Docker-Sandbox

For isolated autonomous operations, loop operator can spawn docker-sandbox agent:

**Pattern:**
1. User runs `/loop-start` with `environment: docker-sandbox`
2. Loop operator spawns docker-sandbox agent with ROE permissions
3. Agent operates in isolated worktree, no access to host filesystem
4. Loop operator monitors agent output, applies escalation gates
5. On completion or escalation, loop operator reports results

**Safety:** Docker-sandbox prevents host filesystem access, network restrictions optional.

## Anti-Patterns

**No success criteria:** Running loop with ambiguous completion condition ("make it better"). Define measurable criteria.

**Max iterations too high:** Setting max_iterations > 20. Indicates task decomposition needed (break into smaller loops).

**Ignoring escalations:** Clicking through 5 escalation warnings. Escalation means strategy failing - stop and rethink.

**No safety mode:** Running destructive loop without safety-guard. Always specify Careful minimum.

**Polling too frequently:** Loop iterations every second. Add iteration_delay to prevent resource exhaustion.

**No progress logging:** Looping without logging each iteration. Logs enable post-mortem analysis.

## State Management

**Location:** ~/.claude/loop-operator-state.json

**Fields:**
- `loop_id`: Unique identifier
- `task`: Task description
- `iterations`: Array of iteration results
- `start_time`: ISO timestamp
- `status`: Running, Paused, Escalated, Complete

**Persistence:** State saved after each iteration, survives session restart.

**Cleanup:** State files older than 7 days auto-deleted.

## Mandatory Checklist

1. Verify task and success criteria defined clearly
2. Verify max_iterations set (default 10, never exceed 20)
3. Verify safety_mode specified (Careful minimum, Guard for autonomous)
4. Verify escalation gates configured (3 identical failures, 3 stalled iterations)
5. Verify loop state persisted to ~/.claude/loop-operator-state.json
6. Verify /loop-status reports current iteration, success rate, elapsed time
7. Verify safety-guard integration (env vars set before loop, unset after)
8. Verify escalation prompts user for RETRY/ABORT/DEBUG decision
