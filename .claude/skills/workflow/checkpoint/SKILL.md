---
name: checkpoint
description: Named decision point for long-running tasks — PIVOT, REFINE, or PROCEED
version: 0.2.0
level: 1
triggers:
  - "checkpoint"
  - "check in"
  - "pivot or proceed"
  - "decision point"
  - "/checkpoint"
context_files:
  - context/learnings.md
steps:
  - name: State Assessment
    description: What is done, in progress, and blocked?
  - name: Goal Alignment
    description: Does the current path still lead to the original goal?
  - name: Risk Surface
    description: What new risks or unknowns have appeared since the last checkpoint?
  - name: Decision
    description: PIVOT, REFINE, or PROCEED — with explicit rationale
  - name: Log if PIVOT
    description: If pivoting, write the abandoned approach and reason to context/learnings.md
---

# Checkpoint Skill

A structured pause during long-running tasks. Prevents tunnel vision and catches drift before it compounds.

## What Claude Gets Wrong Without This Skill

Without checkpoints, Claude continues executing a plan past the point where new information has invalidated one of its assumptions. The compound reliability math is real: at a 10% error rate per step, 10 steps yields 35% success. A checkpoint at step 5 resets the accumulation.

## The Three Decisions

**PROCEED** — on track, no new risks, continue as planned.

**REFINE** — mostly correct, but one or two steps need adjustment. Document what changed and why, then continue.

**PIVOT** — the approach is fundamentally wrong or blocked. Stop. Re-plan the affected phase. Write the abandoned approach to learnings.md — this is high-value content.

A PIVOT is not a failure. A PIVOT without documentation is a failure.

## Checkpoint Output

```
Checkpoint — [task] — Step [N] of [N]

Completed: [list]
In Progress: [current step]
Blocked / New Info: [if any]

Decision: PROCEED / REFINE / PIVOT
Rationale: [one sentence]
Next: [specific next action]
```

## When Checkpoints Are Required

- After every 5 sequential steps (mandatory)
- When a blocker appears
- When new information invalidates an assumption
- When the task has been running for a long time without a natural pause
- **When context usage reaches 90%** (warning threshold — do not wait for 95%)

## Context Usage Thresholds

Claude Code compacts at 93% of effective context (window minus 20k overhead). PSC checkpoints fire earlier:

| Level | Action |
|---|---|
| ~90% | Run checkpoint immediately — surface state, decide PIVOT/REFINE/PROCEED |
| ~95% | Blocking threshold — new tool calls may fail. Compact now. |
| Mid-debug | Do NOT compact — stack traces and error traces are the tool |

Signals that context is at 90%+: earlier parts of the conversation feel distant, rules from CLAUDE.md feel less active, you are uncertain about a constraint stated early in the session.

When in doubt, checkpoint. The cost of a false positive is one checkpoint. The cost of a missed threshold is silent context drift.

## Anti-Patterns

Do not issue a PROCEED when there are unresolved blockers. Acknowledge them and decide.

Do not PIVOT without writing the abandoned approach to learnings.md. Future sessions will revisit the same dead end without that record.

## Mandatory Checklist

1. Verify completed steps are listed accurately (not optimistically)
2. Verify any new information since the last checkpoint was surfaced
3. Verify the decision (PIVOT/REFINE/PROCEED) has an explicit rationale
4. Verify a PIVOT writes the abandoned approach to context/learnings.md
5. Verify the next action is specific, not "continue with the plan"
