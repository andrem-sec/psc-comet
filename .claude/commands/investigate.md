---
name: investigate
description: Systematic root-cause debugging — no fixes before root cause is confirmed
---

Invoke the investigate protocol now. Do not apply any fix until the root cause is confirmed.

## Phase 1 — Gather

Read the affected code. Check recent changes via `git log -10 --oneline`. Reproduce the bug deterministically before forming any hypothesis. State the symptom precisely.

## Phase 2 — Analyze

Match the bug against known patterns: race condition, nil propagation, state corruption, integration failure, configuration drift, stale cache. List every candidate.

## Phase 3 — Hypothesize

Rank hypotheses by likelihood. Confirm each with evidence — a failing test, a log line, a traced execution path. If three hypotheses fail, stop. Do not continue guessing. Escalate: question the architecture, ask the user, or flag as BLOCKED.

## Phase 4 — Implement

Fix only the confirmed root cause. Minimize the diff. Write a regression test that fails without the fix. If the fix touches more than 5 files, stop and confirm with the user before proceeding.

## Phase 5 — Verify

Reproduce the original scenario. Run the full test suite. Paste evidence. Report:

```
Symptom: [what the user observed]
Root cause: [file:line — what was actually wrong]
Fix: [what changed and why]
Regression test: [test name and result]
Status: DONE | DONE_WITH_CONCERNS | BLOCKED
```

## Ownership mode

Before Phase 3, run: `git shortlog -sn --since="90 days ago" --no-merges HEAD | head -5`

If the top author accounts for 80%+ of commits: solo mode — investigate issues found outside the current task and offer to fix them.

If below 80%: collaborative mode — flag issues outside the current task via AskUserQuestion and move on. Do not fix unilaterally.
