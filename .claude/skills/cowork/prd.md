---
name: prd-cowork
description: Cowork-compatible PRD — spec requirements before implementing (single-file variant)
version: 0.1.0
level: 3
triggers:
  - "prd"
  - "write requirements"
  - "before we build"
platform: cowork
---

# PRD (Cowork)

Define what to build before writing any code.

## Steps

**1. Capture Intent**
Ask: What problem does this feature solve? State it in one sentence.

**2. Scope Boundaries**
In: [what is explicitly included]
Out: [what is explicitly excluded]

**3. Acceptance Criteria**
Write specific, verifiable criteria. Not: "it works." Yes: "POST /api/X returns 201 with Y when Z."

Test: can you write a test for this criterion without asking any questions? If yes, it is good. If no, refine it.

**4. Confirm**
Present the PRD. Ask: "Confirmed?" Do not proceed until confirmed.

## Output Format

```
PRD: [feature name]

Goal: [one sentence]

In scope: [list]
Out of scope: [list]

Acceptance criteria:
1. [specific, testable]
2. [specific, testable]
3. [specific, testable]

Confirmed? (yes / modify / no)
```

## Notes

- Reject generic criteria: "implementation complete", "code compiles", "feature works"
- One confirmed PRD is worth more than five iterations after implementation
- This is the Cowork single-file variant. Full version at .claude/skills/workflow/prd/SKILL.md
