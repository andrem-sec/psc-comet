---
name: model-router-cowork
description: Cowork-compatible model selection guidance (single-file)
version: 0.1.0
level: 1
triggers:
  - "which model"
  - "model router"
  - "use haiku"
  - "use opus"
platform: cowork
---

# Model Router (Cowork)

Match the task to the right model. Wrong direction wastes money or produces wrong answers.

## Routing Table

**Haiku** (fast, low cost)
- File lookup, search, summarization
- Simple data transformation
- Boilerplate and scaffolding
- Repetitive formatting

**Sonnet** (default — balanced)
- Most software engineering tasks
- Code review and debugging
- Planning and decomposition
- Technical writing, API integration

**Opus** (deep reasoning — exception, not default)
- Architectural decisions with significant tradeoffs
- Complex debugging with multiple interacting causes
- High-stakes decisions where error is costly
- Novel problems with no clear precedent

## Rule

Route to Opus because the task requires deep multi-step reasoning Sonnet demonstrably gets wrong — not because it feels important.

Route to Haiku for anything batch, repetitive, or lookup-based.

Default to Sonnet for everything else.
