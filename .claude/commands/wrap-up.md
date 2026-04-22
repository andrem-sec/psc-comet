---
name: wrap-up
description: End-of-session protocol — collect learnings, update context, commit
---

Invoke the wrap-up skill now. Run these steps in order:

1. **Write handoff** — overwrite `.claude/context/handoff.md` using `context/handoff-template.md`
   as the structure guide. Follow the template sections exactly:
   - Part 1: factual summary of completed work. Do not repeat what is already in git commit messages.
   - Part 2: open risks and specific next steps, actionable enough for a cold session to continue.
   - Multi-project block: include only when more than one project is actively in flight.
   - Remove optional sections (Files In Progress, Environment State) if there is nothing to put in them.

2. **Append learnings** — read `context/learnings-index.md` to see existing tags and the main vs.
   tagged rule. Decide for each learning:
   - If it is a standing rule that applies in every session regardless of project or task, append to
     `context/learnings.md` (main). Keep main small -- when in doubt, use a tag.
   - Otherwise: present the user with the existing tag list from the index, let them choose a tag or
     create a new one, then append to `context/learnings/[tag].md`. Update the tag's last-updated
     date and entry count in the Tag Usage Log in `learnings-index.md`.
   - If `context/learnings/` does not exist: note it, append to `context/learnings.md` only.
   - If nothing new was learned this session, say so and skip this step.

3. **Update user.md** — only if genuinely new information emerged this session. Before writing,
   compare against existing content. Do not rewrite sections that already capture the same information.
   Append-only unless an existing entry is factually wrong or outdated.

4. **Write session log** — append a session entry to
   `02. AI-Vault/Sessions/YYYYMMDD - Session Log.md` (use today's date for YYYYMMDD).
   - If today's file does not exist: create it with this header, then write the first entry:
     ```
     ---
     date: YYYY-MM-DD
     tags: [session-log, ProjectTag]
     ---

     # Session Log — YYYY-MM-DD

     ---
     ```
   - If today's file already exists: append after the last entry. Never remove or overwrite existing entries.
   - Entry format — use the session end time (HH:MM, 24h):
     ```
     ## HH:MM — Topic

     - what was done or built
     - key decision made and why (one line)
     - notable finding or blocker
     ```
   - Replace `ProjectTag` with the relevant project tags for this session (e.g. `Backend`, `Infra`, `PSC`, `ProjectName`).
     Use only tags that were actually touched this session.
   - Keep bullets to 5-8 items. Summarise -- do not transcribe. No next steps, no risks (those belong in handoff).
   - After writing, run `bash scripts/vault-sync.sh push` to commit and sync the vault.

5. **Commit** — conventional commit message for any uncommitted changes.

6. **Reflect check** — ask the user: "Did any new patterns, reusable rules, or instincts emerge
   this session worth capturing? (yes/no)"
   - If yes: invoke `/reflect` now.
   - If no: wrap-up is complete.
