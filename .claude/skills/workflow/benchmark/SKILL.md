---
name: benchmark
description: Performance measurement with Core Web Vitals thresholds — baseline capture, regression detection, optional PageSpeed Insights
version: 0.1.0
level: 2
triggers:
  - "benchmark"
  - "is it fast enough"
  - "performance check"
  - "/benchmark"
  - "check performance regression"
context_files:
  - context/project.md
steps:
  - name: Curl Measurement
    description: Phase 1: run 3-pass curl timing per page, report median TTFB and total load time
  - name: PageSpeed Insights
    description: Phase 2: if GOOGLE_API_KEY is set, fetch real-user p75 field data; otherwise skip and note what is unavailable
  - name: Baseline Comparison
    description: Phase 3: compare against saved baseline if present; apply regression and warning thresholds
  - name: Output and Snapshot
    description: Per-page verdicts with deltas, final PASS/WARNING/REGRESSION, save snapshot to context/benchmarks/
---

# Benchmark Skill

Performance measurement with hardcoded Core Web Vitals thresholds, 3-pass median reporting, and regression detection against a saved baseline. Measure, do not guess. Think of a baseline as a before photo: without it, you cannot tell whether the change made things better, worse, or did nothing.

## What Claude Gets Wrong Without This Skill

Without a protocol, performance "checks" produce a single data point with no comparison context. One curl request is not a measurement: it is a sample. One sample is dominated by network variance, server cold starts, and caching state. A 3-pass median is a measurement.

The other failure mode is missing the baseline: making a change, running a check, seeing numbers, and having no reference to know whether those numbers are a regression.

## Invocation

```
/benchmark <url>                    # Full audit with baseline comparison
/benchmark <url> --baseline         # Capture baseline before making changes
/benchmark <url> --quick            # Single-pass timing, no baseline
/benchmark <url> --pages /,/dash    # Specify multiple pages
/benchmark --diff                   # Pages touched by current branch only
/benchmark --trend                  # Show historical trend from saved snapshots
```

## Core Web Vitals Thresholds (Hardcoded)

| Metric | Good | Needs Work | Poor |
|--------|------|-----------|------|
| TTFB (Time to First Byte) | < 800ms | 800ms-1.8s | > 1.8s |
| FCP (First Contentful Paint) | < 1.8s | 1.8-3s | > 3s |
| LCP (Largest Contentful Paint) | < 2.5s | 2.5-4s | > 4s |

These thresholds are not configurable. They are the Google CWV standard.

## Regression Thresholds

| Signal | Timing | Bundle Size |
|--------|--------|------------|
| REGRESSION | > 50% increase OR > 500ms absolute | > 25% increase |
| WARNING | > 20% increase | > 10% increase |

## Phase 1: Curl Measurement (Always Runs)

For each target page, run 3 passes and report the median:

```bash
curl -o /dev/null -s -w "TTFB:%{time_starttransfer} Total:%{time_total} Size:%{size_download}" <url>
```

Collect: TTFB, total load time, response size. Use `--quick` for a single pass when a rough number is sufficient and speed matters more than precision.

## Phase 2: PageSpeed Insights (Optional Enhancement)

If `GOOGLE_API_KEY` is set:

```bash
curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=<url>&strategy=mobile&key=$GOOGLE_API_KEY"
```

Extract: LCP, FCP, TTFB real-user p75 field data and Lighthouse lab scores.

If `GOOGLE_API_KEY` is not set: skip this phase. Report: "Field data unavailable: set GOOGLE_API_KEY for real-user metrics." Do not fail or warn: this is an optional enrichment, not a requirement.

## Phase 3: Baseline Comparison

If a baseline exists at `context/benchmarks/<url-slug>-baseline.json`:
- Compare each metric against baseline values
- Apply regression and warning thresholds
- Report delta as both absolute value and percentage

If no baseline exists and `--baseline` was not passed:
- Report absolute values against CWV thresholds only
- Note: "No baseline captured: run `/benchmark <url> --baseline` before making changes to enable regression detection."

When `--baseline` is passed: capture the current measurements as the baseline and save to `context/benchmarks/<url-slug>-baseline.json`. Do not run a comparison: you are establishing the reference point.

## Output Format

```
## Benchmark: <url>
Date: [date]
Pages tested: [list]

### <page>
TTFB:  [value] ([delta vs baseline if available]): [GOOD | NEEDS WORK | POOR]
FCP:   [value if available]                       : [GOOD | NEEDS WORK | POOR]
LCP:   [value if available]                       : [GOOD | NEEDS WORK | POOR]
Size:  [bytes] ([delta])

Verdict: PASS | WARNING | REGRESSION

[If regression]: Slowest resource: [resource] at [time]ms
[If PSI available]: Real-user p75 LCP: [value]: [GOOD | NEEDS WORK | POOR]
```

Final verdict across all pages: PASS | WARNING | REGRESSION

## Snapshot

Save each run to `context/benchmarks/[url-slug]-[date].json`. Baseline snapshots save to `context/benchmarks/[url-slug]-baseline.json` on `--baseline` runs. The `--trend` flag reads all saved snapshots for a URL and reports directional movement.

## Anti-Patterns

Do not report a single curl pass as a benchmark. Single-pass numbers are dominated by variance. Run 3 passes and report the median.

Do not treat WARNING as PASS. A 20% regression in TTFB is a signal worth investigating before deploying.

Do not skip capturing a baseline before making changes. A regression you cannot prove is a regression you cannot fix with confidence.

Do not fail the run because GOOGLE_API_KEY is not set. Field data is an enrichment, not a requirement.

## Mandatory Checklist

1. Verify 3 passes were run per page and the median was reported (unless --quick was used)
2. Verify CWV thresholds were applied to all available metrics
3. Verify baseline comparison ran if a baseline file exists
4. Verify PageSpeed Insights phase was either run (if key present) or explicitly noted as unavailable
5. Verify regression and warning thresholds were applied to all deltas
6. Verify the final verdict across all pages was reported
7. Verify results were saved to context/benchmarks/[url-slug]-[date].json
