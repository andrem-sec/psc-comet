---
paths:
  - ".claude/skills/**"
  - ".claude/agents/**"
---

# Skill and Agent Format Rule

All files in `.claude/skills/` must follow the SKILL.md format:

```
---
name: skill-name
description: one-line description for registry display
version: 0.1.0
triggers:
  - "phrase that activates this skill"
context_files:
  - context/user.md        # only list files actually used
steps:
  - name: Step Name
    description: what this step does
---

# Skill Body
```

All files in `.claude/agents/` must include YAML frontmatter with at minimum:
- `name`
- `description`
- `tools` (explicit list — never grant all tools to a subagent)

Median target skill body size: 2-3 KB. If a skill exceeds 5 KB, split into focused modules or move content to `references/`.

Skills encode only what Claude lacks or consistently gets wrong — not general instructions Claude already follows well.
