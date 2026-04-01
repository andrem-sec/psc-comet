---
name: intent-router
description: Classify ambiguous requests and route to the correct skill or agent before any execution begins
version: 0.1.0
level: 1
triggers:
  - "not sure where to start"
  - "what should I do with this"
  - "how should I approach"
  - "where do I begin"
  - ambiguous request before starting work
context_files:
  - context/project.md
steps:
  - name: Restate
    description: Restate the request in one sentence to confirm understanding. If restating reveals ambiguity, ask one clarifying question before classifying.
  - name: Classify
    description: Assign exactly one category from the routing table. If it could be two categories, pick the one that must happen first.
  - name: Route
    description: Name the first skill or agent to invoke and state why it is first — not what the full pipeline looks like.
---

# Intent Router Skill

Classify before executing. Ambiguous requests that go straight to implementation end up solving the wrong problem. One classification step costs almost nothing; backtracking from the wrong path costs a lot.

## What Claude Gets Wrong Without This Skill

Without intent routing, Claude defaults to the most familiar interpretation of an ambiguous request and starts implementing. A request like "fix the auth flow" could be a bug fix, a security review, a refactor, or a new feature — each requiring a different starting skill. Picking wrong means work that has to be undone.

## Routing Table

| Category | Signals | First Skill / Agent |
|----------|---------|---------------------|
| New feature | "add", "build", "implement", "I want", new capability | `deep-interview` → `prd` → `feature-pipeline` |
| Bug fix | "broken", "not working", "error", "failing", regression | `debug-session` → `fix-pipeline` |
| Refactor | "clean up", "reorganize", "too complex", no behavior change | `refactor` |
| Security review | "is this secure", "check for vulns", reviewing local code | `security-gate` |
| Security operation | scanning, testing external systems, autonomous probing | `roe` → `docker-sandbox` |
| Architectural decision | "how should we structure", multiple valid approaches, high impact | `consensus-plan` |
| Code review | "review this", "look at my changes", pre-merge check | `code-review` |
| Deploy / release | "deploy", "ship", "release", "push to prod" | `security-gate` → deploy |
| Unclear | Cannot classify with confidence | `deep-interview` |

## Classification Rules

**One category only.** If a request spans multiple categories, pick the one that must happen first. A "secure new feature" is a new feature — security review comes after implementation, not before.

**"Unclear" is a valid classification.** Do not force a category to avoid the overhead of a clarifying question. Wrong category costs more than one question.

**Security operations require ROE before anything else.** Any request that involves scanning, probing, or testing systems — even systems the user owns — routes to `roe` first. No exceptions.

**Ambiguity signals:**
- Request contains "also" (multiple intents)
- Request contains "fix/improve/update" without specifying what is broken vs what should change
- Request references a system without stating the desired end state
- Request is a question, not a directive

## Route Output Format

```
Intent: [category]
Reason: [one sentence — why this category over alternatives]
First step: [skill or agent name] — [what it will accomplish]
```

If unclear:
```
Intent: unclear
Ambiguity: [what is missing]
Clarifying question: [one question that resolves the ambiguity]
```

## Anti-Patterns

Do not present the full pipeline at this stage. Route to the first step only. The pipeline emerges from the work.

Do not reclassify after the user confirms. If the classification was wrong, that is new information — run intent-router again with the corrected understanding.

Do not skip routing because the request "seems obvious." The obvious interpretation is often not the intended one.

## Mandatory Checklist

1. Verify the request was restated before classifying — not assumed
2. Verify exactly one category was assigned
3. Verify the route names the first skill only — not the full pipeline
4. Verify security operations were routed to `roe` before any execution
5. Verify "unclear" was used when classification was not confident — not a forced category
