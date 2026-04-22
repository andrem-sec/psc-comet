---
name: feature-pipeline
description: Full feature workflow — deep-interview → prd → consensus-plan → tdd → code-review → security-gate
version: 0.1.0
level: 3
triggers:
  - "new feature"
  - "feature pipeline"
  - "full workflow"
  - "/feature"
pipeline:
  - deep-interview
  - prd
  - consensus-plan
  - tdd
  - code-review
  - security-gate
context_files:
  - context/user.md
  - context/project.md
steps:
  - name: Intake
    description: Capture the feature request in one sentence. Assess complexity to determine which stages to run.
  - name: Explore (deep-interview)
    description: Run deep-interview until ambiguity ≤ 20%. Gate before proceeding.
  - name: Specify (prd)
    description: Run prd with interview findings as context. Confirm acceptance criteria. Gate before proceeding.
  - name: Plan (consensus-plan or plan-first)
    description: Complex or high-risk features → consensus-plan. Simple features → plan-first. Gate before proceeding.
  - name: Implement (tdd)
    description: Run tdd. Test first. Minimum Green. Then refactor. Checkpoint every 5 steps. Before opening the gate, run the test suite and report results as evidence — pass count, fail count, any failures. Do not open the gate on assertion alone.
  - name: Review (code-review)
    description: Run code-review on all changed files. Resolve REQUEST CHANGES before proceeding.
  - name: Security (security-gate)
    description: Run security-gate. Resolve any FAIL or CONDITIONAL PASS issues before declaring done.
  - name: Close
    description: Run wrap-up to commit learnings, update decisions.md status, and write session summary.
---

# Feature Pipeline Skill

The complete workflow for building a new feature — from unclear idea to reviewed, secure, committed code.

## What This Skill Does

Orchestrates the full sequence of skills required to take a feature from "we should do X" to "X is done and verified." Each stage gates on the previous one. No stage can be skipped without explicit acknowledgment.

## Stage Selection

Not every feature needs every stage at full depth. Assess on intake:

| Feature Type | Explore | Specify | Plan | Implement | Review | Security |
|-------------|---------|---------|------|-----------|--------|---------|
| Small, clear | skip | prd (light) | plan-first | tdd | code-review | gate |
| Medium, some unknowns | deep-interview | prd | plan-first | tdd | code-review | gate |
| Large, complex | deep-interview | prd | consensus-plan | tdd | code-review | gate |
| Security-sensitive | deep-interview | prd | consensus-plan | tdd | code-review + security-reviewer | gate |

State which stages will run and why before starting.

## Gate Protocol

Every stage ends with a gate. The gate is explicit user confirmation before the next stage begins.

Gate format:
```
[Stage name] complete.
Output: [one-line summary of what was produced]
Gate: Proceed to [next stage]? (yes / modify / stop)
```

Do not proceed without "yes" or equivalent. "Looks good" is yes. Silence is not.

## Checkpoint Rule

During the Implement stage: checkpoint every 5 sequential steps. The pipeline does not override the 5-step checkpoint rule.

## State Persistence

At every gate boundary, write a state entry to `context/learnings.md`:
```
[date] state — Task: [feature name] | Step: [current stage] | Done: [completed stages] | Next: [next stage]
```

This enables `resume` to pick up if the pipeline is interrupted.

## Handoff Between Stages

Each stage produces an artifact that the next stage consumes:

| Stage | Produces | Next stage consumes |
|-------|---------|-------------------|
| deep-interview | Understood problem (interview summary) | prd uses findings as context |
| prd | Confirmed acceptance criteria | plan references criteria by number |
| consensus-plan / plan-first | Approved plan | tdd implements plan steps in order |
| tdd | Passing tests + implementation + test run evidence (pass/fail counts) | code-review scopes to changed files |
| code-review | APPROVE verdict | security-gate scopes to same files |
| security-gate | PASS verdict | wrap-up closes out |

## Anti-Patterns

Do not start implementation before the PRD is confirmed. The most common cause of rework.

Do not run code-review and security-gate in the same session that wrote the code. Spawn isolated agents.

Do not skip the close step. Learnings from a completed feature are high-value for future features.

## Mandatory Checklist

1. Verify stage selection was stated and justified before starting
2. Verify each stage produced its expected artifact before the gate was opened
3. Verify state was written to learnings.md at every gate boundary
4. Verify no stage was skipped without explicit acknowledgment
5. Verify code-review and security-gate used isolated agents
6. Verify wrap-up was run at close
