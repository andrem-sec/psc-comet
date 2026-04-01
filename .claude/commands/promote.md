---
description: Manually promote project instinct to global scope
---

# Promote Instinct to Global

Moves high-confidence project instinct to global scope, applying it across all projects.

## Usage

```
/promote inst_042
```

## Requirements

- Instinct must exist in current project
- Confidence >= 0.8 (promotion threshold)
- Scope must be "project" (not already global)

## Effect

After promotion:
- Instinct moves to global_instincts array
- Applies to all projects in ~/.claude/homunculus/
- Evidence preserved with promotion timestamp
- Logged to learnings.md

## When to Promote

Promote when pattern is:
- Validated across multiple use cases
- Not project-specific (applies broadly)
- High confidence (applied successfully 10+ times)
- Documented with clear evidence

## Implementation

Invoke continuous-learning-v2 skill. The skill will run:
```
python scripts/continuous-learning-v2/instinct-cli.py promote ID
```
