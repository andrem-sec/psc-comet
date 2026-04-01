---
name: ui-slop-guard
description: Audit UI code for AI slop patterns — generic color palettes, missing interaction states, cookie-cutter gradients, and template-clone layouts. Returns SLOP/RISK/CLEAN verdicts with specific remediation.
version: 0.1.0
level: 2
triggers:
  - "ui slop guard"
  - "slop check"
  - "check for ai slop"
  - "audit this UI"
  - "/ui-slop-guard"
context_files:
  - context/project.md
steps:
  - name: Color Audit
    description: Scan for AI slop hex values and unanchored gradients. Flag any color not from the brand token set.
  - name: Interaction Audit
    description: Verify every interactive element has hover, focus, active, and disabled states.
  - name: Typography Audit
    description: Check for Inter/Roboto defaults, missing type scale, and unvaried font weights.
  - name: Layout Audit
    description: Identify hero-cta-features-pricing-footer clone patterns and surface-level "premium" signals.
  - name: Animation Audit
    description: Detect gratuitous or performance-unsafe animations. Flag missing prefers-reduced-motion.
  - name: Verdict
    description: Issue SLOP/RISK/CLEAN per category with specific line-level remediation.
---

# UI Slop Guard Skill

Audit code for the patterns that make AI-generated UI look AI-generated. The output is a category-by-category verdict, not a general impression.

## What Claude Gets Wrong Without This Skill

Claude produces statistically average output. It has trained on thousands of SaaS landing pages, and without contrary instruction, it reproduces the center of that distribution. The resulting UI is not wrong — it is indistinguishable. Same violet gradient, same Inter font at 16px, same hero-features-pricing-CTA structure, same cards with `box-shadow: 0 4px 6px rgba(0,0,0,0.1)`.

The second failure: slop often hides in omission. The button has a primary style. It has no hover state. It has no focus ring. It has no disabled treatment. It looks complete until someone tabs to it or disables it — and then it falls apart. This skill makes omissions visible.

## AI Slop Signature Patterns

These are the specific patterns that tag output as AI-generated. Any match is a flag.

### Color Slop

**Hard block — the AI violet palette:**
- `#7c3aed` (violet-700)
- `#8b5cf6` (violet-500)
- `#6366f1` (indigo-500)
- `#a855f7` (purple-500)
- `#ec4899` (pink-500)

Any of these in a project without an explicit brand reason is AI slop. These are the default colors of models that learned from a corpus dominated by AI startup landing pages.

**Risk flags — unanchored gradients:**
- `linear-gradient(135deg, ...)` — the default angle. Real gradient design specifies intent, not default.
- `linear-gradient(to right, #[purple], #[blue])` — the AI purple-to-blue hero background.
- Any gradient that is not documented in the design brief.

**Risk flags — shadow patterns:**
- `box-shadow: 0 4px 6px rgba(0,0,0,0.1)` — Tailwind's default shadow. Present everywhere. Signals no design intent.
- Identical shadow values across all card components.

### Interaction State Slop

Missing states are invisible until they are not:

| Element | Required States |
|---------|----------------|
| Button (primary) | default, hover, active, focus, disabled, loading |
| Button (secondary/ghost) | default, hover, active, focus, disabled |
| Link | default, hover, focus, visited (if navigation) |
| Input | default, focus, error, disabled |
| Card (clickable) | default, hover, active, focus |
| Toggle/Switch | default-on, default-off, hover, focus, disabled |
| Tab | default, active, hover, focus |

Audit method: read every interactive element. For each, check that CSS or component props define all required states. A button with only `bg-blue-500` and `text-white` has zero states defined. That is SLOP.

### Typography Slop

- `font-family: 'Inter'` with no design rationale — Inter is the AI default font, same as violet is the AI default color.
- Single `font-size: 16px` everywhere — no type scale.
- `font-weight: 400` only — no weight variation to create visual hierarchy.
- Headings that are just body text made larger, not a deliberate typographic choice.
- Missing line-height on body text (renders poorly at narrow widths).

### Layout Slop

The canonical AI landing page structure:
```
[Hero: headline + subline + CTA button + hero image]
[Features: 3-column icon grid]
[Social proof: logo strip]
[Pricing: 3-tier cards]
[CTA banner]
[Footer]
```

This structure is not wrong. It is used because it works. The slop signal is when the structure is reproduced without any differentiation — same section order, same column counts, same visual weight distribution.

Flag: sections with class names `hero`, `features`, `pricing`, `testimonials`, `cta-banner` in exact canonical order. Not a hard block — a RISK that warrants visual review.

### Animation Slop

- `transition: all 0.3s ease` — the blanket transition. Flags everything including layout and color, causing performance issues and visual noise.
- Entrance animations on every element (fade-in, slide-up on scroll) — oversaturation that dulls the effect.
- Missing `@media (prefers-reduced-motion: reduce)` — accessibility violation.
- JavaScript-driven animations that do not account for reduced motion preference.

## Phase Gates

### Color Audit

Scan the codebase for the hard-block hex values and gradient patterns:

```bash
# Hard-block colors
grep -r "#7c3aed\|#8b5cf6\|#6366f1\|#a855f7\|#ec4899" --include="*.css" --include="*.tsx" --include="*.jsx" --include="*.html"

# Unanchored gradients
grep -r "linear-gradient(135deg\|linear-gradient(to right.*#[789a-f][0-9a-f]" --include="*.css" --include="*.tsx"

# Default shadow
grep -r "0 4px 6px rgba(0,0,0,0.1)" --include="*.css" --include="*.tsx"
```

For each match: check if the color/gradient is explicitly documented in the design brief or brand tokens. If not, it is unanchored and a slop candidate.

### Interaction Audit

For each interactive element in scope:
1. Identify its element type (button, link, input, etc.)
2. Check the required state table above
3. For each missing state: flag as SLOP

Check CSS directly — not component names. A file called `Button.tsx` with `className="bg-blue-500 text-white px-4 py-2 rounded"` has no interaction states regardless of its name.

### Typography Audit

Check `font-family` declarations. If Inter appears without a design rationale in the brief, flag RISK. If no type scale is defined (only a single font-size in use), flag RISK.

### Layout Audit

Check section order and class names. If the structure matches the canonical AI landing page pattern exactly, flag RISK — not SLOP. Some projects legitimately use this structure. The flag triggers a visual review question: "Is this structure intentional, or was it generated by default?"

### Animation Audit

Check for `transition: all` (RISK — too broad), missing `prefers-reduced-motion` wrapper (SLOP if animations are present), and identical transition timing across all elements (RISK — no motion design intent).

### Verdict Format

```
## UI Slop Guard Report: [file or component]
Date: [date]

### Color
Verdict: SLOP | RISK | CLEAN
Findings:
- [line N]: #8b5cf6 — AI violet palette, no brand documentation. Replace with brand token.

### Interaction States
Verdict: SLOP | RISK | CLEAN
Findings:
- Button.tsx: missing hover, focus, disabled states

### Typography
Verdict: SLOP | RISK | CLEAN
Findings:
- font-family: Inter — no design brief rationale. Verify this is intentional.

### Layout
Verdict: SLOP | RISK | CLEAN
Findings:
- Section order matches canonical AI template. Review for differentiation.

### Animation
Verdict: SLOP | RISK | CLEAN
Findings:
- transition: all 0.3s ease on 14 elements — too broad. Specify properties.
- No prefers-reduced-motion wrapper found.

### Overall: SLOP | RISK | CLEAN
[Summary: X hard blocks, Y risk flags. Prioritized remediation:]
1. [Highest priority fix]
2. [Second priority fix]
```

**Verdict definitions:**
- `SLOP` — hard block pattern found. Must be remediated before the component is shipped.
- `RISK` — pattern that is often slop but may be intentional. Requires explicit confirmation.
- `CLEAN` — no slop patterns found in this category.

## Integration Points

- **design-token-guard**: Color slop is often a token violation. If raw hex values are in component files instead of token references, invoke design-token-guard.
- **brand-context**: The brand palette is the whitelist. Colors not in the brand palette are slop candidates.
- **inspiration-brief**: The brief's named style is the benchmark. Gradients and colors not aligned to the brief are flags.
- **component-spec**: Missing interaction states were states not defined in the spec. Loop back to component-spec to define them before adding code.

## Anti-Patterns

Do not flag Inter as SLOP if the brand explicitly uses Inter. Brand documentation overrides slop heuristics.

Do not treat the canonical landing page structure as automatically bad. The verdict is RISK, not SLOP — it requires a visual review, not an automatic rewrite.

Do not audit class names for semantic meaning (.hero-section, .features-grid). This skill audits CSS values and properties, not naming conventions.

Do not batch all findings into one correction prompt. Fix one SLOP verdict at a time and verify.

## Mandatory Checklist

1. Verify all 5 hard-block hex values were searched across CSS, TSX, JSX, and HTML files
2. Verify every interactive element was checked against the required states table
3. Verify font-family declarations were identified and cross-checked against brand brief
4. Verify animation declarations were checked for `transition: all` and missing reduced-motion
5. Verify each finding was assigned SLOP/RISK/CLEAN with a specific line-level location
6. Verify SLOP findings are remediated before the component is marked complete
