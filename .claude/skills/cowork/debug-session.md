---
name: debug-session-cowork
description: Cowork-compatible structured debugging — hypothesis-driven, evidence-tracked (single-file)
version: 0.1.0
level: 3
triggers:
  - "debug"
  - "something is wrong"
  - "not working"
  - "figure out why"
platform: cowork
---

# Debug Session (Cowork)

Hypothesis-driven debugging. Replaces trial-and-error with structured investigation.

## Steps

**1. State the symptom precisely**
Not: "it's broken." Yes: "POST /api/orders returns 500 when stock is 0, but only on the second request."

**2. Generate 3 hypotheses (before investigating any)**

For each:
```
Hypothesis: [what might be causing this]
Confidence: HIGH / MEDIUM / LOW
Evidence for: [what supports this]
Evidence against: [what contradicts this]
```

**3. Identify the discriminating probe**
What single test or observation would eliminate the most hypotheses at once?

**4. Run the probe. Record the exact result.**

**5. Update hypothesis confidence. Eliminate refuted ones.**

**6. Converge or run next probe.**

**7. Fix + regression test**
Once hypothesis is confirmed: fix it, verify it resolves the symptom, identify how to prevent recurrence.

## 3-Failure Circuit Breaker

If the same hypothesis has been tested 3 times without resolution:
- Stop
- Escalate — ask the user for additional context
- Do not try a fourth variation of the same approach

## Anti-Patterns

Do not start with the most obvious hypothesis. Generate all three before investigating any.

Do not skip the "evidence against" column. Bugs hide behind assumptions.

Do not fix without confirming the hypothesis. A symptom fix without root cause analysis recurs.
