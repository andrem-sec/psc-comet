---
name: retro
description: Engineering retrospective from git history — velocity, quality, patterns, and team breakdown
version: 0.1.0
level: 2
triggers:
  - "retro"
  - "retrospective"
  - "how did the week go"
  - "/retro"
  - "end of sprint review"
context_files:
  - context/project.md
  - context/learnings.md
steps:
  - name: Time Window
    description: Resolve the window from the flag or default to last 7 days; midnight-aligned in local timezone
  - name: Data Collection
    description: Run 14 parallel git queries: commits, LOC, hourly distribution, contributors, test ratio, conventional types, sessions, hotspots, AI-assist count, streaks, focus scores, PR boundaries, TODOS, streak detection
  - name: Analysis
    description: Compute derived metrics: velocity, session depth, quality signals, team breakdown
  - name: Output
    description: Produce 15-section retrospective (2000-4000 words) with tweetable summary through week-over-week trends
  - name: Snapshot
    description: Save JSON snapshot to context/retros/[YYYY-MM-DD].json for trend comparison in future retros
---

# Retro Skill

A data-driven engineering retrospective built entirely from git history. No self-reporting, no surveys: just what the code record actually shows. Think of git history as the project's heartbeat monitor: it does not lie about when work happened, how long sessions ran, or what the fix-to-feature ratio looked like.

## What Claude Gets Wrong Without This Skill

Without a protocol, retrospectives become opinion-driven: whoever speaks first sets the narrative, recent events crowd out patterns from earlier in the period, and growth suggestions feel personal rather than evidence-based.

Retro grounds every claim in a commit hash. Praise references a specific decomposition in commit abc1234. A growth suggestion references three separate incidents from the data, not a general feeling.

## Time Windows

```
/retro          # Last 7 days (default)
/retro 24h      # Last 24 hours
/retro 14d      # Last 14 days
/retro 30d      # Last 30 days
/retro compare  # Current window vs prior same-length window
```

Windows use midnight-aligned dates in the user's local timezone.

## Data Collection: 14 Parallel Queries

Run these in parallel:

1. `git log --since="<window>" --no-merges --pretty=format:"%h|%ae|%ad|%s" --date=short`
2. `git log --since="<window>" --no-merges --numstat`: LOC added/removed per file
3. `git log --since="<window>" --no-merges --pretty=format:"%ad" --date=format:"%H"`: hourly distribution
4. `git log --since="<window>" --no-merges --pretty=format:"%ae"`: per-author commit counts
5. `git shortlog -sn --since="<window>" --no-merges`: contributor ranking
6. Identify test files (`*.test.*`, `*_test.*`, `*spec*`, `tests/`): count test LOC vs production LOC
7. Scan commit messages for conventional types: feat / fix / refactor / test / docs / chore
8. Detect sessions: commits within 45-minute gaps are the same session. Classify: Deep (50+ min), Medium (20-50 min), Micro (<20 min)
9. File hotspot ranking: files changed most frequently
10. Scan for `Co-Authored-By: Claude` trailers: AI-assisted commit count
11. Check for open items in TODOS.md if it exists
12. Streak detection: consecutive days with commits
13. Focus score per author: percentage of commits to their single most-changed directory
14. PR boundary detection: merge commit messages referencing PR numbers

## Output: 15 Sections

Target length: 2000-4000 words.

1. **Tweetable summary**: one sentence capturing the period
2. **Summary metrics**: commits, contributors, LOC added/removed, net change, PRs merged
3. **Trends**: comparison vs last retro snapshot if available
4. **Time and session patterns**: hourly histogram, session depth breakdown, peak hours, dead zones
5. **Shipping velocity**: commits per day, PR cadence, LOC per hour (rounded to nearest 50)
6. **Code quality signals**: conventional commit type mix, refactor ratio, fix-to-feat ratio
7. **Test health**: test LOC ratio, test file count, regression commits identified
8. **Plan completion**: TODOS.md open/P0/P1/completed counts if the file exists
9. **Focus and highlights**: top file hotspots, most-changed directories
10. **Your week**: deep analysis for the current git user
11. **Team breakdown**: per contributor: commits, LOC, focus score, two specific praise anchors, one growth suggestion framed as investment
12. **Top 3 wins**: most impactful commits identified by message and diff size
13. **3 things to improve**: concrete, anchored in actual data patterns, not general
14. **3 habits for next week**: actionable, specific, based on this period's signals
15. **Week-over-week trends**: directional arrows if prior snapshot exists

## Praise and Feedback Rules

Praise must reference specific commits: "the decomposition in abc1234" not "good refactoring this week."

Growth suggestions are framed as investment, not criticism: "investing time in test coverage for the auth module would reduce the recurrence of the regression pattern visible in commits xyz and abc" not "not enough tests."

AI-assisted commits are labeled separately from solo commits throughout the output.

## Snapshot

Save a JSON snapshot to `context/retros/[YYYY-MM-DD].json` with raw metrics. This is what `/retro compare` and trend sections read from in future runs.

## Anti-Patterns

Do not produce a retrospective without running the git queries first. Opinion without data is not a retro: it is a guess.

Do not include merge commits as work commits. They are PR boundaries, not effort indicators.

Do not make growth suggestions that cannot be traced to a specific data point. If you cannot cite the commit or pattern that supports it, do not say it.

Do not skip the snapshot. The retro's value compounds over time through trend comparison, and the snapshot is what enables that.

## Mandatory Checklist

1. Verify the time window was resolved (from flag or default to 7 days)
2. Verify all 14 data queries were run before producing output
3. Verify all 15 sections are present in the output
4. Verify output is between 2000 and 4000 words
5. Verify praise references specific commit hashes, not general descriptions
6. Verify growth suggestions are framed as investment, not criticism
7. Verify the JSON snapshot was saved to context/retros/[YYYY-MM-DD].json
