---
name: agent-harness-construction
description: Framework for designing quality agents with proper action space and contracts
version: 0.1.0
level: 3
triggers:
  - "design an agent"
  - "agent quality framework"
  - "harness construction"
  - "agent architecture"
context_files:
  - context/project.md
  - context/decisions.md
steps:
  - name: Define Action Space
    description: Specify granularity and tool allowlist
  - name: Establish Observation Contract
    description: Define required fields in tool responses
  - name: Design Recovery Contract
    description: Specify error handling and retry logic
  - name: Budget Context
    description: Calculate context costs and set limits
  - name: Select Architecture Pattern
    description: Choose ReAct, function-calling, or Hybrid
  - name: Define Success Metrics
    description: Track completion rate, retries, pass@k, cost per task
---

# Agent Harness Construction Skill

Framework for designing quality agents. Defines contracts, budgets, and measurement before implementation.

## What Claude Gets Wrong Without This Skill

Without systematic agent design, agents:
1. Have unclear tool boundaries (too permissive or too restrictive)
2. Return inconsistent response formats (breaks downstream parsing)
3. Fail silently on errors (no recovery strategy)
4. Consume unbounded context (budget overruns)
5. Lack measurable success criteria (can't tell if agent is improving)

Agent harness construction ensures agents are well-specified before deployment.

## Four Quality Dimensions

### 1. Action Space

**Defines:** What tools can this agent use? At what granularity?

**Granularity:** Micro (single file/command, high-risk), Medium (edit/read loops, standard dev), Macro (Task/orchestration, complex workflows).

**Tool Allowlist Pattern:**
```yaml
tools:
  - Read
  - Grep
  - Glob
disallowedTools:
  - Write
  - Edit
  - Bash
```

**Rule:** Start restrictive, expand only when justified. Removing permissions later breaks existing workflows.

### 2. Observation Contract

**Defines:** What fields must every tool response include?

**Required Fields:**
- `status`: SUCCESS | PARTIAL | FAILURE
- `summary`: One-line description of what happened
- `next_actions`: Array of suggested follow-ups
- `artifacts`: Paths to files created/modified

**Why:** Enables reliable parsing, orchestrator coordination, and chaining without re-planning. Anti-pattern: raw output with no structure.

### 3. Recovery Contract

**Defines:** How does agent handle errors?

**Strategies:** Retry with backoff (transient errors, max 3), escalate to human (ambiguous/security, max 2 auto-attempts), graceful degradation (optional features unavailable), circuit breaker (3 identical failures = stop).

**Recovery Contract Template:**
```yaml
recovery:
  transient_errors:
    max_retries: 3
    backoff: [1, 5, 15]
  ambiguous_errors:
    escalate_after: 2
  circuit_breaker:
    identical_failures: 3
```

### 4. Context Budget

**Defines:** Maximum tokens this agent can consume.

**Budget Calculation:**

**Agent prompt:** ~2,000 tokens (instructions, examples)
**Tools:** ~500 tokens per tool schema × N tools
**Working context:** File reads, conversation history
**Output:** Agent responses

**Example:**
- Agent with 10 tools: 2,000 + (500 × 10) + working = 7,000 base tokens
- 50 turns × 500 tokens/turn = 25,000 tokens working context
- Total: 32,000 tokens (~$0.10 per agent session at Sonnet pricing)

**Budget Limits:**

| Agent Type | Token Budget | Use Case |
|------------|--------------|----------|
| Micro (researcher) | 10K-20K | Quick searches, single-file analysis |
| Standard (planner, code-reviewer) | 20K-50K | Multi-file review, planning |
| Complex (orchestrator, architect) | 50K-100K | System-wide analysis, coordination |

**If budget exceeded:**
- Compact mid-session (strategic-compact skill)
- Split into multiple agents (orchestrator pattern)
- Reduce tool schema size (use macro-tools)

## Three Architecture Patterns

### ReAct (Reasoning and Acting)
**Best For:** Exploratory tasks, unclear solution paths, research

**Pattern:**
1. Reason: "I need to find the authentication logic"
2. Act: Grep for "auth" across codebase
3. Observe: Found in src/auth.ts
4. Reason: "Now I should read that file"
5. Act: Read src/auth.ts
...

**Pros:** Flexible, handles ambiguity, self-correcting
**Cons:** Higher token cost (reasoning overhead), slower

### Function-Calling (Structured Deterministic)
**Best For:** Well-defined tasks, repetitive operations, production workloads

**Pattern:**
1. User: "Add user validation"
2. Agent: [calls validate_user_input(field="email")]
3. System: Returns validation code
4. Done

**Pros:** Fast, predictable, low token cost
**Cons:** Rigid, fails on ambiguous inputs

### Hybrid (ReAct Planning + Function Execution)
**Best For:** Most agent tasks (recommended default)

**Pattern:**
1. Reason (ReAct): "Task requires editing 3 files in sequence"
2. Plan: [edit_file("a.ts"), edit_file("b.ts"), edit_file("c.ts")]
3. Execute (Function-Calling): Run plan with typed tool calls
4. Observe: All edits succeeded
5. Reason: Verify tests pass
6. Execute: run_tests()

**Pros:** Flexible planning, efficient execution
**Cons:** Slightly higher complexity

## Success Metrics

Track these metrics for every agent:

**Completion Rate:**
- Tasks completed successfully / tasks attempted
- Target: ≥85% for production agents

**Retries Per Task:**
- Average retry attempts before success
- Target: ≤1.5 retries per task

**pass@1 / pass@3:**
- pass@1: Success on first attempt
- pass@3: Success in at least one of three attempts
- Targets: pass@1 ≥70%, pass@3 ≥90%

**Cost Per Successful Task:**
- Total tokens consumed / successful completions
- Track over time to detect regressions

**Example Metrics Dashboard:**
```
Agent: code-reviewer
Period: Last 30 days
Completion Rate: 88% (44/50 tasks)
Retries Per Task: 1.2
pass@1: 72%
pass@3: 92%
Cost Per Task: $0.08 avg
```

## Anti-Patterns

**Overpowered agents**: Agent has Write, Edit, Bash, Task access when it only needs Read + Grep. Start restrictive.

**No observation contract**: Tool responses are raw text. Downstream parsing is brittle and breaks on edge cases.

**Unlimited retries**: Agent retries failed operation 20 times. Use circuit breaker (3 identical failures = stop).

**No context budget**: Agent consumes 200K tokens on simple task. Budget forces efficiency.

**Missing metrics**: Can't tell if agent is improving or degrading over time. Track pass@1, cost, completion rate.

## Mandatory Checklist

1. Verify action space defined with tool allowlist and granularity specified
2. Verify observation contract includes status, summary, next_actions, artifacts fields
3. Verify recovery contract specifies retry strategy, escalation conditions, circuit breaker threshold
4. Verify context budget calculated (agent prompt + tools + working context) and limits set
5. Verify architecture pattern selected (ReAct, function-calling, or Hybrid) with justification
6. Verify success metrics defined (completion rate, retries, pass@k, cost)
7. Verify metrics tracked over time to detect regressions
8. Verify circuit breaker configured (3 identical failures recommended)
