---
name: refactor
description: Safe refactoring — coverage gate, behavior contract, one structural change per test run
---

Invoke the refactor skill now. Before touching any code: confirm test coverage exists (80% minimum — write tests first if not). State the behavior contract — what the code currently does that must be preserved. Then make one structural change, run tests, confirm green, repeat. Do not batch changes. Do not fix bugs or add features in the same pass.
