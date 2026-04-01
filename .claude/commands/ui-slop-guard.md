---
name: ui-slop-guard
description: Audit UI files for AI slop patterns — color palette, missing interaction states, gratuitous animation, layout clones
---

Invoke the ui-slop-guard skill now. Scan the specified files or current working component for: (1) AI slop hex values (#7c3aed, #8b5cf6, #6366f1, #a855f7, #ec4899) and unanchored gradients, (2) missing hover/focus/active/disabled states on interactive elements, (3) Inter font without brand rationale, (4) canonical AI landing page structure without differentiation, (5) transition: all and missing prefers-reduced-motion. Issue SLOP/RISK/CLEAN verdicts per category with specific line-level findings. Prioritize remediations — fix SLOP findings before marking the component done.
