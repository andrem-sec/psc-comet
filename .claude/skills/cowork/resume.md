---
name: resume-cowork
description: Cowork-compatible session resume — reconstructs interrupted task state (single-file)
version: 0.1.0
level: 2
triggers:
  - "resume"
  - "pick up where we left off"
  - "where were we"
platform: cowork
---

# Resume (Cowork)

Pick up an interrupted task. Used when a conversation continues after a break.

## Steps

**1. Ask the user for state**
"Where did we leave off? What was the last thing completed and what was next?"

**2. Read any shared context**
If the user has pasted notes, a learnings log, or a state entry — read them now.

**3. Reconstruct and confirm**
State what you understand:
```
Resume brief:
Last completed: [X]
Next step: [specific action]
Open questions: [if any]
```
Ask: "Is this right?"

**4. Execute next step only**
Once confirmed — execute the specific next action. Not the whole remaining plan. One step, then check in.

## If State Is Unclear

Ask: "What are you trying to accomplish and where did things stop?" Don't guess.

## Note

The Claude Code version reads `context/learnings.md` state entries automatically. In Cowork, the user provides the state. This is the Cowork-adapted version.
