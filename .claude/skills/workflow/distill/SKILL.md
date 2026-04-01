---
name: distill
description: Memory consolidation — distills session learnings and transcripts into persistent memory files
version: 0.1.0
level: 2
triggers:
  - "/distill"
  - "distill memory"
  - "consolidate memory"
  - "update memory files"
context_files:
  - context/learnings.md
steps:
  - name: Orient
    description: Survey the current memory landscape before writing anything
  - name: Gather
    description: Collect signal from learnings.md and recent session state
  - name: Consolidate
    description: Write and update memory files with new signal
  - name: Prune
    description: Keep MEMORY.md index under 200 lines, remove stale entries
---

# Distill Skill

Consolidates session learnings and accumulated context into the persistent memory system
(`~/.claude/memory/`). Run when the ember gate fires (heartbeat will notify you) or manually
at any time to refresh memory with recent work.

## What Claude Gets Wrong Without This Skill

Without distillation, session learnings accumulate in `context/learnings.md` but never get
promoted to the global memory system that persists across projects. The memory index grows
stale. Future sessions start with outdated context.

## When to Run

- When heartbeat surfaces an `ember-due` flag (automatic — run `/distill` to clear it)
- After a major task is complete and the learnings are worth preserving globally
- Before switching to a different project context
- When `context/learnings.md` has grown significantly since the last distillation

## The 4-Phase Process

### Phase 1 — Orient

Before writing anything, survey the current memory landscape:

```bash
ls ~/.claude/memory/
cat ~/.claude/memory/MEMORY.md
```

Read the MEMORY.md index. Skim 2-3 of the most relevant topic files to understand what's
already there. Avoid duplicating entries that already exist.

### Phase 2 — Gather

Collect signal from three sources, in priority order:

1. **context/learnings.md** — most recent entries (scan from bottom up, newest first)
2. **context/session-memory.md** — current session state and key results
3. **context/decisions.md** — any PROPOSED or recently decided entries

For each entry, ask: is this general enough to be useful outside this project, or is it
project-specific? General → global memory. Project-specific → project memory file.

### Phase 3 — Consolidate

Write or update memory files:

- **New insight:** create or append to the relevant topic file
- **Existing entry that changed:** update in place, note what changed
- **Contradicted fact:** delete the old entry, write the corrected one
- **Relative dates:** convert to absolute (e.g. "last week" → "2026-03-24")

Use the standard memory frontmatter format:
```markdown
---
name: [descriptive name]
description: [one-line description for relevance matching]
type: user | feedback | project | reference
---

[memory content]
```

**Bash access is read-only during distillation.** Use only:
`ls`, `find`, `grep`, `cat`, `stat`, `wc`, `head`, `tail`

All writes go through the Write/Edit tools only.

### Phase 4 — Prune and Index

After writing:

1. Update `~/.claude/memory/MEMORY.md` index — one line per file, under 150 chars
2. Keep the index under **200 lines** total
3. Remove pointers to files that no longer exist
4. Demote verbose index entries (>150 chars) — move detail to the topic file, keep pointer short
5. Resolve any contradictions between topic files

## Scope Decision

| Content type | Where it goes |
|---|---|
| How I prefer to work, style preferences | `~/.claude/memory/` (user scope) |
| Project architecture, active constraints | `~/.claude/memory/` with project tag |
| Lessons that apply across projects | `~/.claude/memory/` (global) |
| One-off task detail | Leave in learnings.md, do not promote |

## After Distillation

Update the ember lock to mark consolidation complete:

```bash
touch ~/.claude/memory/.ember.lock 2>/dev/null || true
```

This resets the ember gate's time counter. The session counter resets automatically when
the gate fires.

## Anti-Patterns

Do not copy-paste entire learnings.md entries into memory. Summarize — memory files should
be denser than raw session notes.

Do not distill one-off task details. The quality gate: would this entry help a future session
that has never seen this project before? If no, leave it in learnings.md.

Do not let MEMORY.md exceed 200 lines. When it approaches the limit, merge related entries
into topic files and keep only the pointer in the index.

## Mandatory Checklist

1. Verify MEMORY.md index was read before writing any new files
2. Verify each new entry was checked against existing entries for duplication
3. Verify bash commands used were read-only only
4. Verify MEMORY.md index is under 200 lines after pruning
5. Verify ember.lock was touched to reset the gate timer
