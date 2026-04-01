---
name: inspiration-brief
description: Gate before any UI implementation — requires confirmed inspiration references, color intent, typography direction, visual storytelling concept, and product-type design system. No HTML/CSS written until brief is confirmed.
version: 0.1.0
level: 2
triggers:
  - "inspiration brief"
  - "design brief"
  - "before we build"
  - "start a new UI"
  - "new landing page"
  - "new page"
  - "/inspiration-brief"
context_files:
  - context/project.md
steps:
  - name: Brand Check
    description: Confirm brand context is loaded. If not, invoke brand-context first.
  - name: Product Type
    description: Identify the product type and target audience. Run ui-ux-pro-max design system generator to get style/color/typography recommendations.
  - name: Gather References
    description: Collect 2-5 inspiration URLs or screenshots. At least one must be from awwwards, godly.website, Dribbble, or Pinterest.
  - name: Brief Draft
    description: Synthesize brand + product type recommendations + references into a concrete design brief with color direction, typography direction, named style, and visual storytelling concept.
  - name: Confirm
    description: Present the brief. Get explicit approval. Only then proceed to implementation.
---

# Inspiration Brief Skill

Define what the UI should look and feel like before writing a line of code. The output is a confirmed brief that implementation uses as its visual source of truth.

## What Claude Gets Wrong Without This Skill

Without a brief, Claude starts building immediately. It makes every design decision implicitly — color palette, font choice, layout structure, animation style — and presents the result as a fait accompli. The user then spends 10 prompts correcting decisions that could have been made in 5 minutes upfront.

The deeper problem: Claude's default choices are statistically average. It has seen thousands of SaaS templates. Without direction, it produces the centroid of those templates — technically functional, visually indistinguishable from every other AI-generated interface.

## Where to Find Inspiration

Before drafting the brief, the user should have looked at references. Point them here if they have not:

- **awwwards.com** — Sites of the Day/Month. Award-winning work, high craft signal.
- **godly.website** — Infinite scroll of curated contemporary web design.
- **dribbble.com** — Component and page-level inspiration. Search by product type.
- **pinterest.com** — SaaS landing pages, dashboard UI, mobile app screens.
- **21st.dev** — Component-level inspiration (buttons, backgrounds, cards, navigation).

At least one reference must be a full page (not just a component) from awwwards, godly, or Dribbble.

## Phase Gates

### Brand Check — hard gate

Verify `brand-context` has been run and brand tokens are available. If not, invoke it first. Do not skip this — the brief must be grounded in the actual brand palette, not invented colors.

### Product Type + Design System

Identify the product type from the user's description. Map it to the `ui-ux-pro-max` reasoning database:

```bash
python3 .claude/skills/ui/ui-ux-pro-max/scripts/search.py \
  "[product description]" --design-system -p "[ProjectName]"
```

This returns:
- Recommended style (e.g., Glassmorphism + Flat Design for SaaS)
- Color direction (e.g., Trust blue + orange CTA)
- Typography recommendation (e.g., Space Grotesk + DM Sans)
- Anti-patterns to avoid for this product type
- Landing page pattern recommendation

Use these as the starting point — they are defaults to refine, not mandates.

### Gather References — hard gate

Collect 2-5 references from the user. Acceptable forms:
- URLs to live sites
- Screenshots dragged into the session
- Descriptions of specific sites by name

For each reference, note:
- What specifically is appealing (background treatment, card style, typography, animation)
- What to avoid copying (layout that is too close, colors that clash with brand)

If the user provides no references and says "you decide," surface 3 options from the relevant inspiration sites based on the product type and ask them to pick one to anchor the brief.

### Brief Draft

Synthesize all inputs into a brief with these required fields:

```
## Design Brief: [Page/Feature Name]
Date: [date] | Status: DRAFT → CONFIRMED

### Product Type
[Product type + ui-ux-pro-max recommendation]

### Brand Foundation
Primary: [color + HSL]
Secondary/CTA: [color + HSL]
Font (heading): [font name]
Font (body): [font name]
Voice: [2-3 adjectives]

### Visual Direction
Style: [named style from ui-ux-pro-max — e.g., Glassmorphism]
Mood: [e.g., "Premium, trustworthy, forward-leaning"]
References: [URLs or descriptions]
What to take from references: [specific elements]
What NOT to take: [explicit exclusions]

### Visual Storytelling
Tagline concept: [if applicable]
Hero imagery concept: [static or video, AI-generated or stock]
Key narrative arc: [what story does scrolling tell]

### Anti-patterns for this product type
[From ui-ux-pro-max reasoning — e.g., "Avoid AI purple/pink gradients"]

### Confirmation
Confirmed? (yes / modify / no)
```

### Confirm — hard gate

Present the brief. Wait for explicit user confirmation before writing any HTML, CSS, or component code. A "modify" response triggers revision of specific sections. A "yes" unlocks implementation.

## Integration Points

- **brand-context**: Must run first
- **ui-ux-pro-max**: Provides product type recommendations and anti-patterns
- **site-teardown**: If user provides a reference URL, site-teardown can fetch the full CSS/JS for deeper analysis
- **design-token-guard**: Brief's color/font selections become the token definitions
- **screenshot-loop**: Brief's references become the comparison targets during the visual QA loop

## Anti-Patterns

Do not start writing UI code while the brief is in DRAFT status.

Do not accept "make it look modern and clean" as a brief. Push for specifics — which reference? Which named style?

Do not skip the product-type design system step. The ui-ux-pro-max reasoning rules contain validated anti-patterns that prevent the most common category-specific mistakes.

Do not treat the ui-ux-pro-max recommendations as final. They are the informed default. The user's references and brand may legitimately deviate from them — document the deviation in the brief.

## Mandatory Checklist

1. Verify brand-context was run before this skill
2. Verify product type was identified and ui-ux-pro-max design system was generated
3. Verify at least 2 inspiration references were collected
4. Verify brief contains: named style, color direction, typography direction, visual storytelling concept, and explicit anti-patterns
5. Verify user gave explicit confirmation (not just silence or "sure") before implementation began
