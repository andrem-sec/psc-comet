---
name: resume
description: Resume an interrupted mid-task session — reconstructs state from context files and picks up at the right step
version: 0.1.0
level: 2
triggers:
  - "resume"
  - "pick up where we left off"
  - "continue the task"
  - "where were we"
  - "/resume"
context_files:
  - context/learnings.md
  - context/project.md
  - context/decisions.md
steps:
  - name: Load State
    description: Read context/learnings.md for the most recent state entry. Identify task, step, completed work, and next action.
  - name: Load Decisions
    description: Read context/decisions.md for any PROPOSED decisions from the interrupted session
  - name: Reconstruct Context
    description: Read the files relevant to the interrupted task to rebuild working context
  - name: State Brief
    description: Present a reconstruction brief — what was done, what was next, any open blockers
  - name: Confirm Resumption
    description: Ask the user to confirm the reconstructed state before proceeding
  - name: Execute Next Step
    description: Once confirmed, execute the specific next action from the interrupted task
---

# Resume Skill

Reconstructs a mid-task session from context files and picks up at the right step. Used when a session ends before a task is complete — due to context limits, interruption, or a natural break.

## What Claude Gets Wrong Without This Skill

Without resume, a new session starts completely cold. Claude reads the conversation history (if available) or asks the user to re-explain where things are. The user re-explains. Time is wasted. Worse: if the session was compacted or the conversation history is unavailable, the state is gone. The work may be partially complete in ways that are invisible until something breaks.

Resume is the recovery mechanism for the pre-compact state capture written by `token-budget` and `wrap-up`.

## State Entry Format (written by token-budget / wrap-up)

```
[YYYY-MM-DD] state — Task: [name] | Step: [N] of [N] ([step name]) | Done: [list] | Next: [specific action] | Blocker: [if any]
```

## Reconstruction Protocol

### Step 1 — Load State

**Primary source:** Check for `context/session-memory.md`. If it exists, read all 8 sections:
- Current State, Task, Files, Workflow, Errors, Learnings, Key Results, Worklog

The session memory file is written by `/wrap-up` and is the authoritative state record.

**Fallback source (if session-memory.md is absent):** Read `context/learnings.md`. Find the most recent entry with category `state`. Extract:
- Task name and description
- Which step was in progress
- What had been completed
- What the next specific action was
- Any blockers noted

If neither source exists: the session was not using the wrap-up protocol. Tell the user and ask them to describe where things are manually.

### Step 2 — Load Open Decisions

Read `context/decisions.md`. Find any entries with `Status: PROPOSED` — these are decisions made during the interrupted session that have not been implemented yet.

### Step 3 — Reconstruct File Context

Read the files most relevant to the next action. Do not read everything — read what is needed to execute the next step.

Use the task name and step description from the state entry to identify which files to read.

### Step 4 — State Brief

Present the reconstruction:

```
Resume Brief — [task name]

Interrupted at: Step [N] of [N] — [step name]

Completed:
- [item]
- [item]

Next action: [specific action from state entry]

Open decisions: [list from decisions.md, or "none"]

Blocker: [from state entry, or "none"]

Files loaded: [list of files read for context]
```

### Step 5 — Confirm

Ask: "Does this match your understanding? Proceed? (yes / no — tell me what changed)"

Do not proceed to execution until confirmed. The state entry may be stale or incomplete.

### Step 6 — Execute

Execute exactly the next action from the state entry. Not the whole remaining plan — the specific next step. After completing it, run a checkpoint.

## If State Is Ambiguous

If the state entry is unclear or the reconstructed context does not match the files (e.g., the files were modified since the state was written), surface the discrepancy explicitly:

```
Discrepancy detected:
State says: [what state entry says]
Files show: [what the current files show]

Which is correct? (state / files / explain)
```

Do not guess. Incorrect resumption can overwrite work that was done.

## What NOT to Retry

**Critical**: If the interrupted session tried approaches that failed, those must be documented in `context/learnings.md` and **must not be retried** during resumption.

Look for learnings entries with category `mistake` or `approach` near the state entry timestamp. These document dead ends.

Example learnings entry:
```
[2026-03-28] mistake | Tried using async/await for database queries but hit race conditions. Reverted to synchronous approach. DO NOT retry async approach without transaction locking.
```

When resuming, if a next action would re-attempt a documented dead end:
1. Surface the conflict to the user
2. Suggest an alternative based on the learnings
3. Do NOT proceed with the dead-end approach without explicit user override

This prevents re-thrashing: repeating failed approaches because the session context was lost.

### Documenting Dead Ends During Execution

If you try an approach that fails during the resumed session:
1. Complete the current step or abandon it if blocked
2. Write the failed approach to `context/learnings.md` with category `mistake` or `approach`
3. Include enough detail that a future resume can recognize and avoid it
4. Suggest the next alternative approach before stopping

## Anti-Patterns

Do not try to resume from memory or conversation history. Only use context files — they are the ground truth.

Do not execute multiple steps before getting confirmation. Confirm state, then execute one step, then checkpoint.

Do not skip the confirm step even if the state looks clear. The user may have made changes between sessions.

## Mandatory Checklist

1. Verify context/learnings.md was read and a state entry was found (or user was informed it was missing)
2. Verify context/decisions.md was read for open decisions
3. Verify the relevant files were read for working context (not just the state entry)
4. Verify the state brief was presented before any execution began
5. Verify the user confirmed the reconstructed state
6. Verify only the next specific step was executed (not the whole remaining plan)
7. Verify a checkpoint was run after the first resumed step
