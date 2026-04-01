---
name: tdd
description: Test-driven development — Red, Green, Refactor with explicit phase gates
version: 0.2.0
level: 2
triggers:
  - "tdd"
  - "test driven"
  - "write tests first"
  - "TDD mode"
  - "/tdd"
context_files:
  - context/user.md
steps:
  - name: Red
    description: Write a failing test describing the desired behavior. Run it. Confirm it fails for the right reason.
  - name: Green
    description: Write minimum code to pass. Nothing more.
  - name: Verify
    description: Run the full test suite. All tests must pass, not just the new one.
  - name: Refactor
    description: Improve the implementation without changing behavior. Tests stay green.
  - name: Repeat
    description: Next behavior increment — return to Red.
---

# TDD Skill

Enforce the Red → Green → Refactor cycle.

## What Claude Gets Wrong Without This Skill

Without TDD enforcement, Claude writes implementation first and tests after. The tests then verify what the code does rather than what it should do — producing tests that pass by construction. The feedback loop is inverted: Claude discovers problems at the end of implementation rather than at the start.

## Phase Gates

### Red Phase — the only hard gate

Write the test first. Run it. If it passes, the test is wrong — either it is testing something that already exists or it is not actually asserting anything.

The test must fail for the right reason:
- CORRECT: `AssertionError: expected 401, got 200` — the behavior is not implemented yet
- WRONG: `ImportError: cannot import name 'login'` — the function doesn't exist yet, fix the import structure first

Do not proceed to Green until the test fails for the right reason.

### Green Phase

Write the minimum code to make the test pass. Not the cleanest code. Not the most extensible code. The minimum.

If you cannot make the test pass in under 15 minutes, the test scope is too large. Split it.

### Refactor Phase

One refactor at a time. Rename, extract function, remove duplication — one change. Run tests. Green. Next change.

Do not batch multiple structural changes in one refactor pass. If tests go red mid-refactor, you have changed too much to know which change broke it.

## Coverage Rule

Coverage targets are differentiated by code criticality:

**100% coverage required:**
- Security code (authentication, authorization, access control)
- Auth flows (login, logout, password reset, session management)
- Financial code (payments, transactions, billing, refunds)
- Data integrity (validation, sanitization, encryption/decryption)

**90% coverage required:**
- Public API endpoints
- Core business logic
- State management

**80% coverage required:**
- General application code
- UI components
- Utilities and helpers

**Why differentiated**: Not all code has the same cost-of-failure. A bug in auth can leak all user data. A bug in a UI tooltip is cosmetic. Invest test effort proportional to risk.

Check coverage before declaring Green complete. Do not regress existing coverage.

## Pass@k Metrics (from eval-harness)

For non-deterministic code (LLM calls, external API integration, complex business rules), measure reliability with pass@k metrics:

**pass@1**: Test passes on first attempt
- Target: >95% for critical paths
- Indicates stable, consistent behavior

**pass@3**: Test passes at least once in 3 attempts
- Target: >99% for capability tests
- Accounts for acceptable flakiness (network, timing, etc.)

**pass^3**: Test passes on all 3 attempts
- Target: 100% for regression tests
- Zero tolerance for regressions in existing behavior

Use these metrics when:
- Testing AI-generated outputs (semantic correctness may vary)
- Testing external API integration (network flakiness)
- Testing async operations (timing variability)

Run 3 times, record pass@1, pass@3, pass^3. Only use for non-deterministic code — deterministic tests should be pass@1 = 100%.

## Test Naming

```
test_[unit]_[scenario]_[expected_outcome]
```

Examples:
- `test_auth_with_expired_token_returns_401`
- `test_order_when_stock_zero_raises_OutOfStock`

## Anti-Patterns

Do not write implementation and then write a test that matches it. That is not TDD — it is documentation.

Do not test implementation details. Tests should not break when internal structure changes without behavior changing.

Do not mock the database in integration tests. Use a real test database. Mocked tests that pass while real behavior is broken are worse than no tests.

## Mandatory Checklist

1. Verify the test was written before any implementation code existed
2. Verify the test was run and confirmed to FAIL before writing implementation
3. Verify the test failed for the right reason (behavior missing, not import error)
4. Verify only minimum code was written to reach Green
5. Verify the full test suite passed (not just the new test)
6. Verify coverage was checked and met the 80% minimum
