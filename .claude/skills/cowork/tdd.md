---
name: tdd-cowork
description: Cowork-compatible TDD — Red, Green, Refactor via conversation (single-file)
version: 0.1.0
level: 2
triggers:
  - "tdd"
  - "test driven"
  - "write tests first"
platform: cowork
---

# TDD (Cowork)

Test-driven development adapted for conversational flow. You share code, I enforce the cycle.

## The Cycle

**Red** — Write the test first. Share it. Confirm it would fail before any implementation exists.

**Green** — Write minimum code to pass. Not the cleanest code. The minimum. Share it.

**Verify** — Does the full test suite pass? Not just the new test?

**Refactor** — One structural change. Tests stay green throughout. No behavior changes.

**Repeat** — Next behavior increment. Back to Red.

## Hard Rules

- Test before implementation. If you share implementation first, I will ask for the test before reviewing it.
- The test must fail for the right reason. A test that passes before implementation is wrong.
- Minimum for Green means minimum. Do not optimize during the Green phase.
- One change per Refactor. Rename, extract, or remove duplication — one thing, then verify.

## What Good Tests Look Like

```
test_[unit]_[scenario]_[expected_outcome]
```

- `test_auth_with_expired_token_returns_401`
- `test_cart_when_item_out_of_stock_raises_error`

Test behavior, not implementation. Tests should survive internal refactors.

## Note

This is the Cowork variant. Claude Code full version at `.claude/skills/workflow/tdd/SKILL.md`.
