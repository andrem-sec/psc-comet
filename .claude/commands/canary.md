---
name: canary
description: Post-deploy production monitoring — watches live app for errors, regressions, and failures after deployment
---

Invoke the canary monitoring protocol now. Run after deployment, not before.

## Invocation

```
/canary <url>                        # Monitor for 10 minutes (default)
/canary <url> --baseline             # Capture baseline before deploying
/canary <url> --duration 5m          # Custom duration
/canary <url> --pages /,/dash,/login # Specify pages to monitor
/canary <url> --quick                # Single health check, no loop
```

## Phase 1 — Baseline check

If a baseline exists in `context/canary/<url-slug>-baseline.json`: load it for comparison.

If `--baseline` is passed: capture current state as baseline and exit. Do not start monitoring loop.

If no baseline and no `--baseline` flag: capture a pre-monitoring snapshot as the reference point for this session.

## Phase 2 — Page discovery

Use the `--pages` list if provided. Otherwise monitor the root URL only and note: "Pass --pages to monitor additional routes."

## Phase 3 — Monitoring loop

Check each page every 60 seconds for the specified duration. For each check:

```bash
# Response code and TTFB
curl -o /dev/null -s -w "%{http_code}|%{time_starttransfer}|%{time_total}" <url>
```

Evaluate against these alert conditions:

| Level | Condition |
|-------|-----------|
| CRITICAL | HTTP 5xx, timeout, or connection refused |
| HIGH | HTTP 4xx on a page that was previously 2xx |
| MEDIUM | TTFB more than 2x baseline value |
| LOW | HTTP 404 on a resource that was previously reachable |

**Alert only after a condition persists across 2 consecutive checks.** A single failure is noise. Two in a row is signal.

## Phase 4 — Health report

After the monitoring duration ends (or on CRITICAL alert):

```
## Canary Report: <url>
Duration monitored: [time]
Pages: [list]
Checks run: [count]

### Alerts
[For each alert:]
Level: CRITICAL | HIGH | MEDIUM | LOW
Page: [url]
Condition: [what was detected]
First seen: [timestamp]
Confirmed: YES (2+ checks) | UNCONFIRMED (1 check)

### Baseline deltas
[Metric] before: [value] / after: [value] / delta: [%]

### Verdict: STABLE | DEGRADED | CRITICAL
```

On CRITICAL verdict: surface immediately, do not wait for duration to end.

## Phase 5 — Baseline update

After a successful monitoring run with STABLE verdict: ask the user if the baseline should be updated to the current state.

## Snapshot

Save each report to `context/canary/[url-slug]-[date]-[time].json`.
