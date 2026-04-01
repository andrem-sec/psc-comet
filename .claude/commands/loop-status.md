---
description: Check status of running autonomous loops
---

# Loop Status

Displays currently running or recent loops with iteration progress and success metrics.

## Usage

```
/loop-status
```

## Output

For each loop:
- Loop ID
- Task description
- Current iteration / max iterations
- Success rate (successful / total)
- Time elapsed
- Status: Running, Paused, Escalated, Complete
- Last action taken

## Example

```
Loop #1: Fix linter errors
Iteration: 3/5
Success Rate: 67% (2/3)
Elapsed: 1m 45s
Status: Running
Last Action: Fixed 3 errors in src/auth.ts
```

## State Persistence

Loop state saved to ~/.claude/loop-operator-state.json. Survives session restart.

## Implementation

Invoke loop-operator skill to read state file and format output.
