---
name: a11y-review
description: Accessibility audit against WCAG 2.1 AA — contrast, keyboard navigation, ARIA, focus management, screen reader text
---

Invoke the a11y-reviewer agent in a fresh context now. Scope: the specified component or page files. Audit for: (1) color contrast ratios (4.5:1 normal text, 3:1 large text and UI components), (2) keyboard accessibility — every interactive element reachable and operable by keyboard, (3) ARIA roles and attributes — correct role for each component type, no missing labels on icon buttons, (4) focus management — visible focus rings, focus trap in modals, focus restoration on close, (5) screen reader text — all images have alt, color is not the only differentiator, (6) form accessibility — labels associated, errors announced. Return PASS/FAIL/NEEDS_REVIEW verdict per WCAG criterion with specific line-level findings and remediations.
