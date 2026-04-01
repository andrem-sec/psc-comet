---
name: lesson-gen
description: Mid-session quick capture — save an insight before the context moves on
version: 0.2.0
level: 1
triggers:
  - "extract pattern"
  - "save this approach"
  - "log this"
  - "note this"
context_files:
  - context/learnings.md
steps:
  - name: Identify
    description: What specifically happened? State it in one sentence.
  - name: Quality Gate
    description: Apply the 3-point test — can't Google it, codebase-specific, took real effort
  - name: Generalize
    description: State the general principle, not just the session-specific instance
  - name: Write
    description: Append to context/learnings.md in standard format
---

# Lesson-Gen Skill

Mid-session quick capture. Use when something is worth keeping but you do not want to break flow to do a full wrap-up.

## The 3-Point Quality Gate

1. Could someone Google this in 5 minutes? → **Must be NO**
2. Is this specific to this project or codebase? → **Must be YES**
3. Did this take real effort to discover? → **Must be YES**

## 4-Verdict System

After applying the quality gate, classify the learning into one of four verdicts:

### 1. SAVE
Passes all 3 quality gate points. Save immediately to `context/learnings.md` in standard format.

### 2. IMPROVE THEN SAVE
Good insight but needs refinement:
- Statement is too vague or session-specific
- Missing the general principle
- Lacks concrete details (file paths, numbers, specific errors)

**Action**: Rewrite to be more concrete/general, then save to `context/learnings.md`.

Example:
- Before: "Database queries were slow"
- After: "PostgreSQL queries without indexes on user_id field caused 500ms+ latency on /api/users endpoint. Added index, reduced to 50ms."

### 3. ABSORB INTO EXISTING SKILL
This learning belongs in a skill, not in `context/learnings.md`:
- It's a reusable technique or pattern
- It applies across projects, not just this one
- It's procedural (how to do X) rather than factual (X happened)

**Action**: Identify which existing skill this belongs in (or propose a new skill if none fit). Add to that skill's body or examples section.

Example:
- Learning: "When debugging API issues, always check network tab first, then server logs, then database queries"
- Verdict: ABSORB INTO debug-session skill (this is a general debugging procedure)

### 4. DROP
Fails the quality gate:
- Can be Googled easily
- Too generic (not codebase-specific)
- Low effort / obvious

**Action**: Discard. Do not write to any file.

## Entry Format

```
[YYYY-MM-DD] [category] — [specific statement]
```

One entry per insight. Do not bundle.

## Anti-Patterns

Do not write the session-specific instance — write the general principle it illustrates.

Do not write what you intended to do — write what actually happened and what it revealed.

## Mandatory Checklist

1. Verify the learning was evaluated against all 3 quality gate points
2. Verify one of the 4 verdicts was chosen (SAVE / IMPROVE THEN SAVE / ABSORB / DROP)
3. Verify SAVE verdicts were appended to context/learnings.md in correct format
4. Verify IMPROVE THEN SAVE verdicts were refined before saving
5. Verify ABSORB verdicts identified the target skill
6. Verify DROP verdicts were not written anywhere
