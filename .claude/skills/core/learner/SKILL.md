---
name: learner
description: Capture codebase-specific knowledge as a reusable skill — passes 3-point quality gate before writing
version: 0.1.0
level: 2
triggers:
  - "add to skills"
  - "capture this"
  - "make this a skill"
  - "save as skill"
context_files:
  - context/learnings.md
steps:
  - name: Identify the Insight
    description: What is the underlying principle? State the mental model, not the code.
  - name: Quality Gate
    description: Apply all 3 points — cannot be Googled, codebase-specific, took real effort. All must be YES.
  - name: Generalize
    description: Write the insight in its general form so it applies beyond this specific instance.
  - name: Format
    description: Write the skill body using the Learner Template.
  - name: Place
    description: Write to .claude/skills/learned/[skill-name]/SKILL.md
---

# Learner Skill

Extract a reusable skill from something discovered in this session. The output is a new SKILL.md file in `.claude/skills/learned/`.

## The Insight

A learned skill captures the **mental model**, not the code. The mental model is what Claude needs to reproduce the insight — not a copy-paste of what was written.

## The 3-Point Quality Gate

All three must be YES before writing the skill:

1. **Can't be Googled in 5 minutes** — if it's in the docs, it belongs in the docs, not a skill
2. **Codebase-specific** — if it applies to any project, it's too generic to be worth a skill slot
3. **Took real debugging effort** — if it was obvious, it does not need to be encoded

Reject without exception: generic programming patterns, refactoring techniques, library usage examples, type definitions, boilerplate, and anything a junior dev could find in 5 minutes.

## Skill Body Template

```markdown
---
name: [short-kebab-case-name]
description: [one line — specific enough to be useful]
version: 0.1.0
level: 1
triggers:
  - "[phrase that activates this]"
context_files: []
steps:
  - name: [Step]
    description: [What to do]
---

# [Skill Name]

## The Insight
What is the underlying principle? State the mental model.

## Why This Matters
What symptom brought you here? What went wrong without this?

## Recognition Pattern
When does this skill apply? What are the signs?

## The Approach
How should Claude think through this? Decision heuristic, not code.

## Example (Optional)
Illustrate the principle. Not copy-paste material.

## Mandatory Checklist

1. Verify [condition specific to this skill]
2. Verify [another condition]
```

## Storage

Learned skills go in `.claude/skills/learned/[skill-name]/SKILL.md`.

These are project-specific. Do not move them to core/ or workflow/ unless they prove general enough to apply across projects — which is rare.

## Anti-Patterns

Do not write a learned skill from a first occurrence. One instance is an observation. A recurring pattern is a skill.

Do not name skills generically. `auth-skill` is not a name. `jwt-algorithm-confusion-detection` is.

## Mandatory Checklist

1. Verify the learning passed all 3 quality gate points
2. Verify the insight is stated as a mental model, not as code
3. Verify the skill name is specific enough to be meaningful without reading the body
4. Verify the file was written to .claude/skills/learned/ not to core/ or workflow/
5. Verify a corresponding entry was added to context/learnings.md
