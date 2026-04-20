---
name: heartbeat
description: Session-start orientation — loads context, surfaces learnings, confirms registry
version: 0.2.0
level: 1
triggers:
  - "start session"
  - "heartbeat"
  - "session start"
  - "/heartbeat"
pipeline:
  - heartbeat
context_files:
  - context/user.md
  - context/principles.md
  - context/security-standards.md
  - context/learnings.md
  - context/project.md
  - context/learnings-index.md
  - context/decisions.md
steps:
  - name: Load Context
    description: Read context/user.md and context/learnings.md
  - name: Scan Environment
    description: Check git status, current branch, last 3 commits
  - name: Surface Learnings
    description: Filter learnings.md for entries relevant to today's likely work
  - name: Confirm Registry
    description: List available skills and agents relevant to this session
  - name: Set Intention
    description: Ask for today's primary goal if not already stated; note it
---

# Heartbeat Skill

Run at the start of every session. Orient before working.

## What Claude Gets Wrong Without This Skill

Without heartbeat, Claude starts from zero each session — no memory of prior decisions, no awareness of active blockers, no connection between today's goal and yesterday's learnings. The same mistakes recur. Context is rebuilt from scratch through conversation instead of being loaded directly.

## Session Brief Format

```
Session — [date]
Branch: [branch] | [clean/N modified files]
Recent: [last 2 commits, one line each]

Relevant learnings:
- [entry] (only if applicable)

Goal: [stated or inferred]
```

Keep the brief to 6 lines or fewer. This is orientation, not a report.

## Context Load Order

Load stable files before dynamic files to maximize prompt cache hits across tool calls.

Stable prefix (load first): `user.md`, `principles.md`, `security-standards.md`
Dynamic suffix (load last): `project.md`, `learnings.md`, tagged files, `decisions.md`

See `context/context-priority.md` for the full priority hierarchy and conflict resolution rule.

## Ember Gate Check

After loading context, check for `.claude/context/ember-due`. If this file exists:

1. Read its contents (shows session count and hours since last consolidation)
2. Include this line in the session brief: `Memory consolidation due: [file contents]`
3. Recommend the user run `/distill` at a convenient point
4. Delete the flag file after surfacing it (prevents repeated alerts for the same trigger)

```bash
# To check and clear the flag:
cat .claude/context/ember-due 2>/dev/null && rm -f .claude/context/ember-due
```

The ember gate fires when both: 24+ hours have passed since last consolidation AND 5+ sessions have run. This is the auto-consolidation signal from the ember-gate.sh hook.

## Vault Surfacing (Optional)

If Obsidian MCP is active AND the session goal has been stated, query AI-Vault for
pages relevant to today's work and surface the top 2 in the session brief.

```
Relevant vault pages:
- [[Page Title]] — one-line relevance note
- [[Page Title]] — one-line relevance note
```

If Obsidian MCP is unavailable, skip this step silently. Do not report the absence
unless the user asks about vault integration.

## Registry Awareness

Skill, agent, and command registries exist at:
- `context/skills-registry.md`
- `context/agents-registry.md`
- `context/commands-registry.md`

Do not load these files at session start. Note their existence in the session brief if the
user asks what is available. Load on demand when a skill, agent, or command needs to be selected.

## Anti-Patterns

Do not load every skill in the registry. Load only what is relevant to the session goal.

Do not produce a long report. If context/user.md is empty, say so in one line and ask the user to run `/start-here`.

Do not ask multiple questions. One clarifying question at most.

## Mandatory Checklist

1. Verify context/user.md was read (not skipped)
2. Verify context/learnings.md was read (not skipped)
3. Verify git status was checked
4. Verify session brief is 6 lines or fewer
5. Verify today's goal is captured before proceeding
6. Verify stable files were loaded before dynamic files (user.md, principles.md, security-standards.md before project.md, learnings-index.md, decisions.md)
