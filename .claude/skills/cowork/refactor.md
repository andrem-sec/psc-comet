---
name: refactor-cowork
description: Cowork-compatible safe refactoring — coverage gate, behavior contract, one-change rule (single-file)
version: 0.1.0
level: 2
triggers:
  - "refactor"
  - "clean this up"
  - "restructure"
platform: cowork
---

# Refactor (Cowork)

Behavior-preserving restructuring. Different structure, identical observable behavior.

## Before Touching Anything

**1. Coverage gate** — do tests exist? Is coverage ≥ 80%? If not, write tests first.

**2. Behavior contract** — state what the code currently does in terms of observable inputs, outputs, and side effects. This is what must be preserved.

## The One-Change Rule

Make one structural change. Share it. Confirm tests pass. Then make the next change.

Do not batch. Examples of one change:
- Extract a function
- Rename a variable or method
- Remove one instance of duplication
- Flatten one level of nesting

## When to Stop

When the code is clear enough that the next developer can understand it without asking the author. Not when it is perfect.

## Hard Rules

- No behavior changes during refactor. If a test breaks, stop and reassess.
- No bug fixes in the same pass. Fix first, then refactor.
- No new features. Separate concern.
- No renaming things you do not yet understand.
