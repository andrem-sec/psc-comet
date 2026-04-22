---
name: reflect
description: Extract instinct candidates from the current session and add confirmed ones to the instinct store
version: 0.1.0
level: 2
triggers:
  - "/reflect"
  - "any patterns this session?"
  - "extract instincts"
  - "session patterns"
context_files:
  - context/learnings.md
steps:
  - name: Review Session
    description: Identify patterns, mistakes, non-obvious decisions, and unexpected successes from this session
  - name: Propose Candidates
    description: Format each candidate with trigger, action, and domain fields — present the full list before asking for confirmation
  - name: Confirm with User
    description: Walk through the list, collect yes/no/rephrase for each — do not add anything unconfirmed
  - name: Add to Instinct Store
    description: Run instinct-cli.py add for each confirmed candidate, show output
  - name: Summary
    description: Report how many instincts were added and their IDs
---

# Reflect Skill

Run at the end of a session (invoked inline by `/wrap-up`) or at any point when new reusable
patterns emerged. Captures instincts — not learnings.

## Learnings vs. Instincts

A **learning** is narrative context: what happened, what was discovered, what was decided.
It goes in `context/learnings/[tag].md` via `/wrap-up`.

An **instinct** is an actionable rule: given condition X, take action Y. It goes in the
instinct store via `instinct-cli.py`. It must be specific enough to fire reliably and
distinct enough not to duplicate an existing entry.

## Instinct Quality Gate

Before proposing a candidate, it must pass all three:

1. **Trigger is specific** — not "when writing code" but "when modifying a hook that has
   an existing shellcheck directive"
2. **Action is concrete** — not "be careful" but "preserve the shellcheck source= directive
   and add it back if the line is removed during editing"
3. **Domain is assigned** — one of: workflow, security, testing, code, git, tool, meta, platform

Reject candidates that are too generic, too obvious, or already covered by an existing instinct.

## Running instinct-cli.py

```bash
# Add a confirmed instinct
python scripts/continuous-learning-v2/instinct-cli.py add "TRIGGER" "ACTION" --domain DOMAIN

# Verify it was added
python scripts/continuous-learning-v2/instinct-cli.py list --domain DOMAIN
```

Run from the project root (the directory containing `.claude/`).

## Graceful Degradation

If `instinct-cli.py` is not found or Python is unavailable, list the confirmed instincts
in a code block formatted for manual entry. Note: "Run `bash scripts/bootstrap-phase8.sh`
to restore the instinct CLI."

## Anti-Patterns

Do not manufacture candidates. If the session had no reusable patterns, say so explicitly
and end reflect immediately.

Do not propose instincts that are already in `context/learnings.md` as standing rules — those
are learnings, not instincts.

## Mandatory Checklist

1. Verify the full candidate list was presented before any confirmation was requested
2. Verify no instinct was added without explicit user confirmation
3. Verify each added instinct has all three fields: trigger, action, domain
4. Verify instinct-cli.py output was shown for each addition
5. Verify a summary of IDs was provided at the end
