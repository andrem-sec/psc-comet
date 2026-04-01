---
name: design-token-guard
description: Enforce the design token layer — block raw hex values, hardcoded font sizes, and magic spacing numbers in component files. All visual values must reference semantic tokens.
version: 0.1.0
level: 2
triggers:
  - "design token guard"
  - "token guard"
  - "check tokens"
  - "enforce tokens"
  - "/design-token-guard"
context_files:
  - context/project.md
steps:
  - name: Token Inventory
    description: Locate the token definitions — CSS custom properties, Tailwind config, design-system MASTER.md. Establish what tokens exist.
  - name: Violation Scan
    description: Search component files for raw values that should be token references — hex colors, px font sizes, magic spacing numbers.
  - name: Classify
    description: For each violation, identify whether a token exists for this value (TOKEN_VIOLATION) or the token is missing entirely (TOKEN_GAP).
  - name: Remediate
    description: TOKEN_VIOLATION — replace raw value with token reference. TOKEN_GAP — add token to the token file, then reference it.
  - name: Verify
    description: Re-scan after remediation. No raw visual values in component files.
---

# Design Token Guard Skill

Enforce the rule: no raw visual values in component files. Every color, font size, spacing value, border radius, and shadow must reference a token. This is how design systems stay coherent when components multiply.

## What Claude Gets Wrong Without This Skill

Claude scatters raw values through component files. `color: #2563EB` here, `font-size: 16px` there, `padding: 12px 24px` everywhere. Each value is correct in isolation. As a system, they are a maintenance liability — changing the brand primary color requires hunting 40 files instead of editing one token.

The second failure: Claude creates tokens but does not use them. A `design-system/MASTER.md` or `tokens.css` file gets generated and then immediately ignored. Components are written against raw values because they compile and Claude does not check. This skill closes that gap.

## The Three-Layer Token Architecture

Visual values must flow through three layers before reaching a component:

```
Layer 1 — Primitive tokens (raw values, never used in components)
  --color-blue-600: #2563EB;
  --size-4: 16px;
  --radius-md: 6px;

Layer 2 — Semantic tokens (intent-named, reference primitives)
  --color-primary: var(--color-blue-600);
  --text-base: var(--size-4);
  --radius-button: var(--radius-md);

Layer 3 — Component tokens (component-scoped, reference semantic)
  --button-bg: var(--color-primary);
  --button-font-size: var(--text-base);
  --button-radius: var(--radius-button);
```

Components reference Layer 3 (or Layer 2 directly for simple cases). They never reference Layer 1. They never use raw values.

## Phase Gates

### Token Inventory — hard gate

Locate where tokens are defined in the project. Common locations:

| Stack | Token Location |
|-------|---------------|
| CSS/vanilla | `tokens.css`, `design-system/tokens.css`, `:root` in `global.css` |
| Tailwind | `tailwind.config.js` → `theme.extend` |
| CSS Modules | `variables.module.css` |
| Styled Components | `theme.ts`, `ThemeProvider` |
| Design system MASTER.md | `.claude/skills/ui/design-system/` |

If no token file exists: create one before running the violation scan. Do not remediate violations by hardcoding — create the missing token layer first.

Document the token file path at session start. Every subsequent violation check references this path.

### Violation Scan

Search component files for raw values:

**Color violations:**
```bash
# Raw hex values in component files
grep -r "#[0-9a-fA-F]\{3,6\}" --include="*.css" --include="*.tsx" --include="*.jsx" \
  --exclude-dir="tokens*" --exclude-dir="design-system"

# rgb/rgba raw values
grep -r "rgb(" --include="*.css" --include="*.tsx" --include="*.jsx" \
  --exclude-dir="tokens*"
```

**Typography violations:**
```bash
# Raw pixel font sizes
grep -r "font-size: [0-9]" --include="*.css" --include="*.tsx"

# Raw font-weight numbers (should be token names in advanced systems)
grep -r "font-weight: [0-9][0-9][0-9]" --include="*.css"
```

**Spacing violations:**
```bash
# Magic pixel padding/margin values (common slop: 12px, 24px, 48px)
grep -r "padding: [0-9]" --include="*.css"
grep -r "margin: [0-9]" --include="*.css"
```

**Tailwind-specific — raw values in className:**
```bash
# Arbitrary Tailwind values (e.g., text-[16px], bg-[#2563EB])
grep -r "\[#[0-9a-fA-F]" --include="*.tsx" --include="*.jsx"
grep -r "text-\[[0-9]" --include="*.tsx" --include="*.jsx"
```

**Exceptions — values allowed in component files:**
- `0` (zero values for margin/padding reset)
- `100%`, `auto` (layout keywords)
- `inherit`, `currentColor` (CSS cascade keywords)
- `transparent`
- Values inside token definition files themselves

### Classify Each Violation

For each raw value found:

**TOKEN_VIOLATION** — a token exists for this value but the component uses the raw value instead.
```
Found: color: #2563EB in Button.tsx:24
Token exists: --color-primary: #2563EB (in tokens.css:12)
Fix: Replace #2563EB with var(--color-primary)
```

**TOKEN_GAP** — no token exists for this value. The value needs to be tokenized first.
```
Found: padding: 12px 24px in Card.tsx:8
No spacing token found for 12px or 24px
Fix: Add --spacing-3: 12px and --spacing-6: 24px to tokens.css, then update Card.tsx
```

**TOKEN_CONFLICT** — a token exists but points to a different value.
```
Found: color: #1D4ED8 in NavLink.tsx:15
Closest token: --color-primary: #2563EB (different shade)
Fix: Determine if this is intentional (add new token) or a mistake (use --color-primary)
```

### Remediate

Fix TOKEN_VIOLATIONs first — they are simple substitutions.

For TOKEN_GAPs:
1. Add the token to the token definition file (Layer 2 — semantic, not Layer 1 — primitive)
2. Name it by intent, not value: `--spacing-button-padding-y`, not `--spacing-12px`
3. Then update the component to reference the new token

For TOKEN_CONFLICTs:
1. Ask the user before resolving — this requires design intent judgment
2. Document the decision in `context/decisions.md`

### Verify

After all remediations, re-run the violation scan. Target: zero raw hex values, zero raw font-size px values in component files. Spacing violations are RISK — document remaining intentional exceptions.

## Token Naming Conventions

Good token names encode intent, not value:

| Bad (value-based) | Good (intent-based) |
|-------------------|---------------------|
| `--blue-500` | `--color-primary` |
| `--16px` | `--text-base` |
| `--12-24px` | `--spacing-card-padding` |
| `--6px` | `--radius-button` |
| `--400` | `--font-normal` |

Exception: primitive tokens (Layer 1) can be value-based. They are never used in components directly — they are only referenced by semantic tokens.

## Tailwind Projects

In Tailwind projects, the token layer lives in `tailwind.config.js`. Raw values appear as arbitrary values in className strings.

**Allowed:**
```jsx
// Uses configured scale
<div className="bg-primary text-base p-4 rounded-button">
```

**Violation:**
```jsx
// Arbitrary values — bypasses the token layer
<div className="bg-[#2563EB] text-[16px] p-[12px] rounded-[6px]">
```

In Tailwind, the `theme.extend` configuration IS the token layer. Arbitrary values in JSX are the equivalent of raw hex in CSS.

## Enforcement Hook Integration

This skill works alongside the `warn-token-violation.sh` hook (Phase 4), which automatically flags raw hex values on Write/Edit. The skill provides the full audit and remediation workflow; the hook provides real-time prevention.

## Anti-Patterns

Do not add token references without the token existing in the token file. Forward references silently fail in CSS custom properties (the property resolves to the initial value, not an error).

Do not create a token for every raw value individually without checking if a scale exists. Twelve similar spacing values should use a shared spacing scale, not twelve ad-hoc tokens.

Do not resolve TOKEN_CONFLICTs unilaterally — different shades of the same color may be intentional for hover states, disabled states, or accessibility contrast requirements.

Do not skip the token inventory phase. Remediating violations before knowing what tokens exist leads to creating duplicate tokens.

## Mandatory Checklist

1. Verify token definition file(s) were located and inventoried before any scan
2. Verify scan covered CSS, TSX, JSX, and HTML files (excluding token definition files)
3. Verify each violation was classified as TOKEN_VIOLATION, TOKEN_GAP, or TOKEN_CONFLICT
4. Verify TOKEN_VIOLATIONs were replaced with existing token references (not new hardcoded values)
5. Verify TOKEN_GAPs resulted in new tokens added to the token file before component updates
6. Verify TOKEN_CONFLICTs were escalated to the user before resolution
7. Verify re-scan after remediation shows zero raw hex values in component files
