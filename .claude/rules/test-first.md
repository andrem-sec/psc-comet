---
paths:
  - "src/**"
  - "lib/**"
  - "app/**"
  - "pkg/**"
---

# Test-First Rule

When writing new code in these paths:

1. Write the failing test first (Red)
2. Write the minimum code to make it pass (Green)
3. Refactor with confidence the test provides (Refactor)

Never write implementation code without a corresponding test. If a test file does not exist for the module being modified, create it first.

Coverage minimum: 80% on new code. Do not regress existing coverage.
