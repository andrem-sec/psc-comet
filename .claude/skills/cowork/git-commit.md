---
name: git-commit-cowork
description: Cowork-compatible commit message with decision context trailers (single-file)
version: 0.1.0
level: 1
triggers:
  - "commit this"
  - "write a commit"
  - "commit message"
platform: cowork
---

# Git Commit (Cowork)

Write commits that encode the decision context, not just the change.

## Format

**Simple (typo, rename, formatting):**
```
type(scope): description
```

**Non-trivial (decisions, tradeoffs, constraints):**
```
type(scope): description

[Why this solves the problem — 1-3 sentences]

Constraint: [something you could not change]
Rejected: [alternative] | [why rejected]
Directive: [warning for the next person to touch this]
Confidence: high | medium | low
```

## Types

`feat` `fix` `refactor` `test` `docs` `chore` `perf` `ci`

## Rules

- Subject line under 72 characters
- Imperative mood: "fix", not "fixed"
- Body explains WHY — the diff shows what
- Add `Rejected:` for any alternative seriously considered
- Add `Directive:` for any code that will be misunderstood without context

## Example

```
fix(auth): prevent silent session drops on token expiry

Auth service returns inconsistent 4xx codes, so interceptor
now catches all 4xx and triggers inline refresh.

Constraint: Auth service does not support token introspection
Rejected: Extend TTL to 24h | security policy violation
Directive: Error handling is intentionally broad — do not narrow
Confidence: high
```
