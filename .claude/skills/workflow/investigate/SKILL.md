---
name: investigate
description: Systematic root-cause debugging — no fixes before root cause is confirmed
version: 0.1.0
level: 3
triggers:
  - "investigate"
  - "root cause"
  - "find out why"
  - "dig into this bug"
  - "/investigate"
context_files:
  - context/project.md
  - context/learnings.md
steps:
  - name: Gather
    description: Read affected code, check recent git log, reproduce the bug deterministically, state the symptom precisely
  - name: Analyze
    description: Match against known bug patterns — race condition, nil propagation, state corruption, integration failure, config drift, stale cache
  - name: Hypothesize
    description: Rank by likelihood, confirm each with evidence; circuit-break after 3 failed hypotheses
  - name: Implement
    description: Fix only the confirmed root cause, minimize diff, write a regression test
  - name: Verify
    description: Reproduce original scenario, run full test suite, report with status verdict
---

# Investigate Skill

A structured five-phase root-cause debugging protocol. No fix is applied until the root cause is confirmed with evidence. Think of it as a controlled demolition: you do not swing the wrecking ball until you know exactly which wall to hit.

## What Claude Gets Wrong Without This Skill

Without a structured protocol, debugging becomes symptom-chasing. A timeout gets wrapped in a retry loop. A nil pointer gets a nil check. The behavior stops manifesting, but the cause is still there, waiting for the next context to trigger it.

The other failure mode is hypothesis overload: generating six possible causes, trying one, giving up, trying another, losing track of what was tested. Three failed hypotheses with no circuit breaker become ten, and ten become a refactor of the wrong system.

This skill enforces gather-before-hypothesize, evidence-before-fix, and a hard stop after three failures.

## Phase 1: Gather

Before forming any hypothesis:

1. Read the affected code
2. Run `git log -10 --oneline` to surface recent changes in the area
3. Reproduce the bug deterministically: if you cannot reproduce it, you cannot verify the fix
4. State the symptom precisely in one sentence: what happens, where, under what conditions

Do not move to Phase 2 until you can reproduce the bug or have a documented reason why reproduction is not possible.

## Phase 2: Analyze

Map the symptom against known bug pattern categories. List every candidate, do not filter yet:

| Pattern | What to look for |
|---------|-----------------|
| Race condition | Concurrent access to shared state, missing locks, async ordering assumptions |
| Nil/null propagation | Value expected to exist, flows through multiple layers before crash |
| State corruption | Object modified by multiple code paths, invariants violated |
| Integration failure | External service behavior changed, API contract drift, timeout assumptions |
| Configuration drift | Works in one environment, fails in another; env vars, feature flags |
| Stale cache | Cached value no longer valid, cache invalidation missing or incorrect |

## Phase 3: Hypothesize

Rank the candidates from Phase 2 by likelihood. For each, state what evidence would confirm or refute it: a failing test, a specific log line, a traced execution path.

Test them in order. For each:
- State the hypothesis
- State what evidence you expect to find
- Find it or refute it

**Circuit breaker:** If three hypotheses fail, stop. Do not continue guessing. The root cause is deeper than the initial analysis reached. Options at this point:
- Question the architecture, not the implementation
- Ask the user for information you do not have
- Report status as BLOCKED with the three failed hypotheses documented

## Ownership Mode

Before Phase 3, run:
```bash
git shortlog -sn --since="90 days ago" --no-merges HEAD | head -5
```

If the top author has 80% or more of commits: **solo mode**: investigate issues discovered outside the current task scope and offer to fix them.

If below 80%: **collaborative mode**: flag out-of-scope issues via AskUserQuestion and move on. Do not fix them unilaterally.

## Phase 4: Implement

Only after the root cause is confirmed with evidence:

- Fix only the confirmed root cause: do not bundle unrelated improvements
- Minimize the diff; a small precise fix is easier to review and revert than a broad one
- Write a regression test that fails without the fix and passes with it
- If the fix touches more than 5 files, stop and confirm with the user before proceeding

## Phase 5: Verify

1. Reproduce the original scenario with the fix applied: it must not reproduce
2. Run the full test suite
3. Paste evidence

Report:
```
Symptom: [what the user observed]
Root cause: [file:line: what was actually wrong]
Fix: [what changed and why]
Regression test: [test name and result]
Status: DONE | DONE_WITH_CONCERNS | BLOCKED
```

DONE_WITH_CONCERNS: fix is applied but something warrants follow-up (e.g., related fragility found, test coverage gaps).
BLOCKED: root cause not confirmed; three hypotheses exhausted; escalation required.

## Anti-Patterns

Do not form hypotheses before reproducing the bug. A hypothesis about an unreproducible bug is speculation, not investigation.

Do not fix the symptom. A nil check on a value that should never be nil masks the real failure. Find out why it is nil.

Do not continue past three failed hypotheses. More guessing from a bad prior compounds the error. Stop and reframe.

Do not expand the fix scope. Once the root cause is confirmed, the fix should be surgical. "While I'm in here" additions belong in a separate task.

## Mandatory Checklist

1. Verify the bug was reproduced deterministically before any hypothesis was formed
2. Verify the symptom was stated precisely in one sentence
3. Verify candidate patterns were listed before ranking
4. Verify each hypothesis was tested against actual evidence, not assumed
5. Verify the circuit breaker triggered after three failures (if applicable)
6. Verify the fix addresses only the confirmed root cause
7. Verify a regression test was written that fails without the fix
8. Verify the full test suite passed after the fix was applied
