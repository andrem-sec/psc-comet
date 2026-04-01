---
name: wrap-up-cowork
description: Cowork-compatible session-end protocol (single-file variant)
version: 0.1.0
triggers:
  - "end session"
  - "wrap up"
  - "close out"
platform: cowork
---

# Wrap-Up (Cowork)

Run at the end of every session.

## Steps

**1. Collect Learnings**
Review what happened this session. Identify 1-3 things worth remembering:
- A pattern that worked well
- A mistake made and corrected
- A decision that might be revisited

**2. Format Entries**
Use the standard format: `[YYYY-MM-DD] [category] — [learning]`

Categories: `pattern` | `mistake` | `approach` | `tool` | `decision`

**3. Session Summary**
Produce a 3-line summary:
```
Done: [what was completed]
Learned: [key insight]
Next: [what to pick up next session]
```

**4. Handoff**
Share the formatted learning entries and session summary with the user to paste into their notes or learnings log.

## Notes

- Cowork has no persistent file system access between sessions. This variant produces output for the user to save manually.
- For the full persistent version with automatic `learnings.md` updates, use the Claude Code `.claude/skills/core/wrap-up/` variant.
- Do not manufacture learnings — only record what actually happened.
