---
name: canary
description: Post-deploy production monitoring — watches live app for errors, regressions, and failures after deployment
version: 0.1.0
level: 2
triggers:
  - "canary"
  - "watch production"
  - "post-deploy monitoring"
  - "/canary"
  - "monitor after deploy"
context_files:
  - context/project.md
steps:
  - name: Baseline Load
    description: Load prior baseline if available; capture pre-monitoring snapshot if not
  - name: Page Discovery
    description: Use --pages list or monitor root URL and note limitation
  - name: Monitoring Loop
    description: Check each page every 60 seconds; alert only after 2 consecutive failures to suppress noise
  - name: Health Report
    description: Produce structured report with alerts, baseline deltas, and STABLE/DEGRADED/CRITICAL verdict
  - name: Baseline Update
    description: Offer to update baseline after a STABLE run
---

# Canary Skill

Post-deploy production monitoring. Run after deployment, not before. Watches live pages at 60-second intervals, filters out single-check noise, and surfaces only confirmed anomalies. Think of it as a canary in a coal mine: its job is to catch the signal before it becomes an incident.

## What Claude Gets Wrong Without This Skill

Without a monitoring protocol, post-deploy checks are manual spot-checks: someone opens the app, clicks around, and declares it working. This misses intermittent failures, gradual degradation, and regression in non-primary routes.

The other failure mode is alert fatigue from a single failing check. A single 502 in a monitoring loop can be a transient infrastructure hiccup, not a deployment regression. Alerting on single failures trains people to ignore alerts. The two-consecutive-check rule separates signal from noise.

## Invocation

```
/canary <url>                         # Monitor for 10 minutes (default)
/canary <url> --baseline              # Capture baseline before deploying
/canary <url> --duration 5m           # Custom monitoring duration
/canary <url> --pages /,/dash,/login  # Monitor specific routes
/canary <url> --quick                 # Single health check, no loop
```

## Phase 1: Baseline

If a baseline exists at `context/canary/<url-slug>-baseline.json`: load it as the comparison reference.

If `--baseline` is passed: capture current state as baseline and exit. Do not start the monitoring loop.

If no baseline and no `--baseline` flag: capture a pre-monitoring snapshot as the session reference. This is not a persistent baseline: it allows intra-session deltas to be reported.

## Phase 2: Page Discovery

Use the `--pages` list if provided. Otherwise monitor the root URL only and note: "Pass --pages to monitor additional routes." Do not guess which routes matter.

## Phase 3: Monitoring Loop

Check each page every 60 seconds for the specified duration. Per check:

```bash
curl -o /dev/null -s -w "%{http_code}|%{time_starttransfer}|%{time_total}" <url>
```

Alert levels:

| Level | Condition |
|-------|-----------|
| CRITICAL | HTTP 5xx, timeout, or connection refused |
| HIGH | HTTP 4xx on a page that was previously 2xx |
| MEDIUM | TTFB more than 2x the baseline value |
| LOW | HTTP 404 on a resource that was previously reachable |

**Alert only after the condition persists across 2 consecutive checks.** A single failure is noise. Two in a row is signal.

On CRITICAL: surface immediately, do not wait for the duration to end.

## Phase 4: Health Report

```
## Canary Report: <url>
Duration monitored: [time]
Pages: [list]
Checks run: [count]

### Alerts
Level: CRITICAL | HIGH | MEDIUM | LOW
Page: [url]
Condition: [what was detected]
First seen: [timestamp]
Confirmed: YES (2+ checks) | UNCONFIRMED (1 check)

### Baseline deltas
[Metric] before: [value] / after: [value] / delta: [%]

### Verdict: STABLE | DEGRADED | CRITICAL
```

STABLE: no confirmed alerts, all metrics within baseline tolerance.
DEGRADED: one or more MEDIUM or LOW confirmed alerts.
CRITICAL: any CRITICAL or HIGH confirmed alert.

## Phase 5: Baseline Update

After a STABLE run, ask the user: "The deployment is stable. Do you want to update the baseline to the current measurements?"

Do not update the baseline automatically. Always ask.

## Anti-Patterns

Do not run canary before deployment. It monitors what is live, not what is staged.

Do not alert on single-check failures. Alert only after two consecutive failures on the same page.

Do not declare STABLE after a --quick single check. A single check detects a hard failure but cannot confirm stability over time.

Do not update the baseline without asking. A STABLE baseline is a deliberate record, not an automatic snapshot.

## Mandatory Checklist

1. Verify baseline was loaded or a session reference was captured before the loop started
2. Verify monitoring loop ran at 60-second intervals for the specified duration
3. Verify alerts were only issued after 2 consecutive failures on the same page
4. Verify CRITICAL alerts were surfaced immediately without waiting for duration to end
5. Verify the health report includes all four sections: alerts, baseline deltas, checks run, verdict
6. Verify the baseline update was offered (not applied automatically) after a STABLE verdict
7. Verify each run was saved to context/canary/[url-slug]-[date]-[time].json
