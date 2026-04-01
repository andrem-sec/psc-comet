---
description: Export learned instincts to JSON file for sharing
---

# Export Instincts

Exports all instincts (project + global) to portable JSON format for sharing with teammates.

## Usage

Export to stdout:
```
/instinct-export
```

Save to file:
```
/instinct-export --output instincts.json
```

## Security Note

Review exported file before sharing. Remove:
- Project-specific secrets or API keys in evidence fields
- Proprietary patterns or internal tool names
- File paths that reveal internal structure

## Implementation

Invoke the continuous-learning-v2 skill. The skill will run:
```
python scripts/continuous-learning-v2/instinct-cli.py export [--output FILE]
```
