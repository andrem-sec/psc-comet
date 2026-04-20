---
name: model-router
description: Model selection guidance — match task complexity to model capability
version: 0.1.0
level: 1
triggers:
  - "which model"
  - "model router"
  - "use haiku"
  - "use opus"
  - "cost-sensitive"
context_files: []
steps:
  - name: Classify Task
    description: Identify the task category and complexity
  - name: Apply Routing Rules
    description: Match to model tier using the routing table
  - name: State Recommendation
    description: Name the model and the reason in one line
---

# Model Router Skill

Match the task to the right model. Using Opus on trivial tasks wastes money. Using Haiku on complex reasoning tasks wastes time and produces wrong answers.

## What Claude Gets Wrong Without This Skill

Without routing guidance, every task defaults to the same model regardless of whether it needs that model's capability. The result is either unnecessary cost (heavy model on simple tasks) or degraded quality (light model on complex tasks).

## Routing Table

### Use Haiku (fast, low cost)
- File retrieval and search
- Simple data transformation
- Boilerplate generation
- Lookup and summarization of known content
- Repetitive formatting tasks
- Test data generation
- Simple code scaffolding

### Use Sonnet (balanced — default)
- Most software engineering tasks
- Code review and debugging
- Planning and decomposition
- Multi-step implementation
- Technical writing
- API integration
- Standard refactoring

### Use Opus (deep reasoning, highest capability)
- Architectural decisions with significant tradeoffs
- Complex debugging with multiple interacting causes
- Security audit requiring deep analysis
- Tasks requiring reasoning across very long contexts
- Novel problem solving with no clear precedent
- High-stakes decisions where error is costly
- Cross-domain synthesis
- Agent-type selection and multi-agent workflow design (Opus achieves ~83% vs Sonnet ~72% on tool modality selection -- source: Terminal Agents paper, 2604.00073)

**Pro plan note:** Opus requires Anthropic Max plan. If on Pro plan, Sonnet will still work for agent/tool selection but may default to suboptimal choices. Treat Opus as a soft recommendation, not a hard requirement, for this category.

## Agent-Level Routing

Apply the same logic to agent model selection in frontmatter:

```yaml
model: claude-haiku-4-5-20251001    # retrieval, simple execution
model: claude-sonnet-4-6             # standard work (default)
model: claude-opus-4-6              # deep reasoning, high stakes
```

## Two-Stage Judge Escalation

Before delivering Sonnet output, scan for low-confidence signals. If any are present,
escalate to Opus and re-run the same prompt before delivering:

**Escalation signals:**
- Hedging language ("I think", "probably", "might", "I'm not sure", "it depends")
- Multiple competing answers presented without a clear recommendation
- Output that contradicts known session context or prior decisions
- Explicit uncertainty: "I cannot determine" or "more information needed" on a task that should be answerable

**On escalation:**
1. Re-run with Opus
2. Deliver the Opus output
3. Note the escalation: "Sonnet was uncertain -- Opus used"

Do not escalate on tasks where Sonnet hedging is appropriate (open-ended questions, design tradeoffs with no clear winner). Escalate only when a concrete answer was expected and Sonnet failed to commit.

## Fallback Model Strategy

When a model fails or produces poor output, escalate to the next tier:

**Haiku → Sonnet**: If Haiku produces incorrect or incomplete output
**Sonnet → Opus**: If Sonnet gets stuck or produces low-confidence results
**Opus → Human**: If Opus cannot solve the problem, surface to user

Document the fallback decision:
```
Primary model: Haiku (simple transformation)
Result: Failed - produced malformed JSON
Fallback model: Sonnet
Result: Success
Reason for escalation: Task complexity was misjudged, required parsing ambiguous input
```

This creates a trail showing why model selection changed mid-task.

## 15-Minute Unit Rule (Task Decomposition Guidance)

If a task cannot be completed in 15 minutes, it is not a unit — it is a task list.

**Break it down**:
- Each unit should be independently verifiable (has a clear done condition)
- Each unit should have a single dominant risk (not multiple unknowns)
- Each unit should produce a testable artifact

**Example of bad decomposition**:
- "Implement user authentication" (too large, multiple risks)

**Example of good decomposition**:
- "Create user schema with password_hash field" (15 min, one risk: schema design)
- "Write password hashing function with bcrypt" (15 min, one risk: crypto library)
- "Add login endpoint that validates password" (15 min, one risk: validation logic)
- "Add session token generation" (15 min, one risk: token security)
- "Write integration test for full auth flow" (15 min, one risk: test setup)

**Why 15 minutes**: Matches human attention span, allows frequent checkpoints, makes progress measurable.

**Model routing + 15-min rule**: If a Sonnet task takes >15 minutes, either decompose further OR escalate to Opus.

## Cost Awareness

Running 10 Haiku calls costs roughly the same as 1 Sonnet call. Running 10 Sonnet calls costs roughly the same as 1 Opus call.

For batch operations on simple tasks, always use Haiku. For orchestrator-level decisions in agent teams, consider Opus. For most interactive work, Sonnet is correct.

## Orchestrator-Level Routing (Multi-Agent Workflows)

In multi-agent workflows, model assignment is per agent role, not per session. The session default does not override an agent's role-based assignment.

**Rule:** Assign models in the agent's spawn prompt or YAML frontmatter, not in the orchestrator's session config.

```
Architect agent  → Opus   (even if session default is Sonnet)
Implementer agent → Sonnet
Verifier agent   → Sonnet
Classifier agent → Haiku
```

Reference agentic-engineering skill for the full per-role table and rationale.

## Anti-Patterns

Do not route to Opus because a task feels important. Route to Opus because it requires deep multi-step reasoning that Sonnet demonstrably gets wrong.

Do not route to Haiku because you want to save money on a task where quality matters.

## Mandatory Checklist

1. Verify the task was classified before the model was selected
2. Verify the recommendation names both the model and the reason
3. Verify Opus is not the default recommendation — it should be the exception
4. Verify fallback model is documented if primary model failed
5. Verify tasks >15 minutes are flagged for decomposition or model escalation
