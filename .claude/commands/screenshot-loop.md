---
name: screenshot-loop
description: Start the visual QA loop — build section, screenshot, compare to reference, correct, repeat
---

Invoke the screenshot-loop skill now. Confirm reference screenshots are in place at temp_screenshots/reference-[section].png before any implementation pass. Build one section at a time, then screenshot using Puppeteer (or prompt for manual screenshot if unavailable). Compare against the reference screenshot. List specific deltas in technical terms (not general impressions). Issue one correction per delta. Maximum 3 passes per section before pausing for user check-in. Do not loop on animated components — flag them for manual review. Do not push or commit while the loop is active.
