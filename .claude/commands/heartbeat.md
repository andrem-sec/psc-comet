---
name: heartbeat
description: Session-start orientation — load context, surface learnings, confirm registry
---

Invoke the heartbeat skill now. Run these steps in order:

1. **Check ember-due flag** — if `.claude/context/ember-due` exists, surface it:
   "Memory consolidation is due (ember gate triggered). Run `/distill` when convenient this session."
   Do not run distill automatically.

2. **Check for `.claude/context/handoff.md`** — if it exists, read it. Surface Part 2 (open risks
   and next steps) prominently. Part 1 is historical context -- load it but do not lead with it.

3. **Load user context** — read `.claude/context/user.md` to orient to the user's role, preferences,
   and active projects.

4. **Load learnings** — read both:
   - `context/learnings.md` (main -- always-relevant standing rules)
   - `context/learnings-index.md` (MOC -- tag map for on-demand navigation)
   Do not load individual tagged files unless a specific topic makes them directly relevant.
   If neither file exists, note it and continue without error.

5. **Scan git status** — note current branch, uncommitted changes, and whether HEAD matches the
   commit in handoff.md (if present).

6. **Produce session brief** — current branch, last commit, ember-due notice (if any), open risks
   from handoff, and suggested first action.
