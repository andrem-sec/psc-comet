---
name: reflect
description: Extract instincts and reusable patterns from the current session
---

# Reflect

Invoke the reflect skill now. This is the session instinct extraction step.

## Purpose

Extract instinct candidates from this session -- patterns, rules, and lessons that should
influence future sessions. These go into the instinct store via `instinct-cli.py`.

An instinct is a reusable rule: given condition X, take action Y. It is more specific than
a learning (which is narrative) and more actionable (which is why it goes in a separate store).

## Steps

1. **Review the session.** What patterns emerged? What mistakes were made and why?
   What decisions were taken that were non-obvious? What worked better than expected?

2. **Propose instinct candidates.** For each candidate:
   - **Trigger:** the specific condition under which this applies -- be precise. Vague triggers
     fire on everything and are useless. Bad: "when writing code". Good: "when modifying a hook
     that has shellcheck directives".
   - **Action:** what to do when the trigger fires
   - **Domain:** one of: workflow, security, testing, code, git, tool, meta, platform

   Present all candidates as a numbered list before asking for any confirmation.

3. **Confirm with user.** Show the full list. For each candidate the user says: yes, no, or
   rephrase. Collect all responses before running any commands. Do not add any instinct the
   user has not confirmed.

4. **Add confirmed instincts.** For each confirmed instinct, run:
   ```
   python scripts/continuous-learning-v2/instinct-cli.py add "TRIGGER" "ACTION" --domain DOMAIN
   ```
   Run from the project root. Show the command output for each addition.

5. **Summary.** Report: N instincts added, list their IDs and triggers.

## If Nothing Emerged

If the session had no patterns worth capturing, say so explicitly:
"No instinct candidates identified for this session."
Do not manufacture candidates to fill space.

## Graceful Degradation

If `instinct-cli.py` is not found or Python is unavailable:
- List the confirmed instincts formatted for manual entry
- Note: "instinct-cli.py unavailable -- run `bash scripts/bootstrap-phase8.sh` to restore"
