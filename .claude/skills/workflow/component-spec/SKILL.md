---
name: component-spec
description: Define component API, states, variants, and ARIA requirements before writing a line of implementation code. Gates component work behind a confirmed spec.
version: 0.1.0
level: 2
triggers:
  - "component spec"
  - "spec this component"
  - "before I build this"
  - "define this component"
  - "/component-spec"
context_files:
  - context/project.md
steps:
  - name: Identity
    description: Name the component. Identify its category (input, display, navigation, feedback, layout).
  - name: Props API
    description: Define all props — name, type, default, required/optional. No undocumented props.
  - name: States
    description: Enumerate every visual state — default, hover, active, focus, disabled, loading, error, empty.
  - name: Variants
    description: List named variants (size, color, shape). Each variant is a prop value, not a separate component.
  - name: Accessibility
    description: Specify ARIA role, aria-label pattern, keyboard navigation, focus ring, screen reader behavior.
  - name: Responsive
    description: Define breakpoint behavior. What changes at mobile? What collapses or stacks?
  - name: Confirm
    description: Present spec. Wait for explicit confirmation before writing implementation.
---

# Component Spec Skill

Write the spec before writing the component. A confirmed spec prevents the cycle of building, seeing it does not match intent, rebuilding, and realizing the API is wrong for the context.

## What Claude Gets Wrong Without This Skill

Claude builds what it guesses the component needs. It chooses an API surface based on the first use case it imagines. States get omitted because they were not considered upfront — the disabled state looks like the active state because both were never defined. Variants proliferate as separate components instead of being parameterized.

The deeper failure: ARIA is bolted on at the end if at all. A button that triggers a dialog does not have `aria-haspopup`. A toggle does not have `aria-checked`. An input does not have an `aria-describedby` pointing to its error message. These are not optional — they are the difference between a component that works and one that excludes users.

## Where to Find Component Inspiration

Before writing the spec, look at how others have solved this component:

- **21st.dev** — Component-level inspiration. Search by component type (button, card, input, modal).
- **CodePen** — Live examples with source. Filter by Most Loved.
- **Shadcn/UI** — Accessible, unstyled components with clean API patterns.
- **Radix UI primitives** — The reference standard for accessible interactive components.
- **Headless UI** — Tailwind-adjacent accessible components.

Do not copy visual style from these sources. Copy API patterns and state enumeration — what states did they handle that you missed?

## Phase Gates

### Identity — hard gate

Name the component and classify it:

| Category | Examples |
|----------|---------|
| Input | Button, TextField, Select, Checkbox, Toggle, Slider |
| Display | Card, Badge, Avatar, Tag, Tooltip, Chip |
| Navigation | Tabs, Breadcrumb, Pagination, Sidebar, NavLink |
| Feedback | Alert, Toast, Progress, Skeleton, Spinner |
| Layout | Divider, Spacer, Grid, Stack, Container |
| Overlay | Modal, Drawer, Popover, Dropdown, Sheet |

Classification determines which state set applies and which ARIA patterns are mandatory.

### Props API

Define every prop explicitly:

```
## Props
| Prop | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| label | string | — | yes | Button label text |
| variant | 'primary' | 'secondary' | 'ghost' | 'destructive' | 'primary' | no | Visual style |
| size | 'sm' | 'md' | 'lg' | 'md' | no | Affects padding and font size |
| disabled | boolean | false | no | Disables interaction |
| loading | boolean | false | no | Shows spinner, disables interaction |
| onClick | () => void | — | no | Click handler |
| type | 'button' | 'submit' | 'reset' | 'button' | no | HTML button type |
```

Rules:
- No props with generic names (`data`, `config`, `options`) unless they are truly generic containers
- Booleans default to false — never make a boolean required
- String unions beat string with "valid values are..." documentation
- Event handlers use the `on` prefix

### States — hard gate

Enumerate every visual state the component can exist in. Missing states become visual bugs.

**Input/Interactive component states:**
- `default` — at rest, no interaction
- `hover` — mouse over
- `focus` — keyboard focused (must have visible focus ring)
- `active` — being pressed/activated
- `disabled` — not interactive, reduced opacity or contrast
- `loading` — async operation in progress
- `error` — validation failed or async operation failed

**Display component states:**
- `default`
- `empty` — no data to display (skeleton, placeholder, or empty state message)
- `loading` — data fetching
- `error` — fetch failed

**For each state, describe:**
- Visual treatment (color, opacity, border, background)
- Any content change (spinner replaces icon, error message appears)
- Cursor change if applicable

### Variants

Variants are named parameter values, not separate components:

```
## Variants
### variant prop
- primary: brand primary background, white text — main CTA
- secondary: transparent background, brand border, brand text — secondary action
- ghost: no background, no border, brand text — inline or tertiary action
- destructive: red background / red border — irreversible actions only

### size prop
- sm: h-8, px-3, text-sm — dense UIs, table actions
- md: h-10, px-4, text-base — default
- lg: h-12, px-6, text-lg — hero CTAs, landing pages
```

Do not create a new component when a variant handles the differentiation.

### Accessibility — hard gate

Map the component to its ARIA pattern. This is not optional.

**By category:**

| Category | Required ARIA |
|----------|--------------|
| Button | `role="button"` (implicit on `<button>`), `aria-disabled` when disabled, `aria-pressed` for toggles |
| Input | `<label>` with `htmlFor`, `aria-describedby` pointing to helper/error text, `aria-invalid` on error |
| Select / Dropdown | `role="combobox"`, `aria-expanded`, `aria-controls`, `aria-activedescendant` |
| Modal | `role="dialog"`, `aria-modal="true"`, `aria-labelledby`, focus trap, Escape to close |
| Alert | `role="alert"` for errors, `role="status"` for success/info |
| Toggle | `aria-checked` (boolean), `role="switch"` |
| Tab | `role="tablist"`, `role="tab"`, `role="tabpanel"`, `aria-selected`, `aria-controls` |
| Navigation | `role="navigation"`, `aria-label` to distinguish multiple nav regions |

**Keyboard navigation:**
- Buttons: `Enter` and `Space` activate
- Tabs: `Arrow` keys navigate, `Tab` moves focus out of group
- Modals: `Tab` cycles within, `Escape` closes
- Dropdowns: `Arrow` keys navigate options, `Enter` selects, `Escape` closes

**Focus ring:**
- Never use `outline: none` without a replacement
- Minimum: `outline: 2px solid currentColor; outline-offset: 2px`
- Must meet 3:1 contrast against adjacent colors

### Responsive

Define what changes at each relevant breakpoint:

```
## Responsive Behavior
| Breakpoint | Behavior |
|-----------|----------|
| Mobile (<640px) | Full width, stacked layout |
| Tablet (640-1024px) | [if different from desktop] |
| Desktop (>1024px) | Default spec applies |
```

If the component looks identical at all breakpoints, say so explicitly. Do not leave it undocumented.

### Confirm — hard gate

Present the full spec. Wait for explicit confirmation. Do not write any implementation code until the user says yes.

If the user says "looks good" without reviewing the states section, prompt: "Did you review the states list? The disabled and error states are often where UI regressions hide."

## Spec Template

```markdown
## Component Spec: [ComponentName]
Date: [date] | Status: DRAFT → CONFIRMED

### Identity
Category: [Input | Display | Navigation | Feedback | Layout | Overlay]
Description: [One sentence — what this component does and where it is used]

### Props API
| Prop | Type | Default | Required | Description |
|------|------|---------|----------|-------------|

### States
- default: [visual treatment]
- hover: [visual treatment]
- focus: [visual treatment — must include visible focus ring]
- active: [visual treatment]
- disabled: [visual treatment]
- loading: [visual treatment, if applicable]
- error: [visual treatment, if applicable]
- empty: [visual treatment, if applicable]

### Variants
[variant prop]: [value] — [use case]

### Accessibility
ARIA role: [role]
Required ARIA attributes: [list]
Keyboard navigation: [Enter/Space/Arrow/Escape behavior]
Focus ring: [spec]
Screen reader announcement: [what does VoiceOver say?]

### Responsive
| Breakpoint | Behavior |
|-----------|----------|

### Confirmation
Confirmed? (yes / modify / no)
```

## Anti-Patterns

Do not write implementation before the spec is confirmed. This includes "just the skeleton" or "just the markup."

Do not leave any state undocumented. If you are not sure what the loading state looks like, ask before building.

Do not use `aria-label="button"` or other non-descriptive ARIA labels. The label must describe the action, not the element type.

Do not skip the responsive section by assuming "it looks fine at all sizes." Define it explicitly.

Do not create separate components for variants. `<Button variant="destructive">` is correct. `<DestructiveButton>` is a smell.

## Mandatory Checklist

1. Verify component category was identified and matched to its ARIA pattern
2. Verify all props have types, defaults, and descriptions
3. Verify all applicable states are enumerated with visual treatments
4. Verify variants are parameterized (not separate components)
5. Verify ARIA role, attributes, and keyboard navigation are specified
6. Verify responsive behavior is defined at each relevant breakpoint
7. Verify user gave explicit confirmation before any implementation began
