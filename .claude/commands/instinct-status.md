---
description: Show all learned instincts with confidence levels
---

# Display Learned Instincts

Shows project and global instincts with confidence scores, apply counts, and domains.

## Usage

Basic:
```
/instinct-status
```

Filtered:
```
/instinct-status --domain testing
/instinct-status --confidence 0.7
```

## Requirements

Python 3.6+ must be installed. If not available, run:
```
bash scripts/bootstrap-phase8.sh
```

## Implementation

You must invoke the continuous-learning-v2 skill to execute this command.

The skill will:
1. Detect Python and instinct-cli.py location
2. Run: `python scripts/continuous-learning-v2/instinct-cli.py list [OPTIONS]`
3. Parse and display results with [PROJECT] or [GLOBAL] markers
4. If no instincts found, display "No instincts learned yet"

Do not implement this directly - invoke the continuous-learning-v2 skill.
