---
name: eval
description: Evaluation management for features and regressions
---

Invoke the eval management protocol now.

## Invocation

```
/eval define <feature-name>     # Create new evaluation file
/eval check <feature-name>      # Run evaluation and record results
/eval report <feature-name>     # Analyze and produce SHIP/NEEDS WORK/BLOCKED verdict
/eval list                      # Show all evaluations with status
/eval clean                     # Archive old eval runs (keep last 10)
```

## Operations

### /eval define <feature-name>

Create a new evaluation file at `.claude/evals/<feature-name>.md` with template structure:

```markdown
# Eval: <feature-name>

Type: [Capability | Regression]
Created: [ISO 8601]
Status: [Active | Passing | Failing | Archived]

## Success Criteria

[Concrete, measurable criteria for PASS]

## Test Cases

### Case 1: [description]
- Setup: [preconditions]
- Action: [what to do]
- Expected: [expected result]
- Actual: [filled during check]
- Result: [PASS/FAIL]

[Additional cases...]

## Metrics

- pass@1: [% of single-attempt passes]
- pass@3: [% where at least 1 of 3 attempts passes]
- pass^3: [% where all 3 attempts pass]

## History

[Run log with timestamps and results]
```

### /eval check <feature-name>

Run the evaluation and record results:
1. Execute each test case
2. Record PASS/FAIL for each
3. Calculate pass@1 (did it work on first try?)
4. Update the eval file with results and timestamp
5. Output summary verdict

### /eval report <feature-name>

Analyze the evaluation and provide recommendation:
- **SHIP**: pass@3 >= 90% for capability evals, pass^3 = 100% for regression evals
- **NEEDS WORK**: Some cases passing but below threshold
- **BLOCKED**: Critical failures or <50% pass rate

### /eval list

Show all evaluations in `.claude/evals/` with current status, type, and latest pass rate.

### /eval clean

Retain last 10 eval runs per feature, archive older results to `.claude/evals/archive/`.

## Eval Types

**Capability**: Can Claude do something new? (e.g., "generate SQL from natural language")
- Threshold: pass@3 >= 90% (at least 1 success in 3 attempts)

**Regression**: Did changes break existing behavior? (e.g., "auth flow still works")
- Threshold: pass^3 = 100% (all 3 attempts must pass)

## Metrics Definitions

- **pass@1**: Percentage of test cases that pass on the first attempt
- **pass@3**: Percentage of test cases where at least 1 of 3 attempts passes
- **pass^3**: Percentage of test cases where all 3 attempts pass

## Important

- Evaluations are stored in `.claude/evals/` (create directory if needed)
- Each eval is a standalone .md file
- History section grows with each /eval check run
- Archive old runs to prevent file bloat
