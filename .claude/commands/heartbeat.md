---
name: heartbeat
description: Session-start orientation — load context, surface learnings, confirm registry
---

Invoke the heartbeat skill now. Run these steps in order:

**Before Step 1:** Fire `git fetch origin --quiet 2>/dev/null` as a Bash tool call in the same
response as the first file reads below (Steps 1-4). Do not wait for it to complete before
proceeding. If it has not returned within a few seconds, skip the update check at Step 7 and
continue without blocking the session.

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

7. **Update check** — run `git log HEAD..origin/main --oneline 2>/dev/null`.
   - If output is empty or the command errors: skip silently.
   - If commits are listed: surface the count and commit list below the session brief. Ask the
     user if they want to pull.
   - If the user confirms: run `git pull --ff-only`.
   - If `--ff-only` fails (non-fast-forward or uncommitted local changes block the merge): do not
     force. Report the failure, tell the user to commit or stash local changes first, then re-run
     `git pull --ff-only` manually.
   - Note the current branch in the output so the comparison is unambiguous (e.g.
     "main is 3 commits behind origin/main").
