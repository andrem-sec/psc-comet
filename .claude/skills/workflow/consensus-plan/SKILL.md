---
name: consensus-plan
description: Planner → Architect → Critic deliberation loop — produces a formally validated ADR
version: 0.1.0
level: 3
triggers:
  - "consensus plan"
  - "deliberate on this"
  - "get a second opinion on the plan"
  - "validate this plan"
  - "/consensus-plan"
pipeline:
  - consensus-plan
  - plan-first
context_files:
  - context/user.md
  - context/project.md
  - context/decisions.md
steps:
  - name: Planner Draft
    description: Invoke the planner agent to produce an initial phased implementation plan
  - name: Architect Steelman
    description: Invoke the architect agent to find the strongest objection to the plan
  - name: Convergence Check
    description: Does the objection have a clear resolution? If yes, revise and proceed. If fundamental, loop back.
  - name: Pre-Mortem (high-risk only)
    description: For HIGH risk plans — identify 3 specific failure scenarios before finalizing
  - name: ADR Output
    description: Write the formal Architecture Decision Record to context/decisions.md
  - name: Confirmation Gate
    description: Present the ADR. Wait for explicit approval before any implementation begins.
---

# Consensus-Plan Skill

A structured deliberation protocol that forces a plan through challenge before it is approved. The output is a formally validated ADR — not just a plan the author thinks is good, but a plan that survived its strongest objection.

## What Claude Gets Wrong Without This Skill

Without deliberation, a plan reflects only the assumptions of the entity that created it. Those assumptions are invisible to the planner — they only become visible when someone with a different perspective examines the same problem. The Planner → Architect → Critic loop exists to surface blind spots before implementation, not during it.

## The Deliberation Loop

### Round 1 — Planner Draft

Invoke the `planner` agent with the task description. The planner produces a structured plan (phases, steps, risks, parallel opportunities) in the standard format.

Do not modify the plan before passing it to the architect.

### Round 2 — Architect Steelman

Invoke the `architect` agent with:
- The planner's draft
- This instruction: "Find the strongest objection to this plan. Steelman it — argue for the objection as if you believe it. Then state the minimum modification to the plan that would resolve it."

The architect must produce:
1. The strongest objection (not a list — the single strongest one)
2. The steelman argument for that objection
3. A specific modification that resolves it

If the architect cannot find a meaningful objection, it must say so explicitly: "No material objection found. Plan is sound." This is a valid outcome — not a failure to engage.

### Round 2.5 — Anonymous Peer Review

After the architect steelman, invoke a third reviewer (researcher agent) with:
- The planner's draft
- The architect's objection and proposed modification
- This instruction: "Review this plan as if you have no stake in either side. You do not know who wrote the plan or the objection. Find the one assumption that both the planner and architect have accepted without questioning."

The peer reviewer must produce:
1. The shared assumption (one, not a list)
2. What would have to be true for that assumption to be wrong
3. A recommendation: proceed / revisit assumption before continuing

This step prevents anchoring: both the planner and architect may share a blind spot that only
an unprimed reviewer can surface.

If the peer reviewer finds no unquestioned assumption, it must say so explicitly.

**Nudge mechanism:** After peer review, issue a forced challenge to the planner:

```
Nudge: The plan assumes [shared assumption identified by peer reviewer].
Challenge: [one question that would invalidate this assumption if the answer is no]
Planner must address this before the plan is finalized.
```

The planner responds inline. If the response is satisfactory, proceed to Convergence Check.
If the response reveals a gap, return to Round 2 with the new information.

### Round 3 — Convergence Check

Assess the architect's objection:

**Resolvable:** The objection points to a specific step or assumption. The modification is clear. Revise the plan to incorporate it and proceed to ADR.

**Fundamental:** The objection challenges the approach itself, not a specific step. Return the plan to the planner with the objection stated explicitly. Run another round. Maximum 2 loops — if still unresolved after 2, escalate to the user.

**No objection:** Proceed directly to ADR.

### Round 4 (Conditional) — Pre-Mortem

For plans with risk level HIGH only:

"If this plan fails in 90 days, the 3 most likely causes are:"
1. [Specific failure scenario with mechanism]
2. [Specific failure scenario with mechanism]
3. [Specific failure scenario with mechanism]

Each scenario must include: what fails, why it fails (the mechanism), and what the early warning signal would be. Vague scenarios ("the team doesn't have time") do not count.

## ADR Output Format

```
## [YYYY-MM-DD] [decision title]
Status: PROPOSED
Risk: LOW | MEDIUM | HIGH

### Context
[Why this decision is being made now — 2-3 sentences]

### Decision Drivers
1. [Driver]
2. [Driver]
3. [Driver]

### Options Considered

#### Option A: [chosen approach]
Pros: [list]
Cons: [list]

#### Option B: [alternative considered]
Pros: [list]
Cons: [list]
Rejected because: [specific reason]

### Decision
[What was decided]

### Rationale
[Why this option, referencing decision drivers]

### Consequences
Positive: [what gets better]
Negative: [what gets harder]

### Follow-ups
- [ ] [Action required as a result]

### Pre-Mortem (HIGH risk only)
Failure scenario 1: [mechanism + early warning]
Failure scenario 2: [mechanism + early warning]
Failure scenario 3: [mechanism + early warning]

### Architect Review
Objection raised: [what it was]
Resolution: [how the plan addressed it]
Reviewer verdict: APPROVED | NO OBJECTION
```

Write this to `context/decisions.md`.

### Living Decisions

ADRs are not permanent. Add a `Revisit trigger` field to every ADR:

```
### Revisit trigger
[Condition that would make this decision worth re-evaluating — e.g., "if X dependency is deprecated",
"if team size exceeds N", "if performance degrades past Y threshold"]
```

At session start (heartbeat) or at `/retro`, surface any ADR whose revisit trigger has been met.
Past decisions are reference — they are not binding if circumstances have changed.

## Confirmation Gate

Present the ADR to the user. Ask: "Confirmed? (yes / modify / no)"

Do not begin any implementation until the user confirms. A PROPOSED ADR is not an approved one.

## When to Use Consensus-Plan vs Plan-First

| Situation | Use |
|-----------|-----|
| 1-5 files, clear approach | `plan-first` |
| Complex feature, architectural tradeoffs | `consensus-plan` |
| Security-sensitive or irreversible operations | `consensus-plan` |
| Refactor of core module | `consensus-plan` |
| Uncertainty about the right approach | `consensus-plan` |

## Anti-Patterns

Do not skip the architect round because the plan "seems obvious." The architect finds objections to obvious plans most reliably.

Do not let the architect produce a list of objections. One strongest objection only — a list diffuses focus.

Do not loop more than twice. If the plan is still unresolved after 2 loops, the problem is not the plan — the problem is ambiguity in the task. Run `deep-interview` first.

## Mandatory Checklist

1. Verify the planner agent was invoked and produced a structured plan
2. Verify the architect agent was invoked with explicit steelman instructions
3. Verify the architect produced exactly one objection (not a list)
4. Verify Round 2.5 anonymous peer review was run (researcher agent, no prior context)
5. Verify the nudge was issued and the planner responded before convergence
6. Verify the objection was either resolved in the plan or escalated to the user
7. Verify pre-mortem was produced for HIGH risk plans (not skipped)
8. Verify the ADR was written to context/decisions.md with a Revisit trigger field
9. Verify the user confirmed the ADR before any implementation began
