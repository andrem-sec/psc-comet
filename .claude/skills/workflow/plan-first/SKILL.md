---
name: plan-first
description: Plan-mode enforcement — required before edits affecting 3+ files, cross-domain work, or security-sensitive changes
version: 0.2.0
level: 2
triggers:
  - "plan"
  - "plan mode"
  - "plan first"
  - "let's plan"
  - "/plan"
context_files:
  - context/user.md
  - context/principles.md
steps:
  - name: Scope Assessment
    description: Count files, identify domains, flag security sensitivity. If editing a skill file, grep for its name across other skills to identify downstream dependents — list them in the plan so their behavior can be verified after the change.
  - name: Plan Mode Decision
    description: If 3+ files, cross-domain, or security-sensitive — enter plan mode. State the decision explicitly.
  - name: Decompose
    description: Break into ordered steps. Before writing each step, assess whether it carries hidden complexity not visible during scope scan. If yes, reason through it before writing the step. Max 5 sequential before a checkpoint.
  - name: Identify Risks
    description: Flag irreversible operations, external calls, schema changes — each needs explicit confirmation
  - name: Parallel Opportunities
    description: Mark steps with no dependencies as parallel. Parallelizable steps do not count toward the 5-step limit.
  - name: Confirm
    description: Present the plan. Wait for explicit user approval. Do not begin editing until confirmed.
---

# Plan-First Skill

Enforce plan-mode discipline before implementation.

## What Claude Gets Wrong Without This Skill

Without plan-first, Claude begins editing immediately on complex tasks. Mid-task, it discovers dependencies it did not account for, requiring backtracking. On security-sensitive tasks, it makes changes whose scope only becomes visible after the fact. The cost of planning is always lower than the cost of unwinding a wrong approach.

## When Plan Mode Is Required

| Condition | Plan Mode |
|-----------|-----------|
| 1-2 files, single domain | Optional |
| 3+ files | Required |
| Cross-domain | Required |
| Security-sensitive | Required |
| Schema / database changes | Required |
| Irreversible operations | Required |

## Plan Format

```
## Plan: [task name]

### Scope
Files affected: [N] — [list]
Domains: [list]
Risk: LOW / MEDIUM / HIGH

### Steps
1. [action] — [file(s)]
2. [action] — [file(s)]
   → Parallel: [action] — [file(s)]
3. [action] — [file(s)]
   ↳ Checkpoint: verify [X] before proceeding

### Risks
[Risk] at Step [N] — requires [confirmation / rollback plan]

### Confirmation
Proceed? (yes / modify / no)
```

## Checkpoint Rule

No more than 5 sequential steps without a verification checkpoint. At each:
- Run tests or build
- State expected outcome
- Decision: PIVOT / REFINE / PROCEED

Parallel steps that share no dependencies do not count toward the 5-step limit.

## Anti-Patterns

Do not begin editing before the user says yes. "I'll start with step 1 while you review" is not compliant.

Do not present a plan so vague it cannot be critiqued. "Refactor the service" is not a step.

Do not include parallel steps that actually share file dependencies — race conditions are real even in sequential Claude sessions.

## Mandatory Checklist

1. Verify file count was assessed before deciding on plan mode
2. Verify all 3 triggers were checked (files, domains, security)
3. Verify each step names specific files, not "the relevant files"
4. Verify parallel steps genuinely have no shared file dependencies
5. Verify a checkpoint appears after every 5 sequential steps
6. Verify the user explicitly confirmed before any editing began
