---
name: git-commit
description: Commit with decision context trailers — encodes the why, not just the what
version: 0.1.0
level: 1
triggers:
  - "commit this"
  - "write a commit"
  - "git commit"
  - "commit message"
context_files: []
steps:
  - name: Assess Complexity
    description: Is this trivial (typo, rename, formatting)? Use simple commit. Is it non-trivial? Use trailer format.
  - name: Write Subject Line
    description: Conventional commit format — type(scope): description. Imperative mood. Under 72 characters.
  - name: Write Body
    description: What problem does this solve? One to three sentences. Focus on why, not what.
  - name: Add Trailers
    description: Add Constraint, Rejected, Directive, Confidence, Scope-risk, Not-tested as applicable
  - name: Verify
    description: Read the commit message — does it give a future developer everything they need to understand this decision?
---

# Git Commit Skill

Write commits that encode the decision context, not just the change. Future developers (including you) will thank you.

## What Claude Gets Wrong Without This Skill

Without structure, commit messages describe what was done (which the diff already shows) instead of why it was done. The decisions, constraints, and rejected alternatives that shaped the change are lost. Six months later, when someone asks "why is it done this way?", the answer is gone.

## Commit Format

### Simple (trivial changes)

```
type(scope): description
```

Examples:
```
fix(auth): correct typo in error message
chore: bump dependency versions
style: reformat user service to match project conventions
```

### Non-trivial (decisions, tradeoffs, constraints)

```
type(scope): description

[Body — what problem this solves, 1-3 sentences]

Constraint: [active constraint that shaped the decision]
Rejected: [alternative considered] | [reason rejected]
Directive: [warning for future modifiers]
Confidence: high | medium | low
Scope-risk: narrow | moderate | broad
Not-tested: [edge case not covered by tests]
```

### Full Example

```
fix(auth): prevent silent session drops during long-running ops

Auth service returns inconsistent status codes on token expiry.
Interceptor now catches all 4xx and triggers inline refresh.

Constraint: Auth service does not support token introspection
Constraint: Must not add latency to non-expired-token paths
Rejected: Extend token TTL to 24h | security policy violation
Rejected: Background refresh on timer | race condition with concurrent requests
Directive: Error handling is intentionally broad — do not narrow without verifying upstream behavior
Confidence: high
Scope-risk: narrow
Not-tested: Auth service cold-start latency >500ms
```

## Trailer Reference

| Trailer | When to Use |
|---------|-------------|
| `Constraint:` | Something you could not change that shaped the solution |
| `Rejected:` | Alternative you considered seriously before rejecting |
| `Directive:` | Instructions for the next person to touch this code |
| `Confidence:` | How certain you are this is the right fix |
| `Scope-risk:` | How broad the blast radius of this change is |
| `Not-tested:` | Edge cases you know exist but did not cover |

## Conventional Commit Types

| Type | Use For |
|------|---------|
| `feat` | New feature or behavior |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or correcting tests |
| `docs` | Documentation only |
| `chore` | Build process, dependencies, tooling |
| `perf` | Performance improvement |
| `ci` | CI/CD configuration |

## Anti-Patterns

Do not write a commit message that just describes what the diff already shows. `add null check` tells you nothing. `add null check to prevent crash when user has no profile (new users created via SSO have no profile until first login)` tells you everything.

Do not add trailers to trivial commits. A typo fix does not need a `Constraint:` trailer.

Do not use past tense. Use imperative: `fix`, not `fixed`. `add`, not `added`.

## Mandatory Checklist

1. Verify the subject line is under 72 characters
2. Verify the type is one of the conventional commit types
3. Verify the body explains WHY, not what (the diff shows what)
4. Verify trailers are present for any non-trivial decision
5. Verify `Rejected:` trailers exist for any alternative that was seriously considered
6. Verify `Directive:` is present for any code that will be misunderstood without it
