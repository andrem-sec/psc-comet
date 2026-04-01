---
name: fix
description: Bug fix pipeline — debug-session → regression test → fix → code-review → learnings
---

Invoke the fix-pipeline skill now. State the symptom as observable behavior. Run debug-session to confirm a hypothesis before touching any code. Write the regression test first. Fix the minimum. Run the full test suite. Code-review the fix only. Write root cause and early warning to context/learnings.md at close.
