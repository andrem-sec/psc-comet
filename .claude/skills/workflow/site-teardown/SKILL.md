---
name: site-teardown
description: Fetch and analyze the full HTML, CSS, and JavaScript of a reference website — not a WebFetch summary. Identifies techniques, effects, and patterns powering the design for cloning or inspiration extraction.
version: 0.1.0
level: 2
triggers:
  - "site teardown"
  - "teardown"
  - "clone this site"
  - "how did they build"
  - "analyze this website"
  - "/site-teardown"
context_files: []
steps:
  - name: Fetch HTML
    description: Fetch the full page HTML. Parse all linked stylesheet hrefs and script srcs.
  - name: Fetch Assets
    description: Fetch each linked CSS file in full. Fetch key JS files. Do not summarize — retrieve raw content.
  - name: Analyze
    description: Identify named techniques powering key visual effects. Map CSS → visual output.
  - name: Report
    description: Produce a teardown report with identified techniques, reusable patterns, and implementation notes.
---

# Site Teardown Skill

Fetch and understand the source code behind a reference website. Not a screenshot analysis — the actual HTML, CSS, and JavaScript. This is how you move from "it kind of looks like the reference" to "I understand exactly how they built that effect."

## What Claude Gets Wrong Without This Skill

Screenshots show the surface. Source code shows the mechanism. When Claude only sees screenshots, it guesses at implementation — and guesses produce approximations, not replications. The visual gap between "inspired by" and "built from source" is enormous.

The second failure mode: WebFetch uses a smaller summarizing model. It reads a page and returns a condensed description. For a stylesheet with 3,000 lines of carefully crafted CSS, that summary loses almost everything that matters — the specific `backdrop-filter` values, the exact `cubic-bezier` curves, the `clip-path` shapes that create the distinctive cutouts. This skill fetches the raw content, not a summary.

## The WebFetch Problem

When Claude uses WebFetch on a CSS or JS file, the output is processed by a smaller model that summarizes it. This is fine for prose content. For CSS and JavaScript, it strips exactly the technical detail you need.

This skill explicitly bypasses summarization:
1. Fetch the HTML with WebFetch (page structure is readable as prose)
2. Parse `<link rel="stylesheet" href="...">` and `<script src="...">` tags from the HTML
3. Fetch each asset URL individually with WebFetch — raw content only, no summarization prompt
4. Work from the raw content directly

## Phase Gates

### Fetch HTML

Fetch the target URL. Extract all:
- `<link rel="stylesheet" href="...">` tags (CSS files)
- `<script src="...">` tags (JS files — prioritize files with meaningful names, skip analytics/tracking)
- Inline `<style>` blocks
- Any `@import` statements in inline styles

Note: Some sites load CSS via JavaScript (CSS-in-JS, styled-components). If the HTML contains minimal CSS links but the page has rich styling, flag this and look for the main JS bundle.

### Fetch Assets — hard gate

Fetch each CSS file. Do not summarize. Work from the raw text.

Priority order:
1. Main stylesheet (usually named `main.css`, `styles.css`, `app.css`, or has the largest file size hint)
2. Any file with `theme`, `design`, `tokens`, or `variables` in the name
3. Animation/effects files
4. Skip: vendor files (`normalize.css`, `reset.css`), analytics, font loaders

For JS files: fetch only files that appear to contain animation or interaction logic. Skip bundles over 500KB unless a specific effect requires it.

### Analyze

For each identified visual effect the user wants to understand or replicate:

1. **Name the technique** — Give it the correct design vocabulary term (glassmorphism, parallax, scroll-triggered counter, entrance animation, etc.)
2. **Identify the CSS properties** — Exact property names and representative values
3. **Identify the JavaScript** — If the effect requires JS, identify the trigger and the mechanism
4. **Note the dependencies** — Does it use a library (GSAP, Intersection Observer, Three.js)?

Focus on effects relevant to the user's brief. Do not document every CSS rule — only the techniques worth learning or replicating.

### Report

```
## Site Teardown: [URL]
Date: [date]
Requested by: [what the user is trying to learn/replicate]

### Page Architecture
Framework detected: [React/Vue/vanilla/etc]
CSS approach: [utility classes/custom CSS/CSS modules/etc]
Key libraries: [GSAP, Framer Motion, etc]

### Effect: [Name]
Technique: [named style term]
CSS: [relevant properties and values]
JS: [trigger and mechanism if applicable]
Replication difficulty: Low / Medium / High
Notes: [caveats, dependencies, accessibility considerations]

### Effect: [Name]
[same structure]

### Reusable Patterns
[Code snippets or implementation notes for the most valuable techniques]

### What NOT to replicate
[Techniques that are platform-specific, require paid libraries, or are not accessible]
```

## Animated Elements — Disable Flag

For sites with heavy animation (GSAP, WebGL, canvas), screenshots taken during development will not capture the motion. When working on an animated component cloned from this teardown, explicitly tell Claude not to use the screenshot comparison loop for that component:

> "This component is animated — do not use the screenshot loop to validate it. I will review it manually."

This prevents Claude from looping endlessly trying to match a static screenshot to a dynamic element.

## Anti-Patterns

Do not rely on WebFetch summaries for CSS files. Always retrieve raw content.

Do not try to replicate proprietary or licensed design elements. Understand the technique, apply it to your own content.

Do not document every CSS rule. Focus on the effects that differentiate this site from a generic template.

Do not skip the architecture detection step. Knowing the framework changes how you replicate the techniques.

## Mandatory Checklist

1. Verify HTML was fetched and all stylesheet/script hrefs were parsed
2. Verify each relevant CSS file was fetched as raw content (not summarized)
3. Verify each identified effect was named with correct design vocabulary
4. Verify CSS properties and values were extracted, not described in prose
5. Verify replication difficulty was assessed for each effect
6. Verify animated elements were flagged for screenshot-loop disable
