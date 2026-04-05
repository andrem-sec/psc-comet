# PSC Scoring Framework

A deployer-configurable scoring layer that sits on top of the PSC health check floors.

## What This Is

The scoring framework lets you track custom quality signals over time -- things the binary floor checks cannot measure, like skill coherence, session protocol adherence, or output consistency.

PSC ships the runner infrastructure. You define the metrics.

## What This Is Not

- Not a replacement for human review
- Not an objective quality measure
- Not a CI gate (use `psc-health-check.sh` for that)

## Setup

1. Copy the template to a private rubric file:
   ```bash
   cp scripts/scoring/rubric-template.yaml scripts/scoring/rubric.yaml
   ```

2. Edit `rubric.yaml`:
   - Replace the example dimension with your own
   - Each dimension needs a `command` that exits 0 on pass, non-0 on fail
   - Adjust `weight` values (they are normalized automatically)
   - Set `acknowledged: true` after reading the risk section

3. Run the scorer:
   ```bash
   bash scripts/scoring/psc-score.sh
   ```

`rubric.yaml` is gitignored by default. Do not commit your metrics.

## Risk: Goodhart's Law

Automated scoring optimizes what you measure. Once a metric becomes a target, it stops being a good measure. Specific failure modes:

- **Over-fitting**: agents learn to satisfy the metric without improving real behavior
- **Regression masking**: a dimension that consistently passes can hide degradation elsewhere
- **False confidence**: a high score does not mean the harness is working well

**Mitigations built into this framework:**

1. Hard floor failures (`psc-health-check.sh`) always score 0, regardless of rubric output. You cannot route around a failing floor with a high rubric score.
2. `acknowledged: false` blocks scoring from running. You must read and accept the risk before scoring activates.
3. Human review remains mandatory before merge. The score is a signal, not a gate.

## Output

The scorer outputs JSON to stdout:

```json
{
  "floor_pass": true,
  "score": 0.875,
  "dimensions": [
    {
      "name": "my-metric",
      "description": "Checks X",
      "passed": true,
      "score": 1.0,
      "weight": 1.0
    }
  ]
}
```

If `floor_pass` is false, `score` is always 0.0 regardless of dimension results.

## Designing Good Metrics

A good metric command:
- Is deterministic (same input, same output every run)
- Tests a specific observable behavior, not a proxy
- Exits 0 cleanly on pass, non-0 on fail
- Runs in under 30 seconds

Avoid metrics that test the same thing the floor checks already cover.
