---
name: brand-context
description: Load and validate brand assets before any design work — logo, colors, typography, voice. Gates UI and marketing work behind confirmed brand context.
version: 0.1.0
level: 1
triggers:
  - "brand context"
  - "load brand"
  - "brand assets"
  - "set up brand"
  - "/brand-context"
context_files:
  - context/project.md
steps:
  - name: Locate Assets
    description: Find or create brand_assets/ directory. Identify what is present — logo files, brand guidelines document, color definitions.
  - name: Extract Core Tokens
    description: From whatever exists, extract the minimum required — primary color, secondary color, font family, logo file path. If guidelines doc exists, parse it fully.
  - name: Confirm and Load
    description: Present extracted brand context to user. Confirm accuracy before proceeding. Document in active session context.
---

# Brand Context Skill

Establish brand identity before writing any UI, marketing, or document code. No design work starts without confirmed brand context.

## What Claude Gets Wrong Without This Skill

Without brand context, Claude invents a color palette. It defaults to blues and purples (the AI slop palette), picks Inter because it is safe, and produces something that could belong to any company. The output is technically correct and visually generic. Fixing brand drift after implementation is expensive — colors are scattered across files, fonts are hardcoded, the logo is the wrong variant.

Brand context is not optional decoration. It is the foundation that every downstream design decision rests on.

## The brand_assets/ Pattern

Every project using this skill should have a `brand_assets/` directory at the project root containing:

```
brand_assets/
  logo.svg          (primary logo, SVG preferred)
  logo-dark.svg     (dark background variant, if available)
  logo-mark.svg     (icon/symbol only, if available)
  brand.md          (guidelines — colors, fonts, voice, usage rules)
```

If `brand_assets/` does not exist, create it and prompt the user to populate it before continuing.

Reference it explicitly in CLAUDE.md so it is loaded every session:

```markdown
## Brand
Brand assets are in brand_assets/. Always check this directory before writing any UI code.
```

## Phase Gates

### Locate Phase — hard gate

Check for `brand_assets/` at the project root. If it does not exist:
1. Create the directory
2. Stop and ask the user to provide: logo file, primary color, secondary color, primary font
3. Do not proceed to design work until at minimum a color and font are confirmed

If `brand_assets/` exists, inventory what is present. Note what is missing (logo variants, brand guidelines doc).

### Extract Phase

From `brand.md` or equivalent guidelines document, extract:

| Token | Example | Notes |
|-------|---------|-------|
| Primary color | `#2563EB` | With HSL equivalent |
| Secondary color | `#EA580C` | CTA / accent |
| Background | `#F8FAFC` | Light mode base |
| Foreground | `#1E293B` | Primary text |
| Primary font | `Inter` | With fallback stack |
| Secondary font | `Playfair Display` | Heading variant if separate |
| Logo path | `brand_assets/logo.svg` | Relative path |
| Brand voice | `Professional, direct` | 2-3 adjectives |

If a `design-system/MASTER.md` already exists (from a previous `ui-ux-pro-max` design system generation), read it — it may already contain the extracted tokens.

### Confirm Phase — hard gate

Present extracted context to the user in a summary table. Get explicit confirmation before proceeding to any design task. This prevents building on misread or outdated brand data.

Do not start writing UI code during the confirmation step.

## Integration with ui-ux-pro-max

After brand context is confirmed, the `ui-ux-pro-max` design system generator can be seeded with the brand personality and product type to produce a full design system recommendation:

```bash
python3 .claude/skills/ui/ui-ux-pro-max/scripts/search.py \
  "[product type] [brand personality]" --design-system -p "[ProjectName]"
```

This produces a `design-system/MASTER.md` that becomes the session's design source of truth.

## Anti-Patterns

Do not invent colors or fonts when brand_assets/ is absent. Stop and ask.

Do not read only the logo file and skip the guidelines document. The logo file provides no color or font information.

Do not assume colors from the logo are the full palette. Logos often use a subset of the brand palette.

Do not proceed if the user says "just use something that looks good." That is a signal to run `ui-ux-pro-max` first and present options before building.

## Mandatory Checklist

1. Verify brand_assets/ directory exists or was created
2. Verify primary color, secondary color, and primary font were extracted or confirmed
3. Verify logo file path is known and the file exists
4. Verify brand voice / personality was noted (used by inspiration-brief and ui-slop-guard)
5. Verify user explicitly confirmed the extracted context before design work began
