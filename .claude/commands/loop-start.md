---
description: Start autonomous loop with safety guardrails
---

# Start Autonomous Loop

Initiates monitored loop for repetitive tasks with automatic escalation on failure.

## Usage

```
/loop-start
Task: Fix all TypeScript errors
Success: tsc --noEmit returns 0 errors
Max Iterations: 5
Safety Mode: Careful
```

## Parameters

- **Task:** Operation to repeat (specific, measurable)
- **Success Criteria:** When to stop (programmatically checkable)
- **Max Iterations:** Hard limit (default 10, max 20)
- **Safety Mode:** Careful (warn), Freeze (lock paths), Guard (both)

## Escalation

Loop stops and prompts user if:
- Same error 3 times consecutively
- No progress for 3 iterations
- Max iterations reached
- User interrupts (Ctrl+C)

## Safety Integration

Automatically enables safety-guard with specified mode. Protections apply to all tool calls during loop.

## Implementation

Invoke loop-operator skill to handle loop execution, monitoring, and escalation logic.
