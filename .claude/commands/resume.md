---
name: resume
description: Resume an interrupted mid-task session from context files
---

Invoke the resume skill now. Run these steps in order:

1. **Read .claude/context/handoff.md first** — this is the canonical record of the last session. If it exists, it takes priority over everything else for orientation. Surface the last commit hash, what was completed, and the exact next step.

2. **Read .claude/context/learnings.md** — scan for any patterns or decisions relevant to the next step.

3. **Read .claude/context/decisions.md** — surface any open architectural decisions that affect the next step.

4. **Check git status** — confirm whether handoff.md's stated commit hash matches HEAD. If not, note the gap.

5. **Present a session brief** — what was done, where we are, what the next step is. Wait for explicit confirmation before executing anything.
