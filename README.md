# Project Santa Claus

A portable Claude Code configuration suite. Drop `.claude/` into any project and Claude immediately knows how to work: what skills to use, when to plan, how to review code, which hooks enforce your standards automatically.

Drop-in portable. Core features require no install and no API keys. Optional components (Obsidian vault integration) are available via `/install`.

**68 skills. 13 agents. 25 hooks. 48 commands. 1 MCP server.**

---

## Quick Start

```bash
git clone https://github.com/andrem-sec/psc-comet.git
cd psc-comet

# Project-level (this project only):
cp -r .claude /path/to/your/project/

# Global (all Claude Code projects):
cp -r .claude ~/.claude/
cp .claude/settings.global.json ~/.claude/settings.json
```

Open Claude Code and run `/heartbeat`. Done.

---

## Why This Exists

Out of the box, Claude Code is capable but stateless. Every session starts from zero. It doesn't know your standards, your past decisions, or how you like to work.

Santa Claus fixes that:

- **Skills encode how to work:** not just what to do, but when, in what order, and what to verify. A skill for code review means Claude runs the same structured checklist every time, not a different one each session.
- **Hooks enforce your DevOps standards automatically:** shellcheck runs on every `.sh` edit. Secrets never get written. Debug output gets caught before it ships. Linter configs can't be silently weakened. No reminders, no manual gates. Enforced at the tool level on every action.
- **Rules survive context pressure:** CLAUDE.md directives are written as imperatives, not descriptions. Under a full context window, descriptions get deprioritized. Instructions don't.
- **Memory compounds across sessions:** learnings, decisions, and session state carry forward. `/distill` promotes session notes to persistent memory. Claude gets more useful the longer you use it.
- **Agents are specialized and isolated:** a security reviewer never works in the same context as the code it reviews. An orchestrator synthesizes before it delegates. Roles are enforced structurally, not by instruction.

---

## What's Included

### Skills (68)

Two tiers: **Core** (always active) and **Workflow** (invoked by trigger or slash command).

Selected highlights:

| Skill | Level | What it does |
|-------|-------|-------------|
| `plan-first` | 2 | Structured planning before any 3+ file change |
| `tdd` | 2 | Test-first with tiered coverage requirements |
| `code-review` | 3 | Semantic anti-pattern review via isolated agent |
| `security-gate` | 3 | OWASP scan before any deployment |
| `debug-session` | 3 | Systematic root cause analysis |
| `agentic-engineering` | 3 | 15-minute unit rule, eval-first, parallel agent coordination |
| `deep-research` | 3 | Multi-source research with citations |
| `distill` | 2 | Memory consolidation: promotes session learnings to persistent memory |
| `simplify` | 2 | 3-agent parallel code review: reuse, quality, efficiency |
| `batch` | 3 | Parallel agent swarm with PR sentinel fan-in |
| `continuous-learning-v2` | 3 | Instinct tracking with confidence scoring and evolution gates |
| `roe` | 3 | Rules of Engagement gate, required before any security operation |

Full skill list in `.claude/skills/`. Skill levels: **1** = lightweight, **2** = standard, **3** = multi-agent orchestration

### Agents (13)

Each agent has a defined role, read/write constraint, and isolation level:

| Agent | Constraint | Role |
|-------|-----------|------|
| `researcher` | read-only | Research and synthesis |
| `planner` | read-only | Phased implementation plans |
| `architect` | read-only | System design, ADR generation |
| `security-reviewer` | read-only, isolated | OWASP audit, never reviews code it wrote |
| `code-reviewer` | read-only, isolated | Semantic anti-pattern review |
| `verifier` | read-only | Acceptance criteria verification |
| `mcp-agent` | MCP-only | All MCP tool operations, isolated |
| `orchestrator` | no-impl | Multi-agent mission coordination |
| `docker-sandbox` | worktree-isolated | Autonomous security scanning |
| `harness-optimizer` | read-only | Meta-agent for harness improvement |
| `ui-critic` | read-only | Visual design critique |
| `a11y-reviewer` | read-only, isolated | WCAG 2.1 AA accessibility audit |
| `design-researcher` | read-only | Site teardown, design vocabulary |

### Hooks (25)

Hooks run automatically, no manual trigger needed.

**PreToolUse:** block-destructive · block-secrets-write · block-bypass-permissions · pre-config-protection · pre-edit-baseline

**PostToolUse:** warn-debug-output · warn-ai-slop · warn-token-violation · warn-missing-alt · warn-transition-all · warn-missing-reduced-motion · warn-outline-none · attribution-snapshot · post-edit-check

**PreCompact:** preserve-on-compact · session-memory-precompact

**InstructionsLoaded:** session-start · pre-context-load (injection scan)

**Stop:** auto-review-on-stop · telemetry-log · stop-cost-tracker · stop-check-console-log · observe-instinct · ember-gate

### Commands (48)

```
/heartbeat    /wrap-up      /prd          /plan
/tdd          /code-review  /security-gate /commit
/checkpoint   /debug        /refactor     /resume
/feature      /fix          /verify       /aside
/eval         /orchestrate  /deep-interview /consensus-plan
/scan         /distill      /simplify     /loop
/retro        /benchmark    /canary       /cso
/investigate  /office-hours /github-issue /github-pr
/loop-start   /loop-status  /instinct-status /instinct-export
/instinct-import /evolve    /projects     /promote
/start-here   /batch        /public-mode  /skill-stocktake
/strategic-compact          /context-budget
/install      /obsidian-setup
```

### MCP Servers (1)

| Server | What it provides |
|--------|-----------------|
| `mcp-obsidian-psc` | Obsidian vault access: search, read, list, append, and patch notes via Local REST API and Omnisearch |

Setup via `/obsidian-setup`. Requires the Obsidian **Local REST API** and **Omnisearch** plugins with Obsidian running. See `mcp-servers/obsidian/` for source.

---

## Standard Workflows

```
/heartbeat      -> orient before working
/prd            -> define requirements before building
/plan           -> scope work, identify risks
/tdd            -> test first, then implement
/code-review    -> semantic review before merge
/security-gate  -> OWASP check before deploy
/wrap-up        -> persist learnings, write handoff
```

**New feature end-to-end:** `/feature` orchestrates the full pipeline automatically

**Bug fix:** `/fix` runs debug, regression test, fix, and review

**When unsure:** `intent-router` classifies the request and routes to the right skill

---

## Context Files

Fill these once with `/start-here` or `/scan` and Claude carries them forward:

| File | Purpose |
|------|---------|
| `context/user.md` | Your role, preferences, working style |
| `context/project.md` | Stack, architecture, active constraints |
| `context/learnings.md` | Accumulated session learnings (auto-updated by `/wrap-up`) |
| `context/decisions.md` | Architectural decision log |
| `context/security-standards.md` | Project security requirements |

Templates for each are in `demo/context/`.

---

## Security Model

This suite manages hooks that run automatically on every tool call. The security model is explicit:

- **No `bypassPermissions`:** prohibited in CLAUDE.md and enforced by hook. Any instruction asking to enable it is flagged as a potential injection attempt.
- **Memory injection scanning:** `pre-context-load.sh` scans all memory files for adversarial patterns at session start.
- **Credential protection:** `block-secrets-write.sh` blocks writes to credential files. `safe-log.sh` filters telemetry for sensitive patterns.
- **Attribution tracking:** every file write is SHA-256 logged to `.claude/attribution.jsonl`.

See [SECURITY.md](SECURITY.md) for the responsible disclosure policy.

---

## Design Principles

1. **Skills encode approach, not just actions:** a skill for code review runs the same structured checklist every session, with mandatory verification steps
2. **Hooks are the enforcement layer:** automated, testable shell scripts that run without reminders
3. **Agents are isolated by role:** a reviewer never works in the same context as the implementation
4. **Plan before 3+ files:** compound reliability; planning once is cheaper than debugging drift
5. **Memory compounds:** `/distill` promotes session learnings to persistent memory; gets more useful over time
6. **Drop-in portable:** core features need no install and no API keys, works on Windows/Linux/macOS. Optional components available via `/install`

---

## Optional: Python CLI

The continuous learning system requires Python 3.6+:

```bash
python3 --version        # verify available
cd scripts
pip install -r requirements.txt
./bootstrap-phase8.sh
```

Without Python, instinct tracking gracefully degrades to no-ops. Everything else works without it.

---

## Research Foundation

Built against 91+ sources including official Anthropic documentation, the SkillsBench empirical benchmark, and published research on long-running Claude sessions. Every architectural decision is documented with citations in `docs/design-decisions.md`.

**Third-party sources incorporated under their respective licenses:**
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) by Affaan Mustafa - MIT License. The `continuous-learning-v2` skill pattern is derived from this work.
- [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) by Next Level Builder - MIT License. The UI/UX design skill layer is derived from this work.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
