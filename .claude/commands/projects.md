---
description: List all projects with learned instincts
---

# List Projects with Instincts

Shows all projects in ~/.claude/homunculus/ with instinct counts and last updated timestamps.

## Usage

```
/projects
```

## Output

For each project:
- Project name
- Git remote URL
- Project instinct count
- Global instinct count
- Last updated (most recent instinct modification)

## Example

```
my-project (https://github.com/user/my-project)
  Project instincts: 15
  Global instincts: 3
  Last updated: 2026-03-28 14:30:00

another-project (https://github.com/user/another-project)
  Project instincts: 8
  Global instincts: 3
  Last updated: 2026-03-27 10:15:00
```

## Implementation

Invoke continuous-learning-v2 skill. The skill will run:
```
python scripts/continuous-learning-v2/instinct-cli.py projects
```
