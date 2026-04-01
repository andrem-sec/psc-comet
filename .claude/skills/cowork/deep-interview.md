---
name: deep-interview-cowork
description: Cowork-compatible Socratic problem exploration with ambiguity gate (single-file)
version: 0.1.0
level: 3
triggers:
  - "deep interview"
  - "explore this problem"
  - "before we spec"
platform: cowork
---

# Deep-Interview (Cowork)

Understand the problem before writing requirements. The gate is ≤ 20% ambiguity.

## Protocol

**Step 1 — Problem statement**
Ask: "State the problem in one sentence."
Restate it back. Confirm: "Is this right?" Don't move forward until confirmed.

**Step 2 — Identify critical unknowns**
Before asking anything, identify the questions whose answers would change the approach. Categories:
- User / stakeholder
- Scope boundaries
- Constraints (what can't change)
- Success criteria
- Failure modes
- Prior attempts
- Integration points

Count them. Tell the user: "I have [N] critical questions. We need ≤ 20% unanswered to proceed."

**Step 3 — One question at a time**
Ask the most impactful unknown. Wait for the answer. After each answer:
- Mark it answered
- Recalculate score: unanswered ÷ total
- Ask next

**Step 4 — Ambiguity gate (≤ 20%)**
When score reaches ≤ 20%:
```
Ambiguity: [N]% ([X]/[Y] answered) — gate OPEN

Summary:
- [Finding 1]
- [Finding 2]
- [Finding 3]

Proceed to requirements? (yes / keep going)
```

## Rules

One question at a time. No lists of questions. No asking what you already know from context. Only ask questions whose answers change the approach.
