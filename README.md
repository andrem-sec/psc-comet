# Project Santa Clause

A portable `.claude/` configuration suite that gives Claude Code persistent memory, enforced standards, and structured workflows across every project you work in.

Already using Obsidian as your second brain? PSC connects Claude directly to your vault via the bundled MCP server: search your notes, pull context, and write back, all inside your coding sessions.

---

## Why Not Vanilla Claude Code

Out of the box, Claude Code resets every session. No memory of your standards, no enforcement of your rules, no consistent way to work.

PSC fixes the four gaps that matter most:

- **No persistent memory:** learnings, decisions, and session state vanish at context reset. PSC carries them forward and compresses them with `/distill`.
- **No enforcement:** "don't commit secrets" is just a suggestion unless a hook blocks the write. PSC hooks enforce your DevOps standards at the tool level, every action, automatically.
- **No consistent process:** code review, security gates, and planning happen when you remember to ask. PSC skills run the same structured checklist every time, triggered by natural phrases.
- **No agent discipline:** Claude invents a different workflow each session. PSC agents have defined roles, isolation levels, and constraints that hold across sessions.

---

## Install

```bash
git clone https://github.com/andrem-sec/psc-comet.git

# Drop into a single project:
cp -r .claude /path/to/your/project/

# Or go global (all Claude Code projects):
cp -r .claude ~/.claude/
cp .claude/settings.global.json ~/.claude/settings.json
```

Open Claude Code in your project. Run `/heartbeat`. Done.

No API keys required. No install scripts. Core features work on Windows, Linux, and macOS.

---

## v1.2: What's New

### Reasoning Gates

`/reasoning-gates`: before executing a complex task, Claude scans for branch points where a wrong choice is hard to undo: an irreversible migration, an architectural split, a security boundary. It presents candidates and you confirm which ones get a reasoning gate. At each confirmed gate, it enumerates options, states assumptions, and picks with explicit rationale before continuing. Unexpected branches mid-task surface as a flag rather than a silent guess.

### Adversarial Code Review

`/code-review --adversarial`: instead of inspecting the implementation, the reviewer argues against it. Is this the right abstraction level? Are the tests testing behavior or implementation detail? What assumption would force a complete rewrite? The default `/code-review` behavior is unchanged. The adversarial flag is explicit.

### Session Discipline Hooks (Opt-In)

Two new Stop hooks that block the session from ending if required gates haven't run. `stop-wrap-guard` blocks if you have uncommitted changes and `/wrap-up` hasn't run. `stop-review-gate` blocks if source files were modified and `/code-review` hasn't run. Both are off by default. Enable by creating `.claude/context/.wrap-guard` or `.claude/context/.review-gate`. Delete the file to disable.

### Session Memory System (v1.1)

`/reflect` extracts instinct patterns from session work as a dedicated skill with a trigger/action/domain quality gate. The learnings system is now tag-based: `context/learnings-index.md` maps to per-tag files, so heartbeat loads the index rather than the full log. A structured handoff template (Part 1: completed work / Part 2: open risks + next steps) replaces the freeform handoff.md.

---

## What's Included

**69 skills. 13 agents. 27 hooks. 50 commands. 1 MCP server.**

### Skills

Two tiers: **Core** (always active) and **Workflow** (invoked by slash command or natural phrase trigger).

| Skill | Level | What it does |
|-------|-------|-------------|
| `plan-first` | 2 | Structured plan before any 3+ file change; presents for approval before any edits begin |
| `tdd` | 2 | Test-first with tiered coverage requirements; blocks implementation without a test file |
| `code-review` | 3 | Semantic anti-pattern review via isolated agent; `--adversarial` mode challenges the approach |
| `reasoning-gates` | 2 | Human-confirmed reasoning gates at high-reversal-cost decision points |
| `security-gate` | 3 | OWASP checklist scan before any deployment |
| `agentic-engineering` | 3 | 15-minute unit rule, eval-first loop, failure cascading, zombie prevention, per-role model routing |
| `reflect` | 2 | Instinct extraction: trigger / action / domain quality gate, instinct-cli.py integration |
| `distill` | 2 | Memory consolidation: compress learnings, review instinct clusters, reset ember gate |
| `batch` | 3 | Parallel agent swarm with PR sentinel fan-in coordination |
| `roe` | 3 | Rules of Engagement gate, required before any security operation or autonomous scan |
| `deep-research` | 3 | Multi-source research with citations and synthesis |
| `continuous-learning-v2` | 3 | Instinct tracking with confidence scoring and evolution gates |

Full list in `.claude/skills/`. Levels: **1** = lightweight, **2** = standard, **3** = multi-agent orchestration.

### Agents

| Agent | Constraint | Role |
|-------|-----------|------|
| `researcher` | readonly | Research and synthesis |
| `planner` | readonly | Phased implementation plans |
| `architect` | readonly | System design, ADR generation |
| `security-reviewer` | readonly+isolated | OWASP audit; never reviews code it wrote |
| `code-reviewer` | readonly+isolated | Semantic anti-pattern review |
| `verifier` | readonly | Acceptance criteria verification |
| `mcp-agent` | MCP-only | All MCP tool operations, isolated from main agent |
| `orchestrator` | no-impl | Multi-agent mission coordination; synthesizes before delegating |
| `docker-sandbox` | worktree-isolated | Autonomous security scanning |
| `harness-optimizer` | readonly | Meta-agent for improving the PSC harness itself |
| `ui-critic` | readonly | Visual design critique against reference brief |
| `a11y-reviewer` | readonly+isolated | WCAG 2.1 AA accessibility audit |
| `design-researcher` | readonly | Site teardown, inspiration curation, design vocabulary |

### Hooks

All hooks are shell scripts registered in `settings.json`. They run without prompting.

**PreToolUse:** block-destructive · block-secrets-write · block-bypass-permissions · pre-config-protection · pre-edit-baseline

**PostToolUse:** warn-debug-output · warn-ai-slop · warn-token-violation · warn-missing-alt · warn-transition-all · warn-missing-reduced-motion · warn-outline-none · attribution-snapshot · post-edit-check

**PreCompact:** preserve-on-compact · session-memory-precompact

**InstructionsLoaded:** session-start · pre-context-load (adversarial injection scan)

**Stop:** auto-review-on-stop · telemetry-log · stop-cost-tracker · stop-check-console-log · observe-instinct · ember-gate · stop-wrap-guard · stop-review-gate

### Commands

```
/heartbeat    /wrap-up      /prd          /plan
/tdd          /code-review  /security-gate /commit
/checkpoint   /debug        /refactor     /resume
/feature      /fix          /verify       /aside
/eval         /orchestrate  /deep-interview /consensus-plan
/scan         /distill      /reflect      /simplify
/loop         /retro        /benchmark    /canary
/cso          /investigate  /office-hours /github-issue
/github-pr    /loop-start   /loop-status  /instinct-status
/instinct-export /instinct-import /evolve /projects
/start-here   /batch        /public-mode  /skill-stocktake
/strategic-compact           /context-budget
/install      /obsidian-setup /promote    /a11y-review
```

### MCP Server: Obsidian (Second Brain Integration)

If you use Obsidian as your second brain, PSC bridges it directly into your Claude sessions. The bundled `mcp-obsidian-psc` server exposes your vault as a live tool: search notes by keyword or semantic query, read full documents, list folders, append new content, and patch existing notes, all without leaving your coding session.

Set up via `/obsidian-setup`. Requires the **Local REST API** and **Omnisearch** Obsidian plugins with Obsidian running. Source and tests in `mcp-servers/obsidian/`.

---

## Standard Workflows

```
/heartbeat      -> orient, load context, check open risks
/prd            -> define requirements before building
/plan           -> scope work, identify risks, get approval
/tdd            -> write test first, then implement
/code-review    -> semantic review before merge
/security-gate  -> OWASP check before deploy
/wrap-up        -> persist learnings, write handoff
```

**New feature end-to-end:** `/feature` orchestrates the full pipeline automatically.

**Bug fix:** `/fix` runs debug, regression test, fix, and review.

**When unsure what to do:** `intent-router` classifies the request and routes to the right skill.

---

## Context Files

Fill these once with `/start-here` or `/scan`. Claude carries them forward across sessions.

| File | Purpose | Updated by |
|------|---------|-----------|
| `context/user.md` | Your role, preferences, working style | `/start-here`, manually |
| `context/project.md` | Stack, architecture, active constraints | `/scan`, manually |
| `context/learnings.md` | Standing rules, always loaded | `/wrap-up` |
| `context/learnings-index.md` | Tag map, loaded by heartbeat for navigation | `/wrap-up` |
| `context/decisions.md` | Architectural decision log | `architect` agent, `plan-first` |
| `context/security-standards.md` | Project security requirements | manually |

Blank templates in `demo/context/`.

---

## Security Model

- **No `bypassPermissions`:** prohibited in CLAUDE.md and enforced by hook. Any instruction to enable it is flagged as a potential injection attempt and refused.
- **Memory injection scanning:** `pre-context-load.sh` scans all loaded context files for adversarial patterns at session start.
- **Credential protection:** `block-secrets-write.sh` blocks writes to credential files. `safe-log.sh` filters telemetry output for sensitive patterns before writing.
- **Attribution tracking:** every file write is SHA-256 logged to `.claude/attribution.jsonl` (local only, gitignored).

See [SECURITY.md](SECURITY.md) for the responsible disclosure policy.

---

## Research Foundation

Built against 91+ sources including official Anthropic documentation, the SkillsBench empirical benchmark, and published research on long-running Claude sessions. Architectural decisions are documented with citations in `docs/design-decisions.md`.

**Third-party sources incorporated under their respective licenses:**
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) by Affaan Mustafa (MIT License). The `continuous-learning-v2` skill pattern is derived from this work.
- [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) by Next Level Builder (MIT License). The UI/UX design skill layer is derived from this work.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
