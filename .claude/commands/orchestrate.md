---
name: orchestrate
description: Named multi-agent workflow chaining with predefined pipelines
---

Invoke the orchestrate protocol now. Execute a named multi-agent workflow with handoff documents between agents.

## Invocation

```
/orchestrate feature <feature-name>    # Full feature pipeline
/orchestrate bugfix <issue-id>         # Bug fix pipeline  
/orchestrate refactor <component>      # Refactoring pipeline
/orchestrate security <scope>          # Security audit pipeline
```

## Predefined Workflows

### Feature Workflow

**Pipeline**: planner → tdd-guide → code-reviewer → security-reviewer

1. **planner** agent
   - Input: Feature requirements
   - Output: Phased implementation plan with risks
   - Handoff document: `context/plans/<feature-name>-plan.md`

2. **tdd-guide** (or tdd skill)
   - Input: Implementation plan
   - Output: Tests + implementation
   - Handoff document: `context/tdd/<feature-name>-coverage.md`

3. **code-reviewer** agent (parallel with security-reviewer)
   - Input: Implementation code
   - Output: Code quality report
   - Handoff document: `context/reviews/<feature-name>-code-review.md`

4. **security-reviewer** agent (parallel with code-reviewer)
   - Input: Implementation code
   - Output: Security findings
   - Handoff document: `context/reviews/<feature-name>-security.md`

**Gate**: After each stage, report results and wait for user approval to proceed.

### Bugfix Workflow

**Pipeline**: researcher → debug-session → tdd-guide → code-reviewer

1. **researcher** agent
   - Input: Bug description + reproduction steps
   - Output: Root cause analysis
   - Handoff document: `context/debug/<issue-id>-analysis.md`

2. **debug-session** skill
   - Input: Root cause analysis
   - Output: Hypothesis ranking + discriminating probe
   - Handoff document: `context/debug/<issue-id>-hypothesis.md`

3. **tdd-guide** skill
   - Input: Bug understanding
   - Output: Regression test + fix
   - Handoff document: `context/tdd/<issue-id>-regression-test.md`

4. **code-reviewer** agent
   - Input: Fix implementation
   - Output: Review verdict
   - Handoff document: `context/reviews/<issue-id>-fix-review.md`

**Gate**: After researcher analysis, confirm hypothesis before proceeding to fix.

### Refactor Workflow

**Pipeline**: architect → planner → code-reviewer → verifier

1. **architect** agent
   - Input: Refactoring goal
   - Output: ADR with design rationale
   - Handoff document: `context/decisions/ADR-<number>-<refactor-name>.md`

2. **planner** agent
   - Input: ADR + current architecture
   - Output: Step-by-step refactoring plan
   - Handoff document: `context/plans/<refactor-name>-plan.md`

3. Implementation (main agent)
   - Input: Refactoring plan
   - Output: Refactored code
   - Note: Main agent implements, not subagent

4. **code-reviewer** agent
   - Input: Refactored code
   - Output: Quality review
   - Handoff document: `context/reviews/<refactor-name>-review.md`

5. **verifier** agent
   - Input: Refactoring goal + implementation
   - Output: Acceptance criteria verification
   - Handoff document: `context/reviews/<refactor-name>-verification.md`

**Gate**: After architect produces ADR, confirm design before planning.

### Security Workflow

**Pipeline**: researcher → security-reviewer → code-reviewer → verifier

1. **researcher** agent
   - Input: Security scope (OWASP, STRIDE, supply-chain, etc.)
   - Output: Attack surface analysis
   - Handoff document: `context/security/<scope>-surface.md`

2. **security-reviewer** agent
   - Input: Attack surface + codebase
   - Output: Security findings with severity
   - Handoff document: `context/security/<scope>-findings.md`

3. Fix implementation (main agent)
   - Input: Security findings
   - Output: Remediation code
   - Note: Main agent implements fixes

4. **code-reviewer** agent
   - Input: Remediation code
   - Output: Code quality review
   - Handoff document: `context/reviews/<scope>-remediation-review.md`

5. **verifier** agent
   - Input: Original findings + remediation
   - Output: Verification that findings are resolved
   - Handoff document: `context/security/<scope>-verification.md`

**Gate**: After security findings, prioritize by severity before fixing.

## Handoff Documents

Each agent produces a handoff document that the next agent consumes. Format:

```markdown
# Handoff: <workflow> - <stage>

Agent: <agent-name>
Input: <what it received>
Output: <what it produced>
Status: COMPLETE / BLOCKED / NEEDS_REVISION

## Summary

[Brief summary of stage outcome]

## Details

[Detailed findings, plans, or analysis]

## Next Agent Input

[Exactly what the next agent needs to proceed]
```

## Parallel Execution

When multiple agents can run independently (e.g., code-reviewer + security-reviewer), execute them in parallel:

1. Spawn both agents simultaneously
2. Wait for both to complete
3. Aggregate their handoff documents
4. Present combined results to user

## Important

- Only main agent implements code. Subagents research, plan, and review.
- Gate at every stage boundary. User must approve before proceeding.
- If any stage produces BLOCKED verdict, stop pipeline and surface blocker.
- Write all handoff documents to `context/` subdirectories.
- Clean up old handoff documents after workflow completes successfully.

## Anti-Patterns

**Running without gates**: Do not auto-proceed through stages. User approval required.

**Subagents writing code**: Subagents are read-only or planning-only. Main agent implements.

**Skipping handoff documents**: Every stage must produce a handoff document for the next stage.

**Sequential when parallel is possible**: Code-reviewer and security-reviewer can run in parallel. Don't serialize them.
