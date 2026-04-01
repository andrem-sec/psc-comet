---
name: fix-pipeline
description: Bug fix workflow — debug-session → tdd → refactor (optional) → code-review
version: 0.1.0
level: 2
triggers:
  - "fix pipeline"
  - "fix this bug"
  - "full fix workflow"
  - "/fix"
pipeline:
  - debug-session
  - tdd
  - code-review
context_files:
  - context/learnings.md
steps:
  - name: Intake
    description: State the symptom precisely. Not the cause — the observable symptom.
  - name: Diagnose (debug-session)
    description: Run debug-session until a hypothesis is confirmed. Gate before fixing.
  - name: Regression Test (tdd — Red phase only)
    description: Write a failing test that reproduces the confirmed bug. Confirm it fails for the right reason.
  - name: Fix (tdd — Green phase)
    description: Write the minimum fix to make the regression test pass. Do not fix anything else.
  - name: Refactor (optional)
    description: If the fix revealed code that should be cleaned up — run refactor as a separate pass. Gate first.
  - name: Review (code-review)
    description: Run code-review on the fix only. Scope is narrow — the bug fix, not the surrounding code.
  - name: Close
    description: Write the confirmed hypothesis and fix to context/learnings.md. Include what the early warning sign was.
---

# Fix Pipeline Skill

The complete workflow for resolving a bug — from symptom to confirmed fix, with a regression test that prevents recurrence.

## What This Skill Does

A bug fix has a specific shape: understand the root cause, prove it with a test, fix only that, verify nothing else broke. This pipeline enforces that shape. The most common failure modes — fixing the symptom, fixing the wrong thing, or fixing correctly but introducing a new bug — each have a specific gate that catches them.

## Stage Details

### Stage 1 — Intake

State the symptom precisely. One sentence. Observable behavior only.

Good: "POST /api/orders returns 500 when item quantity is 0, but only on the second sequential request."
Bad: "The orders endpoint is broken."

### Stage 2 — Diagnose

Run `debug-session`. Do not begin any fixes until a hypothesis is confirmed with evidence.

Gate format:
```
Hypothesis confirmed: [what is causing the bug]
Evidence: [specific file:line or test output]
Gate: Proceed to write regression test? (yes / no)
```

### Stage 3 — Regression Test

Write a failing test that directly exercises the confirmed bug. The test must:
- Reproduce the exact symptom from Stage 1
- Fail because the bug exists, not because of a missing import or test infrastructure issue
- Pass after the fix and only after the fix

Do not write a test that happens to catch the bug incidentally. Write a test that cannot pass until the specific root cause is resolved.

### Stage 4 — Fix

Write the minimum code change that makes the regression test pass. Not the cleanest fix. The minimum.

The fix should touch as few lines as possible. If the minimum fix requires touching 5+ files, the bug is architectural — escalate to `consensus-plan` before continuing.

After fixing: run the full test suite. Every existing test must still pass. If any test breaks, the fix introduced a regression — revert and reconsider.

### Stage 5 — Refactor (Optional)

Only if the fix revealed code that should be restructured. This is a separate pass — do not mix refactoring with fixing.

Gate: "The fix is complete. There is code I noticed that should be cleaned up. Refactor now? (yes / no / later)"

If yes: run `refactor` skill as a separate step with its own coverage gate and one-change rule.

### Stage 6 — Review

Run `code-review` scoped narrowly to the fix. Not the file. Not the module. The changed lines.

Ask the code-reviewer agent to focus on:
- Did the fix address the root cause or just the symptom?
- Could this fix cause the same bug under different input conditions?
- Is the regression test adequate to prevent recurrence?

### Stage 7 — Close

Write to `context/learnings.md`:

```
[date] mistake — [bug description]: root cause was [confirmed hypothesis]. Fixed by [what changed]. Regression test at [file:line]. Early warning sign: [what to look for].
```

This is high-value. Future sessions encountering a similar symptom can find the pattern in learnings.md before spending time on diagnosis.

## Anti-Patterns

Do not write the fix before the regression test. A fix without a test is a fix that will recur.

Do not fix "while you're in there" — scope is the regression test target and nothing else.

Do not close without writing the learnings.md entry. The close step is not administrative — it is the most durable artifact of the fix.

## Mandatory Checklist

1. Verify symptom was stated as observable behavior (not as hypothesis)
2. Verify debug-session confirmed a hypothesis with evidence before any fix was written
3. Verify regression test was written before the fix and confirmed to fail for the right reason
4. Verify full test suite passed after the fix (not just the regression test)
5. Verify no unrequested changes were made beyond the minimum fix
6. Verify code-review was scoped to the fix, not the surrounding code
7. Verify close step wrote to context/learnings.md with root cause, fix, and early warning
