---
name: simplify
description: 3-agent parallel code review — reuse, quality, and efficiency — fixes issues found
version: 0.1.0
level: 2
triggers:
  - "/simplify"
  - "simplify this"
  - "clean up the code"
  - "review for quality"
context_files:
  - context/project.md
steps:
  - name: Spawn Reviewers
    description: Launch 3 parallel agents — Reuse, Quality, Efficiency — each reviewing the changed code
  - name: Aggregate Findings
    description: Collect all findings from the 3 agents
  - name: Fix
    description: Fix each valid issue directly. Skip false positives without argument.
  - name: Confirm
    description: Report what was fixed, or confirm the code was already clean
---

# Simplify Skill

Runs 3 specialized review agents in parallel against recently changed code, then fixes every
valid issue found. Used before creating PRs, after major implementations, or any time code
quality needs a structured pass.

The batch skill calls this automatically before opening a PR — run it manually any time.

## What Claude Gets Wrong Without This Skill

A single pass review misses issues that require focused attention. Reuse analysis requires
scanning the whole codebase for existing utilities — a different cognitive task from quality
review, which requires reading logic flow. Running all three simultaneously, each with a
focused mandate, catches more in less time.

## The 3 Agents

Spawn all three in a **single message block** for true parallelism.

### Agent 1 — Reuse Reviewer

Focus: find code that duplicates something that already exists.

- Functions that duplicate existing utilities or helpers
- Inline logic (string manipulation, path handling, env checks, type guards) that belongs
  in a shared utility
- Copy-pasted blocks across files that should be abstracted
- Dependencies re-implemented from scratch when a library already handles it

### Agent 2 — Quality Reviewer

Focus: structural and semantic anti-patterns.

- **Redundant state** — values being cached that could be derived on demand
- **Parameter sprawl** — functions gaining parameters that should be refactored instead
- **Near-duplicate logic** — similar blocks that need a shared abstraction
- **Leaky abstractions** — internals exposed through a public interface
- **Stringly-typed code** — raw strings where constants or enums belong
- **Unnecessary nesting** — wrapper elements with no layout or semantic value
- **WHAT comments** — comments that describe what the code does (delete them); keep WHY
  comments that explain a non-obvious constraint or decision

### Agent 3 — Efficiency Reviewer

Focus: unnecessary work and missed concurrency.

- **Redundant computation** — the same value calculated multiple times per call
- **N+1 patterns** — repeated queries or reads inside a loop
- **Missed concurrency** — sequential operations that are independent and could run in parallel
- **Hot-path bloat** — expensive work in startup, per-request, or per-render paths
- **Unbounded data structures** — collections that grow without a cap or cleanup
- **Overly broad operations** — reading a whole file when only a section is needed; loading all
  records when filtering first would suffice

## Spawn Format

```
Agent 1 prompt:
  You are a code reuse reviewer. Review the recently changed files for duplicated logic
  and missed opportunities to use existing utilities. [list changed files + relevant context]
  Report each finding as: FILE:LINE — description — suggested fix

Agent 2 prompt:
  You are a code quality reviewer. Review the recently changed files for structural and
  semantic anti-patterns. [list changed files + relevant context]
  Report each finding as: FILE:LINE — description — suggested fix

Agent 3 prompt:
  You are an efficiency reviewer. Review the recently changed files for unnecessary work
  and missed concurrency opportunities. [list changed files + relevant context]
  Report each finding as: FILE:LINE — description — suggested fix
```

All three are `subagent_type: "general-purpose"`, read-only (no writes — findings only).

## Fixing

After collecting all findings:

1. Group by file
2. Fix each valid issue directly (Edit/Write tools)
3. If a finding is a false positive, skip it silently — no explanation needed
4. If a finding requires a larger refactor than fits in this pass, note it but do not fix it

## Report Format

```
Simplify complete — [N] issues fixed, [N] false positives skipped

Fixed:
- auth/session.ts:147 — extracted hashPassword() to utils/crypto.ts (reuse)
- components/Form.tsx:23 — removed redundant useMemo (efficiency)

Clean: api/routes.ts (no issues found)
```

If nothing was found: "Code is clean — no issues found by any reviewer."

## Anti-Patterns

Do not run the three agents sequentially. They must run in parallel (single message block).

Do not fix issues that require understanding business logic without surfacing them to the user.

Do not argue with false positives. Skip them and move on.

## Mandatory Checklist

1. Verify all 3 agents were spawned in a single message block (parallel)
2. Verify all 3 results were collected before fixing anything
3. Verify each fix was applied directly (not described)
4. Verify the report distinguishes fixed vs skipped
