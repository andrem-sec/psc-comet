---
name: wrap-up
description: Session-end protocol — collect learnings, update context, commit session state
version: 0.2.0
level: 1
triggers:
  - "end session"
  - "wrap up"
  - "wrap-up"
  - "session end"
  - "close out"
  - "/wrap-up"
context_files:
  - context/user.md
  - context/learnings.md
  - context/learnings-index.md
steps:
  - name: Write Handoff
    description: Overwrite context/handoff.md using handoff-template.md as structure — Part 1 completed work, Part 2 open risks and next steps
  - name: Collect Learnings
    description: Review this session's work — what patterns, mistakes, or decisions are worth keeping?
  - name: Quality Gate
    description: Apply the 3-point test to each candidate learning before writing it
  - name: Route Learnings
    description: Read learnings-index.md for existing tags, present tag options to user, write to context/learnings/[tag].md or main learnings.md if universal
  - name: Update user.md
    description: Only if genuinely new information — diff against existing content before writing
  - name: Commit State
    description: Check current branch. If on main, present the branch choice prompt before committing. Stage and commit to the chosen destination. Then write the current ISO timestamp to `.claude/context/.wrapup-done` (signals stop-wrap-guard that wrap-up completed).
  - name: Reflect Check
    description: Ask user if new patterns or instincts emerged — if yes, invoke /reflect
  - name: Session Summary
    description: Three lines — done, learned, next
---

# Wrap-Up Skill

Run at the end of every session. Preserve knowledge before the context window closes.

## What Claude Gets Wrong Without This Skill

Without wrap-up, session learnings evaporate. The next session starts cold. Patterns that were discovered at cost get rediscovered. Decisions that were made get revisited without their rationale. The system does not improve.

## The 3-Point Quality Gate

Before writing any learning to learnings.md, it must pass all three:

1. Could someone Google this in 5 minutes? → **Must be NO**
2. Is this specific to this project or codebase? → **Must be YES**
3. Did this take real effort to discover? → **Must be YES**

Reject generic programming patterns, library usage examples, refactoring techniques, and anything a junior dev could find in the docs.

## Learning Entry Format

```
[YYYY-MM-DD] [category] — [concise, specific statement]
```

Categories: `pattern` | `mistake` | `approach` | `tool` | `decision`

Good entry: `[2026-03-25] mistake — Wrote settings.json hooks as escaped Python one-liners; they silently fail on edge cases. Move hooks to .claude/hooks/ shell scripts.`

Bad entry: `[2026-03-25] pattern — Always write tests before implementation.` (too generic, fails gate)

## Session Summary Format

```
Done: [what was completed]
Learned: [the one most valuable insight]
Next: [specific next action]
```

## Session Memory File

After collecting learnings and updating context files, write a session memory snapshot to `context/session-memory.md`. This file is the primary input for `/resume` at the next session start.

Overwrite the file each session (it tracks current state, not history).

### 8-Section Format

```markdown
## Current State
[What is true right now — not what was done, but what IS.
Current branch, file states, whether tests pass, open PRs, blockers.]

## Task
[The task that was active at session end and its acceptance criteria.
If multiple tasks, list all with their status.]

## Files
[Files touched this session, their roles, and their current state.
Format: path — role — state (clean/modified/broken)]

## Workflow
[The sequence of steps taken and their outcomes.
Ordered list. Mark completed steps. Note last completed step explicitly.]

## Errors
[Errors encountered this session and how they were resolved.
Unresolved errors: document what was tried and what failed.]

## Learnings
[Non-obvious things discovered this session that would affect future work.
Only include things that pass the 3-point quality gate.]

## Key Results
[Concrete outputs: files created, tests passing count, PRs opened, decisions made.]

## Worklog
[Timestamp-ordered list of major actions taken. Use approximate times if exact times unknown.
Format: ~HH:MM — [action]]
```

Write this file before committing. The resume skill reads it to reconstruct the session without re-reading the conversation.

## Branch Check

Before committing, run `git branch --show-current` to identify the current branch.

**If on any branch other than main:** commit normally — no prompt needed.

**If on main:** pause and present this choice to the user:

```
You are on main. Where should I commit this session's state?

  1. Commit to main anyway       (solo project / I know what I'm doing)
  2. Commit to an existing branch  (I'll pick from the list)
  3. Create a new branch         (I'll name it now)
  4. Skip the commit             (I'll handle it myself)
```

If they choose **2:** run `git branch` to list local branches, let the user pick, then `git checkout <branch>` and commit there.

If they choose **3:** ask for a branch name, run `git checkout -b <name>`, and commit there.

If they choose **4:** skip the commit step entirely. Note it in the session summary under Next.

Never commit without completing this check when on main.

## Commit Convention

```
chore: wrap-up [date] — [1-line session description]
```

## Anti-Patterns

Do not manufacture learnings to fill the section. If nothing new was learned, write: `[date] pattern — [existing approach confirmed, no new findings]`

Do not append learnings that fail the quality gate. Quantity is not the goal.

## Mandatory Checklist

1. Verify each learning candidate passed the 3-point quality gate before writing
2. Verify learnings.md was updated (or explicitly noted as no new entries)
3. Verify context/user.md reflects any goal changes from this session
4. Verify context/session-memory.md was written with all 8 sections populated
5. Verify current branch was checked before committing
5a. Verify the branch choice prompt was shown if on main
5b. Verify uncommitted changes were staged and committed to the chosen branch
6. Verify session summary is exactly 3 lines (Done / Learned / Next)
