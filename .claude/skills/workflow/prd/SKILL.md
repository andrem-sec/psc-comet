---
name: prd
description: Product Requirements Document — specify and verify before implementing
version: 0.1.0
level: 3
triggers:
  - "prd"
  - "write requirements"
  - "spec this out"
  - "requirements first"
  - "before we build"
pipeline:
  - prd
  - plan-first
context_files:
  - context/user.md
steps:
  - name: Capture Intent
    description: What is this feature or change trying to accomplish? State the goal in one sentence.
  - name: Scope Boundaries
    description: What is explicitly in scope? What is explicitly out of scope?
  - name: Draft Acceptance Criteria
    description: Write specific, verifiable criteria — not generic scaffolding
  - name: Refine Criteria
    description: Apply the quality gate — each criterion must be independently verifiable without subjective judgment
  - name: Identify Dependencies
    description: What must exist or be true before this can be built?
  - name: Confirm
    description: Present the PRD. Get explicit approval before handing off to plan-first.
---

# PRD Skill

Define what to build and how to verify it before writing a line of code. The output is a confirmed specification that plan-first uses as its source of truth.

## What Claude Gets Wrong Without This Skill

Without a PRD, implementation begins on an implicit spec. The spec lives only in the user's head and Claude's initial interpretation. When they diverge — and they always diverge on complex features — the mismatch is discovered at the end of implementation, not the beginning.

## The Acceptance Criteria Quality Gate

Auto-generated acceptance criteria are deliberately generic. They must be replaced with task-specific, independently verifiable criteria before the PRD is confirmed.

**WRONG (scaffold — reject these):**
```
- Implementation is complete
- Code compiles without errors
- Feature works as expected
```

**RIGHT (specific, verifiable):**
```
- POST /api/orders returns 201 with order ID when payload is valid
- POST /api/orders returns 422 with field-level errors when required fields are missing
- Order is written to orders table with status="pending" and timestamp within 1s of request
- Test file exists at tests/api/test_orders.py and all tests pass
```

The test: can you write a passing/failing test for this criterion without asking any clarifying questions? If yes, it is a good criterion. If no, refine it.

## PRD Format

```
## PRD: [feature name]
Date: [date] | Status: DRAFT → CONFIRMED

### Goal
[One sentence — what problem does this solve?]

### Scope
In: [explicit list of what is included]
Out: [explicit list of what is excluded]

### Acceptance Criteria
1. [Specific, verifiable criterion]
2. [Specific, verifiable criterion]
3. [Specific, verifiable criterion]

### Dependencies
- [What must exist before this can be built]

### Open Questions
- [Anything that needs resolution before starting]

### Confirmation
Confirmed? (yes / modify / no)
```

## Pipeline

After PRD is confirmed, pass it directly to plan-first. The plan should reference the acceptance criteria by number.

## Anti-Patterns

Do not start implementing while the PRD is still in DRAFT status.

Do not accept criteria you cannot write a test for. Push back and refine until each criterion is independently verifiable.

Do not include implementation details in the acceptance criteria — specify behavior, not mechanism.

## Mandatory Checklist

1. Verify each acceptance criterion is specific and independently verifiable
2. Verify no generic scaffold criteria survived (implementation complete, code compiles, etc.)
3. Verify scope has both an "In" and an "Out" section
4. Verify open questions were surfaced before confirmation (not discovered during implementation)
5. Verify the user explicitly confirmed the PRD before plan-first was invoked
