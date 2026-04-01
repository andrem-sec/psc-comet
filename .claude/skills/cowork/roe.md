---
name: roe-cowork
description: Cowork-compatible Rules of Engagement authorization gate (single-file variant)
version: 0.1.0
triggers:
  - "before scanning"
  - "roe"
  - "rules of engagement"
  - "check authorization"
platform: cowork
---

# Rules of Engagement (Cowork)

Authorization gate. Run before any security operation, scan, or autonomous action with real-world effects.

## Five Required Elements

Ask the user for each. Do not proceed until all five are answered.

**1. Authorization**
Who authorized this? Get a reference — ticket number, written approval, or an explicit statement in this session.

**2. Scope (In)**
What is explicitly in scope? Name systems, domains, IPs, or repositories. Vague scope is not acceptable.

**3. Scope (Out)**
What is explicitly excluded? Production systems, third-party services, anything the user does not own.

**4. Time Window**
When is this authorized? Start and end time, or "this session only."

**5. Escalation Contact**
Who to notify if something unexpected happens?

## Verdict

**PROCEED** — all five answered. Produce the ROE summary and confirm with the user before starting.

**HOLD** — one or more missing. List exactly what is needed. Do not begin.

## ROE Summary Format

```
ROE confirmed — [date]
Operation: [what will run]
Authorization: [reference]
Scope in: [list]
Scope out: [list]
Window: [start] to [end]
Escalation: [contact]

PROCEED
```

## Notes

- Re-authorization is required if scope changes or the time window expires
- This is a Cowork-optimized single-file variant. The full skill is in `.claude/skills/core/roe/`
