---
name: batch
description: Parallel agent swarm — decomposes work into independent units, spawns isolated workers, tracks PRs via fan-in
version: 0.1.0
level: 3
triggers:
  - "/batch"
  - "parallel agents"
  - "swarm this"
  - "batch this work"
  - "run in parallel"
context_files:
  - context/project.md
  - context/learnings.md
steps:
  - name: Research
    description: Spawn researcher to understand the codebase area. Identify what is parallelizable.
  - name: Decompose
    description: Break work into 5-30 self-contained, independently mergeable units. Write the e2e test recipe.
  - name: Plan Review
    description: Enter plan mode. Present decomposition and e2e recipe. Wait for explicit approval.
  - name: Spawn Workers
    description: After approval, spawn all workers in a single message block with isolation worktree and run_in_background true.
  - name: Track
    description: Render status table. As task-notifications arrive, parse PR sentinel and update table.
  - name: Summarize
    description: When all workers reported, produce final summary with PR count and any failures.
---

# Batch Skill

Orchestrates 5–30 parallel agents working on independent code changes in isolated git worktrees. Each agent makes targeted changes, runs tests, and opens a PR. The orchestrator tracks completion via a PR-sentinel protocol.

## What Claude Gets Wrong Without This Skill

Without batch, parallelizable work runs sequentially. A task that 10 agents could complete in parallel takes 10x longer. Sequential execution also forces agents to share context, introducing noise from earlier subtasks into later ones.

Batch gives each unit a clean slate (isolated worktree) and a clear contract (self-contained prompt + PR sentinel).

## Work Unit Decomposition Rules

Before spawning any worker, decompose the full task into units that satisfy all of the following:

1. **Independently implementable** — the unit can be completed without knowing the result of any sibling unit
2. **Independently mergeable** — the unit's PR does not depend on another unit's PR being merged first
3. **Roughly uniform size** — similar effort per unit (prevents one unit blocking the whole batch)
4. **5–30 units** — fewer than 5 is not worth the coordination overhead; more than 30 and coordination cost dominates

If you cannot satisfy rule 1 or 2 for a unit, it is not parallelizable. Add it to a dependency chain instead.

## E2E Test Recipe

Write a concrete, executable test recipe that every worker must run:

```
E2E Test Recipe:
  Command: [exact command to run]
  Expected: [expected output or exit code]
  Scope: [what this verifies — e.g., "auth flow", "all unit tests", "API endpoint"]
```

The recipe must be runnable from the worktree root without setup beyond `git clone`.

## Worker Spawn (Single Message Block)

Spawn all workers in one response — this is critical for true parallelism.

Each worker must receive:
```
isolation: "worktree"
run_in_background: true
subagent_type: "general-purpose"
```

And a fully self-contained prompt. The prompt must never say "based on the coordinator's findings" or reference the coordinator's conversation — the worker has no access to it.

### Worker Prompt Template

```
You are implementing [unit name] as part of [mission name].

## Your Task
[Specific, concrete description of what to implement. Include file paths, function names,
line numbers. Do not say "implement the feature" — say exactly what to do.]

## Codebase Context
[Relevant facts the worker needs: architecture, key files, conventions.
Do not assume the worker has any prior context.]

## E2E Test Recipe
[Copy the e2e recipe exactly — worker must run it before creating the PR]

## Done Condition
[Binary condition: "unit tests pass AND e2e returns 200"]

## Reporting
When complete, your final line must be exactly one of:
  PR: <url>              (success — link to opened PR)
  PR: none — <reason>   (could not open PR — explain why)
```

## PR Sentinel Protocol

The `PR: <url>` sentinel is the fan-in mechanism. No shared database, no callbacks — each worker ends its output with this line and the orchestrator parses it.

Parse rules:
- `PR: https://github.com/...` → success, extract URL, mark unit done
- `PR: none — <reason>` → failure, log reason, consider continuing that worker
- Missing sentinel → worker may still be running, or failed without reporting

## Status Table Format

Render and update as notifications arrive:

```
Batch Status — [mission name]

| Unit | Status | PR |
|------|--------|----|
| unit-1-auth | done | #142 |
| unit-2-logging | running | — |
| unit-3-tests | failed | none — test suite not found |
| unit-4-docs | done | #143 |

Progress: 2/4 complete, 1 failed, 1 running
```

## Worker Recovery

If a worker reports failure:
1. **Continue the same worker** (it has the error context): `SendMessage` with corrected instructions
2. If correction fails twice: mark as failed, document the blocker in the final summary
3. Never spawn a fresh worker to fix a failure from another worker (no shared context)

## Pre-PR Checklist (Embedded in Worker Prompt)

Every worker prompt must include these steps before creating the PR:

```
Before creating the PR:
1. Run Skill: simplify (parallel code review — do not skip)
2. Run the unit test suite
3. Run the e2e test recipe
4. Commit all changes with: feat: [unit name] — [one line description]
5. Push branch and create PR with: gh pr create --title "[unit name]" --body "..."
6. End your response with: PR: <url>
```

## Anti-Patterns

Do not spawn workers before plan approval. The decomposition must be reviewed.

Do not write worker prompts that reference the coordinator or other workers. Each prompt must stand alone.

Do not wait for all workers to finish before updating the status table. Update as each notification arrives.

Do not spawn more than 30 workers. Beyond that, use multiple batch rounds.

Do not use batch for sequential tasks (where unit B depends on unit A completing). Use loop-operator instead.

## Mandatory Checklist

1. Verify each unit satisfies all 4 decomposition rules before spawning
2. Verify e2e test recipe is concrete and executable (not "run the tests")
3. Verify plan was presented and explicitly approved before any spawning
4. Verify all workers were spawned in a single message block
5. Verify each worker prompt is self-contained (no references to coordinator or siblings)
6. Verify each worker prompt includes the PR sentinel reporting requirement
7. Verify status table is rendered and updated as notifications arrive
8. Verify final summary includes PR count, failure reasons, and any blocked units
