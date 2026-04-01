---
name: checkpoint-cowork
description: Cowork-compatible decision checkpoint — PIVOT, REFINE, or PROCEED (single-file variant)
version: 0.1.0
level: 1
triggers:
  - "checkpoint"
  - "check in"
  - "decision point"
platform: cowork
---

# Checkpoint (Cowork)

A structured pause during long-running tasks.

## Output

```
Checkpoint — [task] — Step [N]

Completed: [list]
In Progress: [current]
Blocked / New info: [if any]

Decision: PROCEED / REFINE / PIVOT
Rationale: [one sentence]
Next: [specific action]
```

## The Three Decisions

**PROCEED** — on track, continue.

**REFINE** — adjust 1-2 steps, then continue. Document what changed.

**PIVOT** — current approach is wrong or blocked. Stop, re-plan, note the abandoned approach so it is not retried.

## When to Call This

- Every 5 sequential steps (required)
- When a blocker appears
- When new information changes an assumption
- When the task has been running long without a pause
