---
name: responsive-design
description: Enforce mobile-first responsive design — breakpoint definition, content reflow audit, touch target validation, and layout stress testing at each tier.
version: 0.1.0
level: 2
triggers:
  - "responsive design"
  - "responsive check"
  - "mobile review"
  - "breakpoint audit"
  - "/responsive-design"
context_files:
  - context/project.md
steps:
  - name: Breakpoint Inventory
    description: Establish the breakpoint system in use. Verify it matches the design brief or project standard.
  - name: Mobile Audit
    description: Review layout at 375px. Touch targets, content reflow, text legibility, navigation.
  - name: Tablet Audit
    description: Review layout at 768px. Identify grid collapse, content ordering, any mobile-only or desktop-only elements.
  - name: Desktop Audit
    description: Review layout at 1280px+. Max-width containers, content density, whitespace.
  - name: Edge Cases
    description: Check very small (320px), large desktop (1920px), and landscape mobile.
  - name: Verdict
    description: BLOCK/WARN/CLEAN per breakpoint tier with specific remediation.
---

# Responsive Design Skill

Audit layouts at every breakpoint before shipping. The pattern of "it works on my screen" is responsible for most responsive bugs. This skill provides a systematic, breakpoint-by-breakpoint review process.

## What Claude Gets Wrong Without This Skill

Claude writes desktop-first code. It builds the full desktop layout and then adds `@media (max-width: 768px)` overrides as an afterthought. The mobile experience gets minimum viable treatment — a single-column stack with no attention to typography scale, touch target sizes, or navigation patterns.

The second failure: Claude tests at one breakpoint mentally. It imagines the layout at 1280px and considers it done. It does not consider 375px (iPhone SE), 390px (iPhone 15), 414px (larger Android), or 320px (minimum supported width). Small differences in assumptions produce real rendering failures.

The third failure: content ordering. On mobile, a sidebar that appears on the right in the desktop layout often needs to appear above the main content — not below it. CSS grid and flexbox reorder properties solve this, but Claude does not set them unless explicitly directed.

## Mobile-First Principle

Write base styles for mobile. Add complexity at larger breakpoints with `min-width` queries. This is the standard — not because it is a preference, but because it is how the cascade and specificity work most predictably.

**Mobile-first:**
```css
/* Base: mobile */
.container { padding: 16px; }
.grid { grid-template-columns: 1fr; }

/* Tablet and up */
@media (min-width: 768px) {
  .container { padding: 24px; }
  .grid { grid-template-columns: repeat(2, 1fr); }
}

/* Desktop and up */
@media (min-width: 1280px) {
  .container { padding: 32px; max-width: 1200px; margin: 0 auto; }
  .grid { grid-template-columns: repeat(3, 1fr); }
}
```

**Desktop-first (anti-pattern):**
```css
/* Base: desktop — wrong direction */
.grid { grid-template-columns: repeat(3, 1fr); }

/* Overrides for smaller screens — harder to maintain */
@media (max-width: 1279px) { .grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 767px) { .grid { grid-template-columns: 1fr; } }
```

If the codebase uses desktop-first, do not rewrite it — document it and work within it. But flag it as a WARN.

## Breakpoint System

Establish the project's breakpoint system before auditing. Common systems:

| Name | Tailwind | Bootstrap | Custom common |
|------|----------|-----------|---------------|
| sm | 640px | 576px | 480px |
| md | 768px | 768px | 768px |
| lg | 1024px | 992px | 1024px |
| xl | 1280px | 1200px | 1280px |
| 2xl | 1536px | 1400px | 1440px |

The project uses one system. Mixing systems (Tailwind defaults in some files, custom breakpoints in others) is a BLOCK finding.

## Phase Gates

### Breakpoint Inventory — hard gate

Locate the breakpoint definitions:
- **Tailwind:** `tailwind.config.js` → `theme.screens`
- **CSS custom properties:** `:root { --bp-md: 768px; }`
- **SCSS variables:** `$breakpoint-md: 768px`
- **JavaScript constants:** `const BREAKPOINTS = { md: 768 }`

If breakpoints are defined in multiple places with different values: BLOCK. Resolve to a single source of truth before auditing layout.

### Mobile Audit (375px)

At 375px, verify:

**Touch targets:**
- All interactive elements are minimum 44×44px (Apple HIG) or 48×48px (Material Design)
- Tap targets do not overlap
- Spacing between adjacent targets is minimum 8px

```bash
# Find small interactive elements
grep -r "width: [0-9]\{1,2\}px\|height: [0-9]\{1,2\}px" --include="*.css" \
  | grep -i "button\|link\|input\|icon"
```

Common failures:
- Icon buttons without minimum tap size (`<button><svg/></button>` with no padding)
- Close buttons in modals that are 24×24px
- Pagination numbers with 4px gap between items

**Navigation:**
- Hamburger menu exists and is functional (if desktop uses horizontal nav)
- Navigation items in mobile menu are minimum 44px tall
- Logo links back to home

**Typography:**
- Body text minimum 16px (14px causes zoom on iOS Safari)
- Heading sizes reduce at mobile (desktop h1 of 64px does not work at 375px)
- Line length stays readable (45-75 characters per line)

**Content reflow:**
- Horizontal scroll does not exist (BLOCK if present)
- No fixed-width elements exceeding viewport width
- Images are responsive (`max-width: 100%` or `width: 100%`)
- Tables either scroll or reflow

**Forms:**
- Input fields are full width on mobile
- Labels are above inputs (not inline)
- `font-size: 16px` on inputs (prevents iOS zoom)

### Tablet Audit (768px)

At 768px, verify:

**Grid behavior:**
- Multi-column grids collapse appropriately (3-col → 2-col or 1-col)
- Cards and panels do not overflow their containers
- Sidebar is either hidden, collapsed, or integrated into flow

**Content ordering:**
- Hero image and text have correct stacking order
- Sidebar content (if relevant) appears before or after main content as intended — not in the visual order defined by DOM source

**Navigation:**
- Navigation fits at this width or gracefully collapses
- No horizontal overflow

### Desktop Audit (1280px)

At 1280px, verify:

**Container max-width:**
- Content is constrained (does not stretch to full viewport on ultra-wide)
- Maximum readable line length is maintained (60-80ch for body text)
- `max-width` container is centered with `margin: 0 auto`

**Content density:**
- Desktop column counts are appropriate for content type (3-4 columns for cards, 2 for comparison)
- Whitespace is intentional, not just empty space from narrow mobile containers expanded

**Hover states:**
- All hover interactions are visible and intentional (links, buttons, cards, navigation items)
- Hover states do not exist on touch-only elements (sidebar nav items that disappear at mobile)

### Edge Cases

**320px (minimum supported):**
- No horizontal scroll
- Text does not overflow containers
- Buttons are still tappable

**1920px (large desktop):**
- Content is not stretched to 1920px width
- Max-width container creates reasonable margins

**Landscape mobile (667px wide, 375px tall):**
- Navigation is accessible
- Hero sections do not require scrolling to see CTA (or gracefully degrade)
- Fixed headers do not consume excessive vertical space

### Verdict Format

```
## Responsive Design Report: [scope]
Date: [date]

### Breakpoint System
Verdict: BLOCK | WARN | CLEAN
Findings: [single source of truth / mixed definitions / system identified]

### Mobile (375px)
Verdict: BLOCK | WARN | CLEAN
Findings:
- .icon-btn: 24×24px — below 44px minimum touch target [BLOCK]
- body text: 14px — will trigger zoom on iOS Safari [BLOCK]
- No hamburger menu — horizontal nav wraps at mobile [WARN]

### Tablet (768px)
Verdict: BLOCK | WARN | CLEAN
Findings:
- .features-grid: 3-column at 768px — columns overflow at this width [BLOCK]
- Sidebar: appears below main content on tablet — correct behavior [CLEAN]

### Desktop (1280px)
Verdict: BLOCK | WARN | CLEAN
Findings:
- No max-width container — content stretches to full viewport at 1920px [WARN]
- Hover states defined for all interactive elements [CLEAN]

### Remediations (prioritized)
1. Fix touch targets: .icon-btn needs min-width/height: 44px and padding: 10px
2. Fix body font-size: 16px minimum on all screens
3. Add max-width: 1200px + margin: auto to .container
```

## Common Fixes

**Touch target fix:**
```css
/* Before — visually 24px icon */
.icon-btn svg { width: 24px; height: 24px; }

/* After — 44px tap target with centered icon */
.icon-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 44px;
  min-height: 44px;
  padding: 10px;
}
.icon-btn svg { width: 24px; height: 24px; }
```

**Prevent iOS zoom on inputs:**
```css
input, select, textarea {
  font-size: 16px; /* Never below 16px */
}
```

**Responsive grid:**
```css
.grid {
  display: grid;
  grid-template-columns: 1fr; /* mobile: single column */
  gap: 16px;
}

@media (min-width: 640px) {
  .grid { grid-template-columns: repeat(2, 1fr); }
}

@media (min-width: 1024px) {
  .grid { grid-template-columns: repeat(3, 1fr); }
}
```

**Content reorder without DOM change:**
```css
/* DOM order: [sidebar] [main] */
/* Visual order at mobile: [main] [sidebar] */
.layout {
  display: flex;
  flex-direction: column;
}

.sidebar { order: 2; } /* mobile: sidebar after main */
.main { order: 1; }

@media (min-width: 1024px) {
  .layout { flex-direction: row; }
  .sidebar { order: 0; } /* desktop: sidebar on left */
  .main { order: 0; }
}
```

## Puppeteer Breakpoint Screenshots

When the screenshot loop is active, use Puppeteer to capture each breakpoint:

```js
const breakpoints = [
  { name: 'mobile', width: 375, height: 812 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1280, height: 800 },
  { name: 'wide', width: 1920, height: 1080 },
];

for (const bp of breakpoints) {
  await page.setViewport({ width: bp.width, height: bp.height });
  await page.screenshot({
    path: `temp_screenshots/[section]-${bp.name}-v1.png`,
    fullPage: true,
  });
}
```

## Anti-Patterns

Do not add `overflow: hidden` to fix horizontal scroll. Investigate what element is overflowing and fix the source.

Do not use `@media (max-width: ...)` queries if the project uses mobile-first `min-width`. Mixing directions breaks specificity and makes the media query cascade unpredictable.

Do not skip the 320px edge case. A non-trivial percentage of users have small or older devices. Content that overflows at 320px represents a broken experience, not an edge case.

Do not use fixed pixel widths on layout containers without a `max-width` counterpart.

Do not assume `width: 100%` on images is sufficient. Images need `max-width: 100%; height: auto; display: block` to prevent overflow and maintain aspect ratio.

## Mandatory Checklist

1. Verify breakpoint system has a single source of truth
2. Verify mobile audit checked: touch targets >=44px, body font >=16px, no horizontal scroll
3. Verify tablet audit checked: grid collapse, content ordering
4. Verify desktop audit checked: max-width container, hover states
5. Verify edge cases: 320px (no overflow), 1920px (no stretch), landscape mobile
6. Verify verdict issued per tier with specific line-level findings
7. Verify BLOCK findings are remediated before component is marked responsive-complete
