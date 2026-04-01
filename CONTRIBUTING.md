# Contributing to Santa Claus

Santa Claus grows through contributed skills, agents, and improvements. This guide covers how to add each type of component, what the quality bar is, and how to run CI locally before opening a PR.

## Before You Start

1. Fork the repo and create a feature branch: `feat/your-skill-name`
2. Never commit directly to `main`
3. Run CI checks locally before pushing (see [Running CI Locally](#running-ci-locally))
4. Open a PR against `main` with a description of what you built and why

---

## Adding a Skill

Skills live in `.claude/skills/core/` (always-available) or `.claude/skills/workflow/` (task-specific). Each skill is a directory containing a `SKILL.md` file.

### Directory Structure

```
.claude/skills/workflow/your-skill/
└── SKILL.md
```

For skills with reference material:
```
.claude/skills/workflow/your-skill/
├── SKILL.md
└── references/
    └── reference-doc.md
```

### Required Frontmatter

Every `SKILL.md` must include all five fields:

```yaml
---
name: your-skill
description: One sentence — what this skill does and when to invoke it
version: 0.1.0
level: 1          # 1 = lightweight, 2 = standard, 3 = complex orchestration
triggers:
  - "exact phrase that should activate this skill"
  - "another trigger phrase"
---
```

**Level guidance:**
- `1` — runs fast, minimal steps, low overhead (examples: `checkpoint`, `model-router`)
- `2` — standard workflow with validation (examples: `tdd`, `refactor`)
- `3` — multi-step orchestration with gates (examples: `prd`, `security-gate`, `consensus-plan`)

### Required Body Sections

All core and workflow skills must include:

1. **What Claude Gets Wrong Without This Skill** — explain the failure mode this skill prevents. Be specific. This is the most important section.
2. **The skill's main content** — steps, tables, formats, protocols
3. **Anti-Patterns** — what Claude commonly does wrong that this skill corrects
4. **Mandatory Checklist** — numbered items starting with "Verify." At least 3 items.

```markdown
## Mandatory Checklist

1. Verify [specific thing was done]
2. Verify [specific thing was checked]
3. Verify [specific thing was confirmed]
```

The checklist must be concrete and actionable. "Verify the skill was applied correctly" is not a checklist item.

### Register in CLAUDE.md

Add your skill to the appropriate table in `.claude/CLAUDE.md`:

```markdown
| your-skill | 2 | "trigger phrase", use case description |
```

Keep CLAUDE.md under 200 lines.

### Add a Cowork Variant (Optional)

If your skill is useful in Claude.ai Cowork (no subdirectory support), add a single-file variant:

```
.claude/skills/cowork/your-skill.md
```

Frontmatter must include `platform: cowork`. Keep it to the essential steps — Cowork sessions are conversational, not filesystem-backed.

### Quality Bar

The `learner` skill defines the quality bar for contributed skills. Before submitting, ask:

- Can someone use this skill without reading any other file?
- Does the "What Claude Gets Wrong" section describe a real failure mode?
- Does the checklist catch the most common ways this skill gets misapplied?
- Are the triggers phrases a user would actually type?

---

## Adding an Agent

Agents live in `.claude/agents/`. Each agent is a single `.md` file.

### Required Frontmatter

```yaml
---
name: your-agent
description: When Claude should delegate to this agent — be specific, Claude uses this to decide
tools:
  - Read
  - Glob
  - Grep
model: sonnet       # haiku | sonnet | opus
permissionMode: dontAsk   # for read-only agents
---
```

**Only `name` and `description` are required by the platform, but all agents in this repo must also specify `tools` and `model` explicitly.**

### Constraint Patterns

| Agent type | Recommended configuration |
|------------|--------------------------|
| Read-only reviewer | `tools` allowlist (Read, Glob, Grep) + `permissionMode: dontAsk` |
| Read + run tests | `tools` allowlist (Read, Glob, Grep, Bash) + `permissionMode: dontAsk` |
| MCP-capable | `tools` list of specific MCP tool names + `permissionMode: dontAsk` |
| Orchestrator (main thread only) | `Agent` + Read/Glob/Grep/Bash |
| Isolated scanner | `isolation: worktree` + `permissionMode: dontAsk` + `hooks` |

**Do not use `disallowedTools` when a `tools` allowlist is already set** — the allowlist is stricter; `disallowedTools` is redundant.

**Do not use `context: fork`** — this field does not exist in the platform. Subagent isolation is inherent: every subagent runs in its own context window.

### Register in CLAUDE.md

Add to the Agent Registry table in `.claude/CLAUDE.md`.

---

## Adding a Hook

Hooks live in `.claude/hooks/`. Each hook is a shell script.

### Requirements

- Must be a `#!/usr/bin/env bash` script
- Must pass `bash -n` syntax check
- Read input via `INPUT=$(cat)` — Claude Code passes hook input as JSON via stdin
- Exit `0` to allow, `2` to block, `1` for non-blocking warning
- Write block/warning messages to stderr (`>&2`)
- Parse the command from input using `jq` or Python (both are typically available)

### Template

```bash
#!/usr/bin/env bash
# PreToolUse: Bash
# Brief description of what this hook does.

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$CMD" ]; then
    exit 0
fi

# Your logic here
# exit 2 to block, exit 0 to allow

exit 0
```

### Register in settings.json

After writing the hook, add it to `.claude/settings.json` under the appropriate lifecycle event:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": ".claude/hooks/your-hook.sh" }]
      }
    ]
  }
}
```

Also update `settings.global.json` with `~/.claude/hooks/your-hook.sh` paths.

---

## Running CI Locally

The CI runs two workflows. Run these before pushing:

### Validate skills and agents

```bash
# Check SKILL.md frontmatter
for f in $(find .claude/skills -name "SKILL.md"); do
  for field in name description version triggers level; do
    grep -q "^${field}:" "$f" || echo "FAIL: Missing '$field' in $f"
  done
done

# Check mandatory checklists
for f in $(find .claude/skills/core .claude/skills/workflow -name "SKILL.md"); do
  grep -q "## Mandatory Checklist" "$f" || echo "FAIL: Missing checklist in $f"
done

# Check agent frontmatter
for f in $(find .claude/agents -name "*.md"); do
  for field in name description tools; do
    grep -q "^${field}:" "$f" || echo "FAIL: Missing '$field' in $f"
  done
done

# Check CLAUDE.md line count
lines=$(wc -l < .claude/CLAUDE.md)
[ "$lines" -le 200 ] || echo "FAIL: CLAUDE.md is $lines lines (limit: 200)"
```

### Validate hooks

```bash
# Syntax check all hooks
for f in .claude/hooks/*.sh; do
  bash -n "$f" && echo "OK: $f" || echo "FAIL: $f"
done

# Validate settings.json
python3 -m json.tool .claude/settings.json > /dev/null && echo "OK: settings.json"
python3 -m json.tool .claude/settings.global.json > /dev/null && echo "OK: settings.global.json"
```

---

## Commit Style

Use conventional commits:

```
feat: add skill-name skill — one sentence description
fix: correct agent frontmatter field
docs: update CONTRIBUTING with hook template
refactor: simplify checkpoint checklist
```

For non-trivial commits, add decision trailers:

```
feat: add your-skill skill

Description of what was added and why.

Constraint: [what shaped the decision]
Rejected: [alternative considered and why it was rejected]
Confidence: high | medium | low
```

---

## What Makes a Good Contribution

Good skills and agents are:

- **Specific** — they do one thing and do it well
- **Honest about failure modes** — the "What Claude Gets Wrong" section is real, not hypothetical
- **Checklistable** — the mandatory checklist catches the most common misapplications
- **Cited** — if the design reflects a specific source or empirical finding, note it in the PR description

The full research rationale for existing design decisions is in `docs/design-decisions.md`. Read it before proposing structural changes — most design choices are there for a documented reason.
