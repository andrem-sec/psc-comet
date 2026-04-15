---
name: eval-harness
description: Eval-driven development with pass@k metrics and three grader types
version: 1.0.0
level: 3
triggers:
  - "/eval"
  - "create eval"
  - "run eval"
  - "eval-driven"
context_files:
  - .claude/evals/*.md
steps:
  - name: Define Eval
    description: Create eval file with test cases and success criteria
  - name: Run Eval
    description: Execute test cases and record results
  - name: Calculate Metrics
    description: Compute pass@1, pass@3, pass^3
  - name: Generate Report
    description: Produce SHIP/NEEDS WORK/BLOCKED verdict
---

# Eval Harness Skill

Eval-driven development: define success criteria before implementation, measure after.

## What Claude Gets Wrong Without This Skill

Without evals, Claude:
1. Optimizes for "looks good" instead of "actually works"
2. Breaks existing functionality without noticing (no regression detection)
3. Cannot distinguish between "works once" and "works reliably"
4. Has no objective quality gate for SHIP decisions

Evals provide the missing feedback loop: concrete, reproducible, pass/fail measurement.

## Before You Define Evals

Run the feature or skill against real inputs first. Do not write test cases from imagination.

1. Run it 10-20 times against realistic inputs -- varied, not cherry-picked
2. Read every output. List what actually failed and why
3. Bucket failures: prompt wording / tool design / model limitation / edge case not handled
4. Write test cases from that list -- one case per observed failure mode

If you have not observed any failures, your eval suite will confirm assumptions instead of catching bugs. Spend 60-80% of eval effort here before touching `/eval define`.

## Two Eval Types

### Capability Evals

**Question**: Can Claude do something new?

**Example**: "Generate valid SQL from natural language queries"

**Success threshold**: pass@3 >= 90%

At least 1 success in 3 attempts. Accounts for variability in LLM outputs while ensuring the capability exists.

**Use case**: New features, new skill additions, prompt engineering experiments.

### Regression Evals

**Question**: Did changes break existing behavior?

**Example**: "User authentication flow completes successfully"

**Success threshold**: pass^3 = 100%

All 3 attempts must pass. Zero tolerance for regressions in release-critical paths.

**Use case**: After refactors, dependency upgrades, bug fixes that touch core paths.

## Three Grader Types

### Code-Based Graders (Deterministic)

Programmatic assertions. Fast, reliable, no LLM overhead.

```python
def grade_sql_generation(output):
    parsed = sqlparse.parse(output)
    return len(parsed) > 0 and parsed[0].get_type() == 'SELECT'
```

**When to use**: Structure validation, format checking, deterministic correctness.

**Anti-pattern**: Using code graders for semantic evaluation ("is this SQL optimal?").

### Model-Based Graders (LLM-as-Judge)

LLM evaluates output quality against rubric.

```
Prompt: "Does the generated SQL correctly answer the question: {question}?
Expected columns: {columns}
Actual SQL: {output}
Answer YES or NO with reasoning."
```

**When to use**: Semantic correctness, intent matching, explanation quality.

**Anti-pattern**: Using model graders without a clear rubric. Leads to flaky, inconsistent grades.

**Grade outcomes, not exact paths.** An agent that reaches the correct result via a different route than expected should pass. Only fail a run when the *outcome* is wrong -- not when the sequence of steps differs. Brittle path-matching produces false failures that corrupt your eval data and make SHIP verdicts untrustworthy.

**Cost awareness**: Model graders consume tokens. For high-volume evals, prefer code-based graders.

### Human Graders (Flagged for Manual Review)

Mark eval for human review when:
- Subjective quality judgment needed
- Model grader confidence is low
- Eval result is surprising (regression where none expected)

**When to use**: UX quality, edge cases, disputed model grades.

**Process**: Flag in eval file, reviewer adds grade + reasoning, update status.

## Metrics Definitions

**pass@1**: Percentage of test cases that pass on first attempt.
- High pass@1 = reliable, consistent capability
- Low pass@1 = flaky, needs improvement

**pass@3**: Percentage of test cases where at least 1 of 3 attempts passes.
- Accounts for LLM variability
- Standard threshold for capability evals: >= 90%

**pass^3**: Percentage of test cases where all 3 attempts pass.
- Zero-tolerance metric
- Standard threshold for regression evals: 100%

## Eval File Structure

Location: `.claude/evals/<feature-name>.md`

```markdown
# Eval: sql-generation

Type: Capability
Created: 2026-03-28T12:00:00Z
Status: Active

## Success Criteria

Generate syntactically valid SELECT queries from natural language.
- Must parse with sqlparse
- Must select from correct table
- Must filter on correct columns

## Test Cases

### Case 1: Simple filter
- Prompt: "Show all users where age > 25"
- Expected: SELECT * FROM users WHERE age > 25
- Grader: code-based (sqlparse + column check)
- Result: [filled during check]

### Case 2: Join query
- Prompt: "Show user names with their order totals"
- Expected: SELECT users.name, SUM(orders.total) FROM users JOIN orders...
- Grader: model-based (semantic correctness)
- Result: [filled during check]

## Metrics

- pass@1: 85%
- pass@3: 95%
- pass^3: 80%

## History

2026-03-28T14:30:00Z | pass@3: 95% | PASS | Ready for release
2026-03-28T12:15:00Z | pass@3: 70% | FAIL | Need more examples
```

## Operations

### /eval define <feature-name>

Create new eval file from template. Prompts for:
- Type (Capability or Regression)
- Success criteria (concrete, measurable)
- Initial test cases (minimum 3, all manually verified)

**Dataset quality over quantity.** Verify every test case manually before adding it -- read the input, trace the expected output yourself, confirm the grader logic is correct. 10 cases you have personally validated outperform 100 synthetic ones you have not checked. Unverified cases corrupt pass rates and make SHIP verdicts meaningless.

### /eval check <feature-name>

Run the evaluation:
1. Read eval file
2. Execute each test case 3 times
3. Grade each attempt with specified grader
4. Calculate pass@1, pass@3, pass^3
5. Update eval file with results and timestamp
6. Output summary

### /eval report <feature-name>

Analyze results and produce verdict:

**SHIP**: Meets threshold (pass@3 >= 90% for capability, pass^3 = 100% for regression)

**NEEDS WORK**: Some cases passing but below threshold. List specific failing cases.

**BLOCKED**: Critical failures or <50% pass rate. Requires investigation.

### /eval list

Show all evals in `.claude/evals/` with:
- Name
- Type (Capability/Regression)
- Status (Active/Passing/Failing/Archived)
- Latest pass@3 percentage
- Last run timestamp

### /eval clean

Archive old eval runs:
- Keep last 10 runs per feature
- Move older runs to `.claude/evals/archive/<feature-name>/`
- Preserve summary stats in main eval file

## Anti-Patterns

**Overfitting prompts to eval examples**: Evals should represent real usage, not cherry-picked cases.

**Measuring only happy paths**: Include edge cases, error conditions, malformed inputs.

**Ignoring cost/latency drift**: Track token usage and response time. A 10x slower solution that passes evals is not shippable.

**Flaky graders in release gates**: If a model grader produces inconsistent results across runs, switch to code-based or human grader.

**No baseline**: Run evals before starting work. Prevents false regressions and establishes starting point.

## Integration with Development Workflow

1. **Before starting**: Define evals with `/eval define`
2. **During development**: Run `/eval check` to measure progress
3. **Before PR**: Run `/eval report` for SHIP verdict
4. **After merge**: Archive old runs with `/eval clean`

Evals are living documents. Update test cases when requirements change.

## Mandatory Checklist

1. Verify eval type (Capability or Regression) matches the use case
2. Verify success criteria are concrete and measurable, not subjective
3. Verify grader type is appropriate (code-based for deterministic, model-based for semantic)
4. Verify pass@k thresholds match eval type (90% for capability, 100% for regression)
5. Verify test cases include edge cases and error conditions, not just happy paths
6. Verify metrics (pass@1, pass@3, pass^3) are all calculated and reported
7. Verify eval file is updated with results and timestamp after each run
8. Verify /eval report verdict matches the calculated metrics
