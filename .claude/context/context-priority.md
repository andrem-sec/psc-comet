---
loaded-by:
  - heartbeat
---

# Context File Priority Order

When two context files give conflicting guidance, the higher-priority file wins.

## Hierarchy (highest to lowest)

1. `CLAUDE.md` -- absolute rules, security invariants, code constraints
2. `context/principles.md` -- active operational principles with override protocol
3. `context/user.md` -- user profile, preferences, working style
4. `context/project.md` -- project stack, constraints, current state
5. `context/learnings.md` -- standing rules; applies every session regardless of task
6. `context/learnings/[tag].md` -- session-specific patterns; loaded on demand
7. `context/decisions.md` -- ADR log; reference only, not binding rules

## Conflict Resolution

Apply the higher-priority file's instruction. If the conflict cannot be resolved by priority
alone (e.g., two principles at the same level), surface it to the user before proceeding.

Do not silently pick one side of a conflict. The user must know when files disagree.

## Cache Efficiency Note

The Anthropic prompt cache has a 5-minute TTL. Load stable files first to keep the cache
prefix intact across tool calls within a session:

- Stable prefix: `CLAUDE.md`, `principles.md`, `user.md`, `security-standards.md`
- Dynamic suffix: `project.md`, `learnings.md`, tagged files, `decisions.md`

Stable files change rarely. Dynamic files change each session or each task.
Loading stable files first means subsequent tool calls hit the cache for those files
rather than re-encoding them.
