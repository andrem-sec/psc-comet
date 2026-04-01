---
name: refactor
description: Safe refactoring protocol — behavior-preserving restructuring with test coverage gate
version: 0.1.0
level: 2
triggers:
  - "refactor"
  - "clean this up"
  - "restructure"
  - "extract this"
  - "simplify this"
context_files:
  - context/project.md
steps:
  - name: Coverage Gate
    description: Confirm test coverage exists before touching anything. If coverage is below 80%, write tests first.
  - name: Define Behavior Contract
    description: State what the code currently does — its observable behavior, not its structure. This is what must be preserved.
  - name: Scope
    description: What is being refactored? One concern at a time.
  - name: One Change
    description: Make one structural change. Run tests. Green. Move to next change.
  - name: No Behavior Changes
    description: If a test breaks, the refactor changed behavior — stop and reassess.
  - name: Verify
    description: Full test suite passes. Coverage did not regress. Behavior contract preserved.
---

# Refactor Skill

Behavior-preserving restructuring. The goal is a different structure that produces identical observable behavior.

## What Claude Gets Wrong Without This Skill

Without refactor discipline, "refactoring" becomes a mix of restructuring, behavior changes, and new features in one pass. When something breaks, there is no way to know which change caused it. Tests that fail mid-refactor mean the scope was too large, but without the discipline to go one change at a time, the error is impossible to isolate.

## The Behavior Contract

Before touching any code, state what it currently does in terms of observable behavior — inputs, outputs, side effects. This is the contract.

If the refactor changes any of these, it is not a refactor — it is a feature change or a bug fix. Handle those separately.

## The One-Change Rule

One structural change at a time:
- Extract a function
- Rename a variable
- Remove duplication
- Flatten nesting
- Extract a class
- Move a module

Run tests after each. If they pass, continue. If they fail, the change broke something — revert it and understand why before proceeding.

Do not batch. Do not "while I'm in here" add improvements. Do not rename AND restructure in one change.

## The Coverage Gate

Refactoring without tests is rearranging furniture in the dark. Before the first structural change:
- Run the test suite
- Check coverage
- If coverage is below 80% on the code being refactored, stop and write tests first

This is not optional. Skipping it means the refactor cannot be verified.

## Common Refactor Operations

| Operation | When to Use |
|-----------|-------------|
| Extract function | Block of code used in 2+ places, or a block that has a single clear responsibility |
| Rename | Name does not reflect current purpose (this happens after behavior is understood, not before) |
| Remove duplication | Same logic in 3+ places — but only if the logic is genuinely identical, not just similar |
| Flatten nesting | More than 3 levels of nesting in a single function |
| Extract class | A function or module has grown to handle 2+ distinct concerns |
| Inline | An abstraction that adds complexity without clarity — sometimes the direct version is better |

## Anti-Patterns

Do not refactor code you do not understand. Read it until you can state its behavior contract before touching it.

Do not refactor and fix bugs in the same pass. Fix first, then refactor.

Do not refactor code with no tests. Write tests first.

Do not "improve" variable names speculatively — rename only when you understand the current name is wrong.

## Mandatory Checklist

1. Verify test coverage was checked before any changes
2. Verify the behavior contract was stated before any structural changes
3. Verify only one structural change was made per test run
4. Verify no test failures occurred without a full stop and reassessment
5. Verify the full test suite passes after all changes
6. Verify coverage did not regress
7. Verify the behavior contract is still satisfied after all changes
