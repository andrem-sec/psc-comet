---
name: code-review
description: Quality and semantic review — catches what automated tools miss
version: 0.1.0
level: 3
triggers:
  - "review this"
  - "code review"
  - "review the code"
  - "pre-merge review"
  - "/code-review"
context_files:
  - context/security-standards.md
steps:
  - name: Scope
    description: List files under review. State what this review covers and what it does not.
  - name: Semantic Review
    description: Check for semantic anti-patterns — code that is syntactically correct but logically wrong
  - name: Logic Review
    description: Trace the critical paths. Does the code actually do what it claims to do?
  - name: Error Handling
    description: What happens on every failure path? Are errors silenced, swallowed, or lost?
  - name: Test Coverage
    description: Do the tests actually exercise the behavior, or do they just cover lines?
  - name: Readability
    description: Will the next developer understand this code without asking the author?
  - name: Security Pass
    description: Flag anything that warrants a full security-gate run (do not duplicate security-gate)
  - name: Verdict
    description: APPROVE / REQUEST CHANGES / BLOCK — with specific, actionable feedback. Then write the current ISO timestamp to `.claude/context/.review-done` (signals stop-review-gate that review completed).
---

# Code Review Skill

Quality and semantic review. Separate from security-gate (which is an OWASP pass) — this reviews logic, correctness, and maintainability.

## What Claude Gets Wrong Without This Skill

Without explicit semantic review, Claude's code review focuses on what it can see at a glance — naming, formatting, obvious bugs. It misses logical errors that are invisible unless you trace execution, tests that assert the wrong thing, and anti-patterns that only become problems under load or edge cases.

## Semantic Anti-Patterns to Actively Check

These are the patterns that pass linting, pass type checking, and still cause production incidents:

**Silent failure**
```python
# WRONG — exception swallowed, caller never knows it failed
try:
    result = process(data)
except Exception:
    pass

# RIGHT — at minimum, log and re-raise or return an error
```

**Boolean parameter flags**
```python
# WRONG — caller has no idea what True means
render_page(user, True)

# RIGHT — use explicit keyword args or separate functions
render_page(user, include_draft=True)
```

**Mutable default arguments**
```python
# WRONG — default list is shared across all calls
def append_item(item, items=[]):
    items.append(item)
    return items

# RIGHT
def append_item(item, items=None):
    if items is None:
        items = []
```

**Late error detection**
Code that validates input halfway through execution after already modifying state. Validate first, act second.

**Asymmetric error handling**
Some code paths return None on failure, others raise exceptions, others return False. Callers must handle all three.

**Test that tests the mock**
```python
# WRONG — this test only proves the mock works
mock_service.process.return_value = {"status": "ok"}
result = handler.run()
assert result == {"status": "ok"}  # this just asserts the mock returned what it was told to
```

**Implicit ordering dependency**
Code that works only if methods are called in a specific order, with no enforcement of that order.

**Callback hell / pyramid of doom**
Deeply nested conditionals or callbacks that make control flow impossible to follow.

## Logic Tracing Protocol

For critical paths (auth, payment, data writes), trace the execution manually:
1. Identify entry point
2. Follow the happy path — does it reach the expected outcome?
3. Follow the primary failure path — is the error handled correctly?
4. Follow the edge case path — what happens with empty input, null, zero, max value?

## Verdict Format

**APPROVE:** Ready to merge. State any minor observations that do not require changes.

**REQUEST CHANGES:**
```
Issue: [description]
Location: [file:line]
Category: [semantic / logic / error-handling / test / readability]
Fix: [specific recommendation]
Blocking: No
```

**BLOCK:**
```
Issue: [description]
Location: [file:line]
Category: [category]
Impact: [what breaks or could break]
Fix: [specific recommendation]
Blocking: YES
```

## Adversarial Mode (`/code-review --adversarial`)

Standard mode asks: "What is wrong with this code?"
Adversarial mode asks: "Why is this the wrong approach entirely?"

Use adversarial mode when you want the implementation challenged, not just inspected. The output argues *against* the code. The user decides whether the argument holds.

**Trigger:** user invokes with `--adversarial` flag or asks for adversarial review.

**Questions to answer:**

1. **Wrong abstraction?** Is the chosen abstraction level correct, or does it leak internals / hide too much?
2. **Tests testing the right thing?** Are tests asserting behavior or implementation details? Would a rewrite break the tests even if behavior is preserved?
3. **Over-engineered?** Is this solving a problem that doesn't exist yet? What is the simplest version that satisfies the actual requirement?
4. **Hidden assumption?** What assumption does this code make that, if wrong, causes it to fail entirely?
5. **Complete rewrite trigger?** What real-world scenario would force a complete rewrite of this approach?

**Output format:**

```
ADVERSARIAL VERDICT: [ARGUMENT HOLDS / ARGUMENT WEAK]

Challenge 1 — [abstraction / tests / complexity / assumption / fragility]:
[Specific argument against the implementation]
Evidence: [file:line]

Challenge 2 — ...

User decision required: Accept / Reject each challenge.
```

Do not produce both standard and adversarial output in the same run. They are separate passes.

## Anti-Patterns

Do not combine code-review with security-gate. They are separate passes. Flag security concerns and recommend running security-gate — do not attempt both in one pass.

Do not issue REQUEST CHANGES without specific locations and fixes. "This could be cleaner" is not actionable feedback.

Do not approve code with untraced critical paths. If you did not trace auth, payment, or data write paths, say so in the scope limitations.

## Mandatory Checklist

1. Verify all semantic anti-patterns were actively checked (not assumed absent)
2. Verify critical paths were traced (auth, payment, data writes — wherever applicable)
3. Verify every REQUEST CHANGES or BLOCK issue has a file:line and specific fix
4. Verify tests were checked for what they actually assert, not just that they exist
5. Verify verdict is one of: APPROVE / REQUEST CHANGES / BLOCK
6. Verify scope limitations were stated (what was not reviewed)
