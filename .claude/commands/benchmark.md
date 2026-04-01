---
name: benchmark
description: Performance measurement with Core Web Vitals thresholds — baseline capture, regression detection, optional PageSpeed Insights
---

Invoke the benchmark protocol now. Measure, do not guess.

## Invocation

```
/benchmark <url>                    # Full audit with baseline comparison
/benchmark <url> --baseline         # Capture baseline before making changes
/benchmark <url> --quick            # Single-pass timing, no baseline needed
/benchmark <url> --pages /,/dash    # Specify pages to test
/benchmark --diff                   # Benchmark only pages touched by current branch
/benchmark --trend                  # Show historical trend from saved snapshots
```

## Core Web Vitals thresholds (hardcoded)

| Metric | Good | Needs Work | Poor |
|--------|------|------------|------|
| LCP (Largest Contentful Paint) | < 2.5s | 2.5–4s | > 4s |
| FCP (First Contentful Paint) | < 1.8s | 1.8–3s | > 3s |
| TTFB (Time to First Byte) | < 800ms | 800ms–1.8s | > 1.8s |

## Regression thresholds

- Timing: > 50% increase OR > 500ms absolute = REGRESSION
- Timing: > 20% increase = WARNING
- Bundle size: > 25% increase = REGRESSION
- Bundle size: > 10% increase = WARNING

## Phase 1 — Curl-based measurement (always runs)

Run for each target page:

```bash
# TTFB and total load time
curl -o /dev/null -s -w "TTFB:%{time_starttransfer} Total:%{time_total} Size:%{size_download}" <url>

# Run 3 times, report median
```

Collect: TTFB, total load time, response size. Run 3 passes per URL and report the median. Single-pass for `--quick`.

## Phase 2 — PageSpeed Insights (optional enhancement)

If `GOOGLE_API_KEY` is set in the environment:

```bash
curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=<url>&strategy=mobile&key=$GOOGLE_API_KEY"
```

Extract from response: LCP, FCP, TTFB field data (real-user p75 values), Lighthouse lab scores.

If `GOOGLE_API_KEY` is not set: skip this phase, note it in output as "Field data unavailable — set GOOGLE_API_KEY for real-user metrics."

## Phase 3 — Baseline comparison

If a baseline exists in `context/benchmarks/<url-slug>-baseline.json`:
- Compare each metric against baseline
- Apply regression and warning thresholds
- Report delta as absolute value and percentage

If no baseline exists and `--baseline` was not passed: report absolute values against CWV thresholds only, note "No baseline captured — run `/benchmark <url> --baseline` before making changes."

## Output format

```
## Benchmark: <url>
Date: [date]
Pages tested: [list]

### <page>
TTFB:  [value] ([delta vs baseline]) — [GOOD | NEEDS WORK | POOR]
FCP:   [value if available]          — [GOOD | NEEDS WORK | POOR]
LCP:   [value if available]          — [GOOD | NEEDS WORK | POOR]
Size:  [bytes]  ([delta])

Verdict: PASS | WARNING | REGRESSION

[If regression]: Slowest resource: [resource] at [time]ms
[If PSI available]: Real-user p75 LCP: [value] — [GOOD | NEEDS WORK | POOR]
```

Final verdict across all pages: PASS | WARNING | REGRESSION

## Snapshot

Save results to `context/benchmarks/[url-slug]-[date].json`. Baseline saved to `context/benchmarks/[url-slug]-baseline.json` when `--baseline` is passed.
