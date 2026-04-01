---
name: code-review-cowork
description: Cowork-compatible code review — semantic anti-patterns and logic tracing (single-file)
version: 0.1.0
level: 3
triggers:
  - "review this"
  - "code review"
  - "pre-merge review"
platform: cowork
---

# Code Review (Cowork)

Quality review for code shared in the conversation. Paste the code and ask for review.

## Semantic Anti-Patterns to Check

**Silent failure** — exception caught and swallowed. Caller never knows it failed.

**Boolean flag parameters** — `render(user, True)` — the True means nothing without reading the function signature.

**Mutable default arguments** — default value shared across all calls (Python-specific but concept applies broadly).

**Test that tests the mock** — test passes because mock returned what it was told to return, not because the code works.

**Implicit ordering dependency** — works only if methods are called in a specific sequence, with no enforcement.

**Late validation** — input validated after state has already been modified.

## Logic Tracing

For auth, payment, and data write paths: trace execution.
1. Happy path — does it reach the expected outcome?
2. Primary failure path — is the error handled?
3. Edge case — what happens with null, empty, zero?

## Verdict

**APPROVE** — ready. State any non-blocking observations.

**REQUEST CHANGES** — issues found that should be fixed, not blocking immediate merge.

**BLOCK** — issues that must be resolved before merge. State impact clearly.

For every issue: what, where, why it matters, specific fix.

## Note

This is the Cowork single-file variant. The full version with complete anti-pattern reference is at `.claude/skills/workflow/code-review/SKILL.md`.
