---
name: retro
description: Engineering retrospective from git history — velocity, quality, patterns, and team breakdown
---

Invoke the retro protocol now. Analyze the git history for the requested time window and produce a structured retrospective.

## Time windows

```
/retro          # Last 7 days (default)
/retro 24h      # Last 24 hours
/retro 14d      # Last 14 days
/retro 30d      # Last 30 days
/retro compare  # Current window vs prior same-length window
```

Windows use midnight-aligned dates in local timezone.

## Data collection (run in parallel)

1. `git log --since="<window>" --no-merges --pretty=format:"%h|%ae|%ad|%s" --date=short`
2. `git log --since="<window>" --no-merges --numstat` — LOC added/removed per file
3. `git log --since="<window>" --no-merges --pretty=format:"%ad" --date=format:"%H"` — hourly distribution
4. `git log --since="<window>" --no-merges --pretty=format:"%ae"` — per-author commit counts
5. `git shortlog -sn --since="<window>" --no-merges` — contributor ranking
6. Identify test files (pattern: `*.test.*`, `*_test.*`, `*spec*`, `tests/`) — count test LOC vs production LOC
7. Scan commit messages for conventional commit types: feat / fix / refactor / test / docs / chore
8. Detect sessions: commits within 45-minute gaps = same session. Classify: Deep (50+ min), Medium (20-50 min), Micro (<20 min)
9. File hotspot ranking: files changed most frequently
10. Scan for `Co-Authored-By: Claude` trailers — AI-assisted commit count
11. Check for open items in TODOS.md if it exists
12. Streak detection: consecutive days with commits
13. Focus score per author: % of commits to their single most-changed directory
14. PR boundary detection: merge commit messages referencing PR numbers

## Output (15 sections)

1. **Tweetable summary** — one sentence capturing the week
2. **Summary metrics** — commits, contributors, LOC +/-, net change, PRs
3. **Trends** — vs last retro snapshot if available
4. **Time and session patterns** — hourly histogram, session breakdown, peak/dead zones
5. **Shipping velocity** — commits/day, PR cadence, LOC/hour (round to nearest 50)
6. **Code quality signals** — conventional commit mix, refactor ratio, fix-to-feat ratio
7. **Test health** — test LOC ratio, test file count, regression commits
8. **Plan completion** — TODOS.md open/P0/P1/completed if file exists
9. **Focus and highlights** — file hotspots, top changed areas
10. **Your week** — deepest analysis for current git user
11. **Team breakdown** — per contributor: commits, LOC, focus score, 2 praise anchors, 1 growth suggestion
12. **Top 3 wins** — most impactful commits by message and diff size
13. **3 things to improve** — concrete, anchored in actual patterns
14. **3 habits for next week** — actionable, specific
15. **Week-over-week trends** — arrow indicators if prior snapshot exists

## Rules

- Use `origin/<default-branch>` for all git queries
- Display timestamps in user's local timezone
- Treat merge commits as PR boundaries, not work commits
- Praise must reference specific commits ("the decomposition in abc1234")
- Growth suggestions framed as investment, not criticism
- AI-assisted commits labeled separately from solo commits
- Target output: 2000-4000 words

## Snapshot

Save JSON snapshot to `context/retros/[YYYY-MM-DD].json` with raw metrics for trend comparison in future retros.
