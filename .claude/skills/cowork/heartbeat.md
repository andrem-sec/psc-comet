---
name: heartbeat-cowork
description: Cowork-compatible session-start orientation (single-file variant)
version: 0.1.0
triggers:
  - "start session"
  - "heartbeat"
platform: cowork
---

# Heartbeat (Cowork)

Run at the start of every session.

## Steps

**1. Orient**
Ask the user: What is the primary goal for this session? Note it.

**2. Surface Context**
If the user has shared a learnings log or prior session notes, read them now and summarize anything relevant to today's goal in 3 bullet points or fewer.

**3. Confirm Approach**
State the session plan in one sentence. Ask: "Does this match what you had in mind?"

## Session Brief Format

```
Session start — [date]
Goal: [user's stated goal]
Relevant context: [1-3 bullets from prior learnings, or "none"]
Plan: [one sentence]
```

## Notes

- Keep this brief — 2-3 exchanges maximum
- If no prior context exists, skip Step 2 and go straight to confirming the goal
- This is a Cowork-optimized single-file variant. The full skill suite is in the Claude Code `.claude/skills/core/heartbeat/` directory.
