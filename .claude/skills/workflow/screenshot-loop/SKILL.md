---
name: screenshot-loop
description: Visual QA loop for UI development — build, screenshot, compare to reference, identify delta, prompt correction, repeat. Formalizes the self-review cycle and defines when to disable it.
version: 0.1.0
level: 2
triggers:
  - "screenshot loop"
  - "visual review"
  - "compare to reference"
  - "self review UI"
  - "/screenshot-loop"
context_files:
  - context/project.md
steps:
  - name: Setup
    description: Confirm Puppeteer is available or identify fallback. Establish reference screenshots and naming convention.
  - name: Build Pass
    description: Write the initial implementation.
  - name: Screenshot and Compare
    description: Take section-by-section screenshots. Compare against reference. Identify specific deltas.
  - name: Correct
    description: Issue targeted correction prompts for each delta. One delta per prompt.
  - name: Final Pass
    description: Screenshot the corrected result. Confirm delta is closed. Repeat if needed.
---

# Screenshot Loop Skill

Formalize the visual QA cycle. Build, screenshot, compare, correct, repeat. The loop closes the gap between what Claude thinks it built and what the reference actually looks like.

## What Claude Gets Wrong Without This Skill

Claude writes code and declares it done. It has no way to see the result without a screenshot mechanism. Without one, it is writing blind — making visual decisions based on mental simulation of CSS properties, not actual rendered output.

The second failure: when a screenshot loop is set up but not managed, it becomes a liability. Claude takes a screenshot, sees it does not perfectly match the reference, and issues another correction. And another. And another. It spirals because the goal (exact pixel match) is unachievable and the loop has no exit condition. This skill defines the exit condition.

## Setup

### With Puppeteer (preferred)

Puppeteer must be installed for automated screenshots:

```bash
npm install puppeteer
# or
npx puppeteer install chrome
```

Screenshot configuration in CLAUDE.md (add to project CLAUDE.md, not global):

```markdown
## Screenshot Workflow
- Tool: Puppeteer
- Output dir: temp_screenshots/
- Naming: [section]-[pass]-[timestamp].png
- On session start: delete old screenshots from temp_screenshots/
- On animated elements: DO NOT screenshot — review manually
```

### Without Puppeteer (fallback)

If Puppeteer is not available, use browser DevTools:
1. Open the page in Chrome/Firefox
2. F12 → Console → Ctrl+Shift+P → "Capture full size screenshot"
3. Drag the screenshot into the Claude Code session
4. Proceed with manual comparison

The loop still works without Puppeteer — it just requires manual screenshot capture at each step.

## Phase Gates

### Setup — hard gate

Before the first implementation pass:
1. Confirm screenshot method (Puppeteer or manual)
2. Take a screenshot of the reference (the inspiration site or mockup)
3. Store as `temp_screenshots/reference-[section].png`
4. Set naming convention: `temp_screenshots/[section]-v[N].png` for each pass

Do not start building without a reference screenshot in place. Without it, there is nothing to compare against.

### Build Pass

Write the initial implementation. Do not screenshot during writing — complete the implementation first, then screenshot.

For large pages, implement section by section:
1. Hero → screenshot → compare → correct
2. Features → screenshot → compare → correct
3. Continue section by section

Do not implement the entire page and then screenshot. Section-by-section closes gaps before they compound.

### Screenshot and Compare

After completing a section:
1. Start the local development server if not running
2. Take a screenshot of the built section
3. Compare side-by-side with the reference screenshot
4. List specific deltas — not general impressions

**Delta format:**
```
- [Element]: Built has [X], reference has [Y]
  Example: "Hero heading: built uses 40px, reference appears ~56px"
- [Element]: Built missing [effect]
  Example: "Card: missing the subtle box-shadow, appears flat"
- [Element]: Color mismatch
  Example: "CTA button: built is #2563EB, reference appears warmer ~#3B82F6"
```

Describe deltas in specific, technical terms. "Looks different" is not actionable. "Font size appears 16px too small" is.

### Correct

Issue one targeted prompt per delta. Do not batch all corrections into one prompt — it increases the chance of regression.

```
"The hero heading font size is too small. Increase from 40px to approximately 56px at desktop breakpoint."
```

After each correction, screenshot again and verify that specific delta is closed before moving to the next.

### Exit Condition

The loop exits when:
- All identified deltas are closed, OR
- Remaining deltas are below the "worth fixing" threshold (cosmetic differences that do not affect brand or usability), OR
- The user explicitly says to proceed

Do not loop more than 3 passes on a single section without pausing to ask the user if the remaining delta is worth pursuing. Some differences between a reference and a clone are intentional or unavoidable.

## The Animated Element Exception

For components that include animation (CSS `@keyframes`, JavaScript-driven motion, video backgrounds), screenshots capture a frozen moment. The loop fails because:
1. Screenshot shows one frame of the animation
2. Claude sees it does not match the reference (which shows a different frame or the final state)
3. Claude modifies the animation trying to match the frozen frame
4. This destroys the animation

**When implementing animated components, explicitly disable the screenshot loop:**

> "This component includes animation — do not use the screenshot loop. Implement it and I will review the motion manually."

Add this instruction at the start of any animated component implementation session.

## Local-First / Explicit Push Rule

The screenshot loop runs against localhost. Never push changes to a staging or production environment while the loop is running. Only push when:
1. The loop is complete for all sections
2. The user has reviewed the final result on localhost and given explicit approval

```markdown
# In project CLAUDE.md:
Always develop and test on localhost. Never commit or push until I explicitly say to.
```

## Screenshot Naming Convention

Poor naming causes confusion when reviewing pass history:

| Bad | Good |
|-----|------|
| screenshot_1.png | hero-v1-before.png |
| temp.png | features-v2-after-correction.png |
| compare.png | reference-hero.png |

Format: `[section]-v[pass]-[state].png`
- `section`: hero, features, pricing, footer, nav
- `pass`: v1, v2, v3
- `state`: before, after, reference

## Anti-Patterns

Do not screenshot while still writing code. Complete the implementation pass first.

Do not loop indefinitely trying to achieve a pixel-perfect match with a reference. Set a maximum of 3 passes per section.

Do not use the screenshot loop on animated components. Review motion manually.

Do not push to any remote until the loop is complete and the user approves on localhost.

Do not batch all delta corrections into one prompt. Fix one delta at a time and verify.

## Mandatory Checklist

1. Verify reference screenshots were captured before implementation began
2. Verify naming convention is in place (section-vN-state.png)
3. Verify screenshots were taken section-by-section, not all at once after full implementation
4. Verify deltas were described in specific technical terms, not general impressions
5. Verify animated components were flagged and loop was disabled for them
6. Verify exit condition was applied — loop did not run more than 3 passes without user check-in
7. Verify no push/commit occurred during an active loop pass
