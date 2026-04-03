---
name: strategic-compact
description: Hook-based compaction suggestions at logical task boundaries
version: 0.1.0
level: 2
triggers:
  - "compact now"
  - "context getting full"
  - "running out of space"
  - "should i compact"
context_files:
  - context/learnings.md
steps:
  - name: Tool Invocation Count
    description: Track tool calls since last compact or session start
  - name: Boundary Detection
    description: Identify if current state is at a logical task boundary
  - name: Compact Decision
    description: Apply decision guide to recommend compact or defer
  - name: State Preservation
    description: Remind user to capture critical state before compacting
  - name: Context Documentation
    description: Update learnings.md with pre-compact state if needed
---

# Strategic Compact Skill

Suggests /compact at logical task boundaries. Prevents premature compaction that loses critical context.

## What Claude Gets Wrong Without This Skill

Without strategic compaction guidance, Claude either:
1. Compacts too early and loses debugging context mid-investigation
2. Compacts too late and runs out of context window during critical work
3. Doesn't preserve state before compacting, losing progress tracking
4. Compacts at random moments instead of natural breakpoints

Strategic compaction maintains context hygiene without disrupting workflow.

## Tool Invocation Tracking

Compaction suggestions triggered by tool call count:
- **50 tool calls**: First suggestion (soft reminder)
- **75 tool calls**: Second reminder (moderate urgency)
- **100+ tool calls**: Strong recommendation (context pressure likely)

**Count these tools:**
- Read, Write, Edit (file operations)
- Bash (command execution)
- Grep, Glob (search operations)
- Task (subagent spawning)

**Don't count:** TodoWrite, AskUserQuestion (metadata operations)

Integration with existing preserve-on-compact.sh hook: hook fires on /compact; this skill decides when to suggest it.

## Decision Guide

| Transition | Compact? | Reasoning |
|------------|----------|-----------|
| Research → Planning | **YES** | Research artifacts captured, planning starts fresh |
| Planning → Implementation | **YES** | Plan finalized, implementation is new phase |
| Mid-Implementation | **NO** | Variable state, error traces, partial progress would be lost |
| After Failed Approach | **YES** | Dead end documented in learnings.md, fresh start needed |
| Feature Complete → Testing | **YES** | Implementation done, testing is verification phase |
| Bug Hunt in Progress | **NO** | Debugging requires full context (stack traces, state, prior attempts) |
| After Successful PR Merge | **YES** | Work complete, next task starts clean |
| Before stepping away (>5 min) | **YES** | Prompt cache expires after 5 minutes — returning cold reprocesses full context at full cost |

**General Rule**: Compact at phase transitions where the prior phase's working context is no longer needed for the next phase.

## What Survives Compaction

Claude Code's compaction preserves:
- CLAUDE.md and all .claude/ configuration
- Recent tool use (last ~10-15 operations)
- Current file state (all files as they exist now)
- Conversation summary (condensed key decisions)

**Lost during compaction:**
- Detailed reasoning for past decisions
- Full error messages and stack traces
- Alternative approaches that were tried and rejected
- Intermediate variable states and debugging context
- Specific code snippets from earlier discussion

## What to Preserve Before Compacting

Before compacting, ensure these are captured:

**In context/learnings.md:**
- Patterns discovered this session
- Mistakes made and their causes
- Dead ends: approaches tried that didn't work (and why)
- Key decisions and their rationale

**In context/decisions.md:**
- Architectural decisions (if any ADRs were made)
- Tradeoffs accepted

**In code comments:**
- Complex logic explanations (if implementation is subtle)
- Constraint documentation (if unusual requirements)

**In test files:**
- Regression tests for bugs found this session

The preserve-on-compact.sh hook prompts for this, but this skill provides the content checklist.

## Integration with Hooks

**preserve-on-compact.sh (PreCompact hook):**
- Fires when user runs /compact
- Prompts: "Capture state in learnings.md?"
- This skill defines what "state" means

**Recommended enhancement:**
Add tool invocation counter to preserve-on-compact.sh:
```bash
TOOL_COUNT=$(grep -c "Tool:" .claude/session.log 2>/dev/null || echo 0)
if [ "$TOOL_COUNT" -gt 50 ]; then
  echo "50+ tool calls since last compact. Consider capturing state."
fi
```

(Note: session.log doesn't exist in current Claude Code. This is aspirational for future hook enhancements.)

## Anti-Patterns

**Compacting mid-debugging**: You're investigating a bug, have a stack trace, tried 3 approaches. Compacting now loses all that context. Finish the investigation first.

**Compacting to "clean up"**: Compaction isn't for aesthetics. Only compact at task boundaries or when context pressure is real (100+ tool calls).

**Ignoring the 50-call reminder**: If you're at 50 calls and still in the same task, that's a signal the task might be too large. Consider checkpointing or breaking it down.

**Compacting without preserving dead ends**: "I tried X but it failed because Y" is critical for the next session. Write it to learnings.md before compacting.

## Mandatory Checklist

1. Verify tool invocation count is tracked or estimated (50/75/100+ thresholds)
2. Verify current task state identified (mid-implementation, post-planning, debugging, etc.)
3. Verify decision guide consulted (transition type determines compact recommendation)
4. Verify if compacting: critical state captured in learnings.md (dead ends, patterns, decisions)
5. Verify if compacting: no active debugging in progress (stack traces and error context would be lost)
6. Verify if deferring: user informed why compaction deferred and when to revisit
7. Verify preserve-on-compact.sh hook will fire if user proceeds with /compact
