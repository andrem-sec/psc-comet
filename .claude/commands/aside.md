---
name: aside
description: Handle side questions mid-task without losing context
---

Invoke the aside protocol now. Freeze current task state and handle the following side question or request. After answering, resume the original task exactly where it was paused.

## Protocol

1. **Capture state**: Note the current task, what step you're on, and what's next
2. **Clarify if ambiguous**: If the aside is unclear, ask ONE clarifying question maximum
3. **Execute read-only**: Handle the aside using READ-ONLY operations (Read, Grep, Glob, Bash read commands)
4. **Detect redirects**: If the aside is actually a new primary task (not a side question), alert the user
5. **Resume**: Return to the frozen task state and continue exactly where you left off

## Aside Categories

**Information request**: "What does this function do?", "Where is X defined?"
- Response: Answer directly, then resume

**Clarification**: "Should I use approach A or B for the current task?"
- Response: Answer, update the current task plan if needed, then continue

**Sanity check**: "Is this the right file?", "Does this look correct?"
- Response: Verify, provide feedback, then resume

**Redirect** (NOT an aside): "Actually, let's work on Y instead"
- Response: "This sounds like a task change, not an aside. Should I abandon the current task and start Y?"

## Chain Asides

If the user asks another aside before you resume, handle it the same way. Track the depth (Aside 1, Aside 2, etc.) and resume in reverse order.

## Important

- Do NOT use Write, Edit, or Bash write operations during an aside
- Do NOT modify files or project state
- Do NOT create commits or run builds
- If the aside requires modification, respond: "This aside requires file changes. Should I exit aside mode and make this the primary task?"

## Resume Statement

When resuming, always state:
```
Aside complete. Resuming: [original task description]
Next step: [what you're about to do]
```
