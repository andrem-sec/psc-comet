---
name: animation-safe
description: Audit animations and transitions for motion accessibility, performance safety, and design intent. Enforces prefers-reduced-motion compliance and blocks layout-triggering transitions.
version: 0.1.0
level: 2
triggers:
  - "animation safe"
  - "animation audit"
  - "check animations"
  - "motion review"
  - "/animation-safe"
context_files:
  - context/project.md
steps:
  - name: Inventory
    description: List all CSS transitions, keyframe animations, and JavaScript-driven motion in scope.
  - name: Accessibility Check
    description: Verify prefers-reduced-motion is handled for every animation. Flag missing wrappers.
  - name: Performance Check
    description: Identify transitions on layout-triggering properties. Flag non-compositor animations.
  - name: Design Intent Check
    description: Audit for gratuitous animations — entrance on every element, looping animations without purpose, identical timing everywhere.
  - name: Verdict
    description: BLOCK/WARN/CLEAN per animation with specific remediation.
---

# Animation Safe Skill

Audit animations before they ship. Motion that ignores accessibility preferences, triggers layout recalculation, or exists purely as decoration creates real problems — vestibular disorders, janky 60fps misses, and UI that feels busy rather than intentional.

## What Claude Gets Wrong Without This Skill

Claude adds animations because they look good in the moment. `transition: all 0.3s ease` gets added to every interactive element. Scroll-triggered fade-ins appear on every section. CSS keyframes loop indefinitely. None of it is gated on `prefers-reduced-motion`. None of it distinguishes compositor-safe properties from layout-triggering ones.

The second failure: Claude writes `transition: all` because it is the shortest transition declaration. `transition: all` transitions every CSS property simultaneously — including layout properties like `width`, `height`, `padding`, `margin`. This forces layout recalculation on every frame, destroying performance on lower-end hardware and causing visual glitches when other properties change.

## Motion Accessibility — The Core Requirement

The W3C defines two motion-sensitive accessibility needs:

**Vestibular disorders** — large-scale motion (parallax, zoom, full-screen transitions) can trigger nausea or disorientation. Approximately 35% of adults over 40 have vestibular dysfunction.

**Attention/cognitive sensitivity** — looping, blinking, or auto-playing animations can make a page unusable for users with attention or sensory processing differences.

The CSS media query `prefers-reduced-motion: reduce` is set by users in their OS accessibility settings (macOS: Settings → Accessibility → Display → Reduce Motion; Windows: Settings → Ease of Access → Display → Show animations). When set, it signals that the user wants minimal motion.

**This is not optional.** WCAG 2.3.3 (AAA) requires that motion triggered by interaction can be disabled. Practically, all non-essential animation should respond to this preference.

### Required Pattern

Every animation block must have a `prefers-reduced-motion` counterpart:

```css
/* Allowed: transition on compositor-safe properties */
.button {
  transition: background-color 0.2s ease, box-shadow 0.2s ease;
}

/* Required: reduced motion override */
@media (prefers-reduced-motion: reduce) {
  .button {
    transition: none;
  }
}
```

For scroll-triggered animations:
```css
.section {
  opacity: 0;
  transform: translateY(20px);
  transition: opacity 0.4s ease, transform 0.4s ease;
}

.section.visible {
  opacity: 1;
  transform: translateY(0);
}

@media (prefers-reduced-motion: reduce) {
  .section {
    opacity: 1;
    transform: none;
    transition: none;
  }
}
```

For JavaScript-driven animation:
```js
// Check before animating
const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
if (!prefersReduced) {
  element.animate([...], { duration: 400 });
}
```

## Performance — Compositor-Safe Properties

The browser rendering pipeline has four stages: JavaScript → Style → Layout → Paint → Composite. Animating properties that trigger Layout or Paint forces the browser to redo expensive work on every frame.

**Safe to animate (compositor only — GPU-accelerated):**
- `transform` — translate, rotate, scale, skew
- `opacity`
- `filter` (with GPU support)
- `will-change: transform` (use sparingly — forces GPU layer)

**Risky to animate (triggers Paint):**
- `color`, `background-color`, `border-color`, `box-shadow`
- These still perform well on modern hardware but can drop frames on mobile
- Use for subtle transitions (hover state color change) — not sustained animations

**Never animate (triggers Layout — jank guaranteed):**
- `width`, `height`, `min/max-width/height`
- `padding`, `margin`
- `top`, `left`, `right`, `bottom` (use `transform: translate()` instead)
- `font-size`
- `border-width`

**The `transition: all` trap:**
`transition: all` animates every property including Layout-triggering ones. If anything else in the component changes (class added, content updates, sibling resizes), every property transitions. This is the most common animation performance bug.

## Phase Gates

### Inventory

List every animation in scope:

```bash
# CSS transitions
grep -r "transition:" --include="*.css" --include="*.tsx" --include="*.jsx"

# CSS keyframes
grep -r "@keyframes\|animation:" --include="*.css"

# JavaScript animation APIs
grep -r "\.animate(\|requestAnimationFrame\|setTimeout.*style\|setInterval.*style" --include="*.js" --include="*.ts" --include="*.tsx"

# GSAP or animation libraries
grep -r "gsap\.\|TweenLite\|TweenMax\|framer-motion\|motion\." --include="*.tsx" --include="*.jsx"
```

For each animation found, record:
- Property being animated
- Duration and easing
- Trigger (hover, scroll, mount, user action)
- Whether it loops

### Accessibility Check — hard gate

For every animation and transition found:
1. Check if there is a `@media (prefers-reduced-motion: reduce)` block that covers it
2. For JS animations: check for `matchMedia('(prefers-reduced-motion: reduce)')` guard

**BLOCK:** Animation exists with no reduced-motion handling.
**WARN:** Animation exists with partial reduced-motion handling (some elements covered, not all).
**CLEAN:** All animations have reduced-motion fallbacks.

### Performance Check

Classify each animated property against the safe/risky/never table above:

**BLOCK — Layout-triggering:**
- `transition: all` — replace with specific properties
- `transition: width`, `transition: height`, `transition: padding` — replace with transform-based alternatives

**WARN — Paint-triggering on sustained animations:**
- `animation: ... box-shadow` in a looping keyframe — flag for review
- `transition: background-color` with very short duration (<100ms) on scroll events — flag for debounce

**CLEAN:** Only transform/opacity/filter in transitions and keyframes.

### Design Intent Check

Flag gratuitous animation — animation that adds motion without adding meaning:

- **Entrance animation on every element:** If every section, card, heading, and paragraph fades in on scroll, the effect becomes noise. Maximum: 2-3 key elements per section get entrance animation.
- **Looping animations without purpose:** Rotating icons, pulsing elements, or breathing effects that loop indefinitely without conveying state (loading, live, active) are distracting.
- **Identical timing everywhere:** `transition: all 0.3s ease` on everything means no animation has more weight than any other. Intentional animation uses varied timing — quick for feedback (0.15s), medium for transitions (0.3s), slow for emphasis (0.5s+).
- **Hover animations on non-interactive elements:** Dividers, decorative images, and background shapes should not animate on hover.

### Verdict Format

```
## Animation Safe Report: [scope]
Date: [date]

### Accessibility (prefers-reduced-motion)
Verdict: BLOCK | WARN | CLEAN
Findings:
- Button.tsx:24 — transition: background-color 0.2s ease — no reduced-motion fallback [BLOCK]
- hero-section.css:45 — @keyframes fadeInUp — @media reduced motion block missing [BLOCK]

### Performance
Verdict: BLOCK | WARN | CLEAN
Findings:
- Card.tsx:12 — transition: all 0.3s ease — replace with: transition: box-shadow 0.2s ease, transform 0.2s ease [BLOCK]
- NavLink.tsx:8 — transition: color 0.15s ease — paint-triggered but low risk for hover state [WARN]

### Design Intent
Verdict: BLOCK | WARN | CLEAN
Findings:
- 12 of 14 sections have scroll-triggered fade-in — oversaturation [WARN]
- .spinner — looping animation appropriate for loading state [CLEAN]

### Remediations (prioritized)
1. Add @media (prefers-reduced-motion: reduce) wrapper to all transitions — accessibility requirement
2. Replace transition: all with specific properties — performance
3. Reduce scroll animations to hero and first 2 feature cards only — design intent
```

## Common Fixes

**Replace `transition: all`:**
```css
/* Before */
.card { transition: all 0.3s ease; }

/* After — specify only properties that should animate */
.card { transition: box-shadow 0.2s ease, transform 0.15s ease; }
```

**Add reduced-motion block:**
```css
/* After every animation block */
@media (prefers-reduced-motion: reduce) {
  .card { transition: none; }
  .hero-text { animation: none; opacity: 1; transform: none; }
}
```

**Replace layout-triggering position animation:**
```css
/* Before — triggers layout */
.slide-in { transition: left 0.3s ease; left: -100%; }
.slide-in.visible { left: 0; }

/* After — compositor only */
.slide-in { transition: transform 0.3s ease; transform: translateX(-100%); }
.slide-in.visible { transform: translateX(0); }
```

## Anti-Patterns

Do not add `will-change: transform` to every animated element. It consumes GPU memory and can degrade performance when overused. Only apply to elements that are actively animating.

Do not use `@keyframes` for hover state transitions. CSS `transition` handles hover states. Keyframes are for multi-step animations (loading spinners, entrance sequences).

Do not gate `prefers-reduced-motion` check only on the animation trigger — gate it on the CSS declaration. A user who loads the page with reduced motion active should never have the animation run, even on the first trigger.

Do not skip the performance check for mobile. `transition: all` is acceptable on a desktop browser. On a mid-range Android device rendering a 60fps scroll, it causes visible jank.

## Mandatory Checklist

1. Verify all transitions, keyframes, and JS animations were inventoried
2. Verify every animation has a prefers-reduced-motion fallback (BLOCK if missing)
3. Verify no `transition: all` exists in component files (BLOCK)
4. Verify no Layout-triggering properties are animated (BLOCK)
5. Verify looping animations have a purpose (loading, live status) — not decoration
6. Verify scroll-triggered entrance animations are limited to key elements per section
7. Verify verdict was issued per category with specific line-level remediations
