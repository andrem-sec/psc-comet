---
name: agentic-engineering
description: Framework for decomposing agent-driven tasks into independently verifiable units
version: 0.1.0
level: 3
triggers:
  - "decompose this task"
  - "break down the work"
  - "agent workflow"
  - "how should i approach this"
context_files:
  - context/project.md
  - context/learnings.md
steps:
  - name: Task Decomposition
    description: Break task into 15-minute independently verifiable units
  - name: Eval Definition
    description: Define success criteria and evaluation for each unit
  - name: Model Selection
    description: Route units to appropriate model (Haiku/Sonnet/Opus)
  - name: Execution Planning
    description: Determine session strategy and compaction boundaries
  - name: Risk Identification
    description: Identify dominant risk for each unit
  - name: Done Condition Specification
    description: Define clear completion criteria per unit
---

# Agentic Engineering Skill

Framework for decomposing agent-driven tasks into manageable, verifiable units with appropriate model routing.

## What Claude Gets Wrong Without This Skill

Without systematic task decomposition, Claude:
1. Attempts monolithic implementations that exceed context windows
2. Uses expensive models (Opus) for tasks that Haiku could handle
3. Doesn't define success criteria before starting work
4. Fails to identify the dominant risk per unit, leading to incorrect prioritization
5. Continues working past natural checkpoints, compounding errors

Agentic engineering ensures tasks are right-sized, model-routed correctly, and verifiably complete.

## The 15-Minute Unit Rule

Each work unit should be **independently verifiable in 15 minutes or less**.

**What "unit" means:**
- Single function implementation with tests
- One bug investigation with root cause identified
- One API integration with working example
- One configuration change with verification
- One documentation section written and reviewed

**Why 15 minutes:**
- Short enough to maintain focus
- Long enough to produce meaningful output
- Verifiable without full system context
- If it fails, revert cost is low

**How to verify:**
- Unit tests pass (code implementation)
- Bug reproduces, then doesn't (bug fix)
- Integration returns expected response (API work)
- Config change produces measurable effect (configuration)
- Documentation is accurate and complete (docs)

**If a unit takes longer than 15 minutes:**
- It contains multiple units (decompose further)
- OR the done condition is unclear (tighten specification)
- OR eval is too complex (simplify success criteria)

## Eval-First Loop

**Never start implementation without defining the eval first.**

### The 4-Step Loop

**1. Define Eval**
- What does success look like for this unit?
- Write the test, assertion, or verification command
- Specify passing threshold (100% for gate tests, 90% for periodic)

**2. Run Baseline**
- Execute the eval before implementation
- Expected result: FAIL (if implementing new feature) or PASS (if fixing regression)
- If baseline doesn't match expectation, eval is wrong

**3. Implement**
- Write the minimal code to pass the eval
- Do not add features beyond the eval scope
- Stay within the 15-minute unit boundary

**4. Re-Run Eval**
- Execute the eval after implementation
- Expected result: PASS
- If still failing: debug, fix, re-run (max 3 attempts before checkpointing)

### Eval Types by Unit

| Unit Type | Eval Approach | Example |
|-----------|---------------|---------|
| New function | Unit test | `test_calculate_total() asserts result == 42` |
| Bug fix | Regression test | `test_notification_bug() reproduces issue, then passes after fix` |
| API integration | Integration test | `curl -X POST /api/endpoint returns 200 with expected JSON` |
| Configuration | Smoke test | `service starts without errors, logs show new config value` |
| Documentation | Review checklist | Code examples run, terminology is consistent, <2-minute read |

## Model Routing by Task Category

**Use Haiku (fast, cheap) for:**
- Classification tasks: "Is this a bug or feature request?"
- Boilerplate generation: scaffolding, templates, repetitive code
- Narrow edits: changing variable names, updating imports, fixing typos
- Data transformation: parsing JSON, reformatting logs, CSV manipulation
- Simple queries: "What files import this module?"

**Use Sonnet (balanced) for:**
- Feature implementation: new functions, components, modules
- Refactoring: restructuring code while preserving behavior
- Code review: semantic analysis, identifying anti-patterns
- Test generation: writing unit/integration tests
- Bug fixes: debugging with moderate complexity (2-3 file scope)

**Use Opus (powerful, slow) for:**
- Architecture design: system decomposition, ADR generation
- Root cause analysis: complex multi-system bugs
- Multi-file invariants: changes that require coordinated edits across 5+ files
- Optimization: performance analysis and improvement across layers
- Security review: threat modeling, vulnerability analysis

**Cost awareness:**
- Opus costs ~15x Haiku per token
- Sonnet costs ~3x Haiku per token
- Default to Sonnet; escalate to Opus only when needed
- Use Haiku aggressively for preparatory work (classification, data gathering)

**Integration with model-router skill:**
This skill provides task category definitions; model-router handles the actual routing logic. Reference model-router for cost calculation and fallback strategies.

## Session Strategy

### When to Start Fresh Session

**After major phase transitions:**
- Research → Planning: new session for planning agent
- Planning → Implementation: new session for clean implementation start
- Implementation → Review: new session for code-reviewer agent (eliminates author bias)
- Feature complete → Next feature: new session to avoid context contamination

**After context compaction:**
- If you compacted during a phase, consider fresh session
- Compaction loses error traces and alternative approaches
- Fresh session = clean slate for next unit

### When to Continue Existing Session

**During iterative refinement:**
- Debugging within same unit (error traces needed)
- Incremental feature additions to same file
- Test-driven development cycles (Red → Green → Refactor)

**When context is still relevant:**
- Next unit builds directly on previous unit (shared context valuable)
- Working within 15-minute units in same phase
- Error messages from prior attempts inform current approach

### When to Compact

**Compact after milestones:**
- Feature complete and tested
- Bug fixed and regression test passing
- Refactor complete with all tests green
- Documentation written and reviewed

**Do NOT compact during:**
- Active debugging (stack traces and error messages needed)
- Mid-implementation (variable state and partial progress would be lost)
- Trying alternative approaches (context of what failed is critical)

Reference strategic-compact skill for detailed compaction decision guide.

## Dominant Risk Per Unit

Each unit has **one dominant risk**. Identify it explicitly before starting.

**Risk categories:**

**Correctness**: Will this produce the right result?
- Mitigation: Strong eval, boundary testing, edge cases

**Performance**: Will this be fast enough?
- Mitigation: Benchmark baseline, profile after implementation

**Security**: Could this introduce a vulnerability?
- Mitigation: Input validation, security-reviewer agent, OWASP check

**Integration**: Will this work with existing systems?
- Mitigation: Integration test, smoke test in staging

**Maintainability**: Can future developers understand this?
- Mitigation: Code review, documentation, naming clarity

**If you identify 2+ dominant risks, the unit is too large.** Split into smaller units, each with a single dominant risk.

## Done Condition Specification

Every unit must have a **clear, binary done condition**.

**Good done conditions:**
- "Unit test passes"
- "API returns 200 with expected JSON shape"
- "Bug no longer reproduces in test case"
- "Coverage increased from 78% to 82%"
- "Documentation includes working code example"

**Bad done conditions:**
- "Code looks good" (subjective)
- "Mostly working" (incomplete)
- "Ready for review" (review is a separate unit)
- "Feature implemented" (too vague)

**Pattern:** Every done condition should be verifiable by running one command (npm test, curl, coverage check, etc.).

## Tool Parallelism (Free Performance)

Claude Code's tool orchestration engine automatically parallelizes consecutive read-only tool calls (up to 10 concurrent). Write-heavy tools force a serial boundary.

**To get free parallelism: group reads before writes.**

```
Parallel (engine runs concurrently):
  [Read file1] [Grep pattern] [Glob *.sh] [WebSearch topic]

Serial (write forces boundary):
  [Read file1]  ← concurrent batch 1
  [Edit file1]  ← serial
  [Read file2] [Grep pattern]  ← concurrent batch 2
  [Edit file2]  ← serial
```

When designing agent prompts, group all information-gathering steps before any implementation steps. This is not a discipline — it's a scheduling hint the engine uses automatically.

**Implication for multi-step tasks:** Batch all reads in one conceptual block, then all writes. Never interleave reads and writes unless the read depends on a prior write.

## PR Sentinel Protocol (for Parallel Workflows)

When coordinating multiple parallel agents, use a sentinel string as the completion signal instead of a shared database or callback mechanism.

Each agent ends its final message with exactly one of:
```
PR: <url>              (success)
PR: none — <reason>   (could not complete)
RESULT: <json>         (non-PR workflows — domain-specific sentinel)
```

The coordinator parses this sentinel to track completion. No shared state, no callbacks, crash-safe, restartable.

**Rule:** Define the sentinel format in the worker's spawn prompt. Never rely on unstructured output for coordination signals.

## Anti-Patterns

**Skipping eval definition**: Starting without a defined eval leads to scope creep.

**Using Opus for Haiku tasks**: Wastes 15x cost for classification or boilerplate.

**Working in 60-minute units**: Units >15 minutes are unverifiable and compound errors.

**Compacting mid-debugging**: Loses stack traces. Finish debugging first.

**Interleaving reads and writes**: Breaks the engine's parallelism optimization. Group reads first.

**Unstructured completion signals**: Expecting a coordinator to parse free-text output for task status. Use explicit sentinels.

## Mandatory Checklist

1. Verify task decomposed into units, each verifiable in 15 minutes or less
2. Verify each unit has eval defined BEFORE implementation starts
3. Verify baseline eval run and result matches expectation (FAIL for new features, PASS for regressions)
4. Verify model routing matches task category (Haiku for classification/boilerplate, Sonnet for implementation, Opus for architecture)
5. Verify each unit has single dominant risk identified (correctness, performance, security, integration, maintainability)
6. Verify done condition for each unit is binary and verifiable by single command
7. Verify session strategy matches phase (fresh session after major transitions, continue during iterative refinement)
8. Verify compaction only at milestones, not mid-debugging or mid-implementation
