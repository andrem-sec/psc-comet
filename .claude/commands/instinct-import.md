---
description: Import instincts from teammates or other projects
---

# Import Instincts

Merges instincts from JSON file into current project. Handles ID conflicts by keeping higher confidence version.

## Usage

```
/instinct-import instincts.json
```

## Conflict Resolution

If imported instinct ID already exists:
- Compare confidence scores
- Keep version with higher confidence
- Log conflict resolution to learnings.md

## Safety

Imported instincts start with their original confidence. To prevent untrusted patterns:
- Review imported file first
- Low-confidence imports (<0.5) require manual verification
- Global scope imports require approval

## Implementation

Invoke continuous-learning-v2 skill. The skill will run:
```
python scripts/continuous-learning-v2/instinct-cli.py import FILE
```
