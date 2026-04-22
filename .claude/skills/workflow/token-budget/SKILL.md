---
name: token-budget
description: Context window management — track spend, decide when to compact, preserve state
version: 0.1.0
level: 2
triggers:
  - "context getting long"
  - "token budget"
  - "should we compact"
  - "running out of context"
  - "context window"
context_files:
  - context/learnings.md
  - context/project.md
steps:
  - name: Assess
    description: Estimate current context usage and how much remains
  - name: Triage
    description: What must be preserved vs. what can be safely dropped?
  - name: Pre-Compact Capture
    description: Write critical state to context/ files before compacting
  - name: Compact Decision
    description: Compact now, continue until natural break, or restructure the approach
---

# Token Budget Skill

Manage context window spend in long sessions. Prevents the silent failure mode where context fills up mid-task and Claude starts dropping earlier instructions.

## What Claude Gets Wrong Without This Skill

Without active budget management, context fills gradually and silently. Claude begins deprioritizing early rules, earlier decisions, and the beginning of the task plan. The first thing to be dropped is often the most important — the constraints and goals stated at session start.

The failure mode is not an error. It is drift that is invisible until the work is noticeably wrong.

## Context Window Spend Estimation

Claude cannot precisely count tokens mid-conversation. Use these rough signals:

**Low usage (safe):**
- Conversation just started
- Only a few files have been read
- No large code blocks or file contents in context

**Medium usage (watch):**
- Multiple large files have been read and quoted
- Long code generation has happened
- Several agent spawns have returned results
- The session has been running for 30+ minutes of active work

**High usage (act soon):**
- Earlier parts of the conversation are likely compressed
- Recall of details from early in the session is uncertain
- The system prompt rules feel less "active"
- You are getting suggestions that contradict early decisions

**Critical (act now):**
- You cannot recall a constraint from early in the session
- The heartbeat brief from session start is gone
- Rules from CLAUDE.md are not being applied

## Compaction Thresholds (from Claude Code source)

Claude Code's autocompact triggers at **93% of effective context** where:
```
effectiveWindow = contextWindow - 20,000 (reserved for compaction overhead)
```

PSC acts earlier:

| Threshold | State | Action |
|---|---|---|
| ~90% | Warning | Run /checkpoint immediately |
| ~93% | Autocompact trigger | Claude Code may compact without warning |
| ~95% | Blocking | New tool calls may be refused |

**Time-based trigger:** If a session has been running for more than 2 hours of active work without compaction, consider compacting at the next natural task boundary — regardless of estimated token count. Long sessions accumulate drift that is invisible in usage estimates.

**Cache-efficiency signal:** If Claude is repeating itself or reconstructing reasoning it has already done, the cached context may no longer be serving it. This is a secondary compaction signal independent of token count.

## Pre-Compact Capture Protocol

Before compacting, write to context files anything that is not already there:

1. **Open decisions** — any decision made this session that is not yet in `context/decisions.md`
2. **Active constraints** — constraints discovered this session not in `context/project.md`
3. **In-progress state** — current task, which step, what is done, what is next
4. **Blocking learnings** — anything discovered that would change the approach

Format for in-progress state:
```
## In-Progress State — [date]
Task: [what is being worked on]
Status: Step [N] of [N] — [current step name]
Completed: [list]
Next: [specific next action]
Blocker: [if any]
```

Write this to `context/learnings.md` under a `state` category entry.

## Compact Decision Matrix

| Situation | Decision |
|-----------|----------|
| At a natural task boundary | Compact now — clean state |
| Mid-task, state can be fully captured | Pre-compact capture, then compact |
| Mid-task, complex state hard to capture | Continue to next natural break |
| Actively debugging with rich accumulated context | Do not compact — the context IS the tool |
| Early in session, usage is low | Continue — no action needed |

## After Compacting

Run heartbeat immediately. The session brief re-establishes context. Read `context/learnings.md` for the in-progress state entry if one was written.

## Anti-Patterns

Do not compact mid-implementation without writing state first. Coming back to an empty context after compaction means re-reading everything.

Do not compact during an active debug session. The accumulated evidence is the most valuable part.

Do not ignore high-usage signals. Drift is silent and cumulative.

## Mandatory Checklist

1. Verify open decisions were written to context/decisions.md before compacting
2. Verify in-progress state was written to context/learnings.md before compacting
3. Verify compact decision was based on usage assessment, not just "it's been a while"
4. Verify heartbeat was run immediately after compacting
