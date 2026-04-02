# Contributing

Project Santa Clause is **source-available**. The code is public and free to read, fork, and use under the MIT License. Active development is maintained by a closed circle of collaborators.

## For Public Users

You are welcome to:
- Read, fork, and adapt the project for your own use
- Open an **Issue** to report a bug or suggest an improvement
- Share what you build with it

External pull requests are not accepted. If you want to contribute directly, see [Becoming a Collaborator](#becoming-a-collaborator) below.

## Filing an Issue

Issues are the right channel for:
- Bug reports (hook fails in a specific environment, CI breaks on a valid file)
- Feature suggestions (new skill idea, hook improvement)
- Documentation gaps

When filing a bug: include your OS, Claude Code version, and the exact hook or skill that failed. Paste the hook output if available.

## Becoming a Collaborator

Collaborator access is by invitation. If you've been using the project and want to contribute directly, open an Issue titled **"Collaborator request"** and describe what you'd like to work on. Requests are reviewed periodically.

## For Invited Collaborators

### Branch and PR workflow

- Work on a feature branch: `feat/your-change` or `fix/what-you-fixed`
- Never commit directly to `main` or `comet`
- Open a PR with a description of what changed and why
- CI must pass before merge

### Skill format

Every `SKILL.md` requires this frontmatter:

```yaml
---
name: skill-name
description: One sentence — what it does and when to invoke it
version: 0.1.0
level: 1          # 1 = lightweight, 2 = standard, 3 = complex orchestration
triggers:
  - "phrase that activates this skill"
---
```

Required body sections: **What Claude Gets Wrong Without This Skill**, the skill content, **Anti-Patterns**, and a numbered **Mandatory Checklist** (minimum 3 "Verify…" items).

Register new skills in `.claude/CLAUDE.md`. Keep CLAUDE.md under 200 lines.

### Hook format

Hooks are `#!/usr/bin/env bash` scripts in `.claude/hooks/`. Requirements:
- Pass `bash -n` syntax check and `shellcheck`
- Read input via `INPUT=$(cat)` (JSON from stdin)
- Exit `0` allow · `1` warn · `2` block
- Register in `.claude/settings.json` and `.claude/settings.global.json`

### Commit style

```
feat: add skill-name — one sentence why
fix: correct pattern in hook-name
docs: update contributing guide
```

Non-trivial commits should include trailers:
```
Constraint: [what shaped the decision]
Rejected: [alternative and why it was dropped]
Confidence: high | medium | low
```

### Running CI locally

```bash
# Validate skills and agents
for f in $(find .claude/skills -name "SKILL.md"); do
  for field in name description version triggers level; do
    grep -q "^${field}:" "$f" || echo "FAIL: Missing '$field' in $f"
  done
done

# Validate mandatory checklists
for f in $(find .claude/skills/core .claude/skills/workflow -name "SKILL.md"); do
  grep -q "## Mandatory Checklist" "$f" || echo "FAIL: Missing checklist in $f"
done

# Validate hooks
for f in .claude/hooks/*.sh; do
  bash -n "$f" && shellcheck "$f" && echo "OK: $f"
done

# Validate settings.json
python3 -m json.tool .claude/settings.json > /dev/null && echo "OK: settings.json"

# Check CLAUDE.md line count
lines=$(wc -l < .claude/CLAUDE.md)
[ "$lines" -le 200 ] || echo "FAIL: CLAUDE.md is $lines lines (limit: 200)"
```
