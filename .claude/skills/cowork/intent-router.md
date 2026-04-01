---
name: intent-router-cowork
description: Cowork-compatible intent classification and routing (single-file variant)
version: 0.1.0
triggers:
  - "not sure where to start"
  - "what should I do"
  - "how should I approach"
  - ambiguous request
platform: cowork
---

# Intent Router (Cowork)

Classify the request before doing anything. One wrong turn costs more than one question.

## Steps

**1. Restate**
Restate the request in one sentence. If restating reveals ambiguity, ask one clarifying question.

**2. Classify**

| Category | Signals | Start With |
|----------|---------|------------|
| New feature | "add", "build", "implement", new capability | deep-interview → prd |
| Bug fix | "broken", "error", "not working", regression | debug-session |
| Refactor | "clean up", no behavior change | refactor |
| Security review | "is this secure", reviewing local code | security-gate |
| Security operation | scanning, probing, testing systems | roe first — always |
| Architecture | "how should we structure", high impact decision | consensus-plan |
| Code review | "review this", pre-merge | code-review |
| Deploy | "ship", "release", "push to prod" | security-gate |
| Unclear | Cannot classify confidently | Ask one question |

**3. Route**
Name the first skill only. Not the full pipeline.

## Output Format

```
Intent: [category]
Reason: [one sentence]
First step: [skill name] — [what it accomplishes]
```

Or if unclear:
```
Intent: unclear
Question: [one question that resolves it]
```

## Notes

- Security operations always route to `roe` before anything else
- One category only — if it spans two, pick what happens first
- This is a Cowork-optimized single-file variant. The full skill is in `.claude/skills/workflow/intent-router/`
