---
name: deep-interview
description: Socratic problem exploration — identifies critical unknowns and gates on ≤20% ambiguity before proceeding
version: 0.1.0
level: 3
triggers:
  - "deep interview"
  - "explore this problem"
  - "before we spec"
  - "understand the problem"
  - "/deep-interview"
pipeline:
  - deep-interview
  - prd
context_files:
  - context/user.md
  - context/project.md
steps:
  - name: Problem Statement
    description: Ask the user to state the problem in one sentence. Restate it back. Confirm alignment before proceeding.
  - name: Critical Unknown Identification
    description: Identify the full set of critical unknowns — questions whose answers would change the approach. Score ambiguity.
  - name: Socratic Questioning
    description: Ask the most impactful unknown first. One question at a time. Recalculate ambiguity score after each answer.
  - name: Ambiguity Gate
    description: When ambiguity score reaches ≤20%, the gate opens. State the score and offer to proceed to PRD.
  - name: Handoff
    description: Summarize what was learned. Invoke the prd skill with the enriched problem understanding as context.
---

# Deep-Interview Skill

Systematic Socratic exploration before requirements are written. The output is a understood problem, not a solution. PRD comes after.

## What Claude Gets Wrong Without This Skill

Without deep-interview, PRD starts from the user's initial framing. The initial framing is almost always incomplete — it describes symptoms rather than root causes, assumes constraints that may not exist, and omits the edge cases that make the problem hard. PRD built on an incomplete framing produces requirements that solve the wrong problem precisely.

## Ambiguity Scoring

**Ambiguity score** = unanswered critical questions ÷ total critical questions identified

**Target gate:** ≤ 20% (at least 80% of critical questions answered)

### Critical Question Categories

A question is *critical* if its answer would change either the approach or the scope. Not all questions are critical.

| Category | Examples |
|----------|---------|
| **User / Stakeholder** | Who experiences this problem? Who decides success? |
| **Scope** | What is explicitly in and out? Where does this end? |
| **Constraints** | What cannot change? What must remain backwards-compatible? |
| **Success criteria** | What does success look like? How will it be measured? |
| **Failure modes** | What are the top 3 ways this solution fails? |
| **Prior attempts** | What has been tried? Why did it fail? |
| **Integration** | What does this touch? What is upstream and downstream? |

## The Interview Protocol

### Step 1 — Problem Statement

Ask: "State the problem in one sentence."

Restate it back in different words. Ask: "Is this right?" Do not proceed until the user confirms.

### Step 2 — Critical Unknown Identification

Before asking any questions, internally identify the full set of critical unknowns across all 7 categories. Count them. This is the denominator for ambiguity scoring.

State to the user: "I've identified [N] critical unknowns. I'll work through them — we need ≤20% unanswered before proceeding."

### Step 3 — Socratic Questioning

One question at a time. After each answer:
- Mark the unknown as answered
- Recalculate the ambiguity score
- Determine if any new unknowns were revealed by the answer (add to total if critical)
- Ask the next highest-impact unknown

Do not ask multiple questions at once. The point is depth of understanding, not breadth of coverage.

### Step 4 — Ambiguity Gate

When the score reaches ≤ 20%, state:

```
Ambiguity score: [N]% ([X] of [Y] critical questions answered)
Gate: OPEN — ready to proceed to PRD.

Summary of what we know:
- [Key finding 1]
- [Key finding 2]
- [Key finding 3]

Proceed to PRD? (yes / continue interviewing)
```

The user may choose to continue interviewing past the gate. The gate is a floor, not a ceiling.

### Step 5 — Handoff to PRD

Pass the enriched problem understanding to the `prd` skill. The PRD should reference the interview findings, not re-derive them.

## Anti-Patterns

Do not ask questions you already know the answers to from `context/project.md` or `context/user.md`. Read those first.

Do not ask for information that does not change the approach. Only critical unknowns count toward the score.

Do not rush to the gate. If the score drops to 20% but a major category (e.g., failure modes) is completely unanswered, ask one more question from that category.

Do not paraphrase the user's answer back as a new question. Each exchange should reduce ambiguity, not circle.

## Mandatory Checklist

1. Verify the problem statement was restated and confirmed before any questions were asked
2. Verify critical unknowns were identified across all 7 categories before asking the first question
3. Verify only one question was asked at a time
4. Verify the ambiguity score was recalculated after every answer
5. Verify the gate was not opened until the score reached ≤ 20%
6. Verify the handoff to PRD included the interview findings as context
