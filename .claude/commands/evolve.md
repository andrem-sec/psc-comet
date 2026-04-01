---
description: Cluster related instincts into skill suggestions
---

# Evolve Instincts into Skills

Analyzes learned instincts and suggests skill structures by clustering related patterns.

## Algorithm

1. Group instincts by domain
2. Calculate trigger similarity (cosine similarity > 0.7)
3. Propose SKILL.md structure with clustered actions
4. Include sample triggers and checklist items

## Output

Proposed skill scaffold with:
- Frontmatter (name, description, level, triggers)
- Grouped actions by similarity
- Anti-patterns derived from low-confidence instincts
- Mandatory checklist from high-confidence requirements

## Review Required

Evolved skills are suggestions only. Manual review needed for:
- Removing redundant actions
- Clarifying ambiguous instructions
- Adding context and examples
- Validating level classification

## Implementation

Invoke continuous-learning-v2 skill. The skill will run:
```
python scripts/continuous-learning-v2/instinct-cli.py evolve
```
