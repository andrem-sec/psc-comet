# Project Santa Claus (Comet Branch)

Advanced Claude Code configuration suite with full ECC (Extended Claude Capabilities) integration. Drop `.claude/` into any project or `~/.claude/` for global authority.

**46 skills. 10 agents. 12 hooks. 38 commands.** Cross-session memory. Continuous learning system. Research-backed and validated against official Anthropic guidance.

## Quick Start

```bash
git clone -b comet https://github.com/Helpless2044/project_santa_clause.git
cd project_santa_clause

# Project-level (this project only):
cp -r .claude /path/to/your/project/

# Global (all Claude Code projects):
cp -r .claude ~/.claude/
cp .claude/settings.global.json ~/.claude/settings.json
```

Open Claude Code and run `/heartbeat`. Done.

**Every session:** `/heartbeat` at start. `/wrap-up` at end.

## What's New in Comet (ECC Phases 0-8)

This branch extends the stable `sc_v1` with:

### Phase 8: Continuous Learning System
- `continuous-learning-v2` skill (Level 3) — instinct tracking with confidence scoring
- `loop-operator` skill (Level 2) — autonomous loop management with safety gates
- Python CLI infrastructure (`scripts/continuous-learning-v2/instinct-cli.py`)
- Commands: `/instinct-status`, `/instinct-export`, `/instinct-import`, `/instinct-evolve`, `/projects`, `/promote`

### Phase 7: Workflow Tools
- `codebase-onboarding` (Level 3) — systematic 4-phase onboarding
- `safety-guard` (Level 2) — 3-mode safety guardrails
- `skill-comply` (Level 3) — compliance measurement
- `agent-harness-construction` (Level 3) — agent quality framework
- `context-budget` (Level 2) — token usage audit

### Phase 6: Meta-Improvement
- `skill-stocktake` (Level 3) — quality audit with Keep/Improve/Update/Retire verdicts
- `strategic-compact` (Level 2) — smart context compaction
- `agentic-engineering` (Level 3) — 15-minute unit rule + eval-first loop
- `deep-research` (Level 3) — multi-source research with citations

### Phase 5: Component Upgrades
- Enhanced `resume`, `lesson-gen`, `code-reviewer`, `tdd`, `model-router` skills

### Phase 4: Orchestration
- `/orchestrate` command — multi-agent workflow chaining
- `harness-optimizer` agent — meta-agent for improving the harness itself

### Phase 3: Eval Infrastructure
- `verification-loop` skill (Level 2)
- `eval-harness` skill (Level 3) — pass@k metrics
- `ai-regression-testing` skill (Level 3)

### Phase 2: Core Commands
- `/verify` — unified verification sweep (4 modes)
- `/aside` — context-preserving side questions
- `/eval` — eval-driven development

### Phase 1: Additional Hooks
- `pre-config-protection.sh` — blocks linter config changes
- `stop-check-console-log.sh` — scans for debug output
- `stop-cost-tracker.sh` — cost tracking (stub)

## Standard Workflows

```
/prd           → define requirements before building
/plan          → scope work, identify risks
/tdd           → write tests first, then implement
/code-review   → semantic review before merge
/security-gate → OWASP check before deploy
/commit        → conventional commit with decision context
```

**For new features:** `/feature` — orchestrates full pipeline automatically

**For bugs:** `/fix` — debug → regression test → fix → review

**For security ops:** `/heartbeat` → `roe` → `docker-sandbox`

**When unsure:** `intent-router` classifies and routes to correct skill

## Core Components

### Skills (46 total)

**Core (8):** heartbeat, wrap-up, lesson-gen, learner, remember, security-gate, project-scan, roe

**Workflow (38):** intent-router, prd, plan-first, tdd, code-review, checkpoint, debug-session, refactor, git-commit, model-router, token-budget, deep-interview, consensus-plan, resume, feature-pipeline, fix-pipeline, verification-loop, eval-harness, ai-regression-testing, continuous-learning-v2, loop-operator, codebase-onboarding, safety-guard, skill-comply, agent-harness-construction, context-budget, skill-stocktake, strategic-compact, agentic-engineering, deep-research, *and more*

Skill levels: **1** = lightweight, **2** = standard, **3** = complex orchestration

### Agents (10)

- `researcher` — read-only research and synthesis
- `planner` — phased implementation plans
- `architect` — ADR generation, steelman review
- `security-reviewer` — isolated OWASP audit
- `code-reviewer` — semantic anti-pattern review
- `verifier` — acceptance criteria verification
- `mcp-agent` — MCP operations isolated
- `orchestrator` — multi-agent mission coordinator
- `docker-sandbox` — autonomous security scanning
- `harness-optimizer` — meta-agent for harness improvement

### Commands (38)

Core workflow: `/heartbeat`, `/wrap-up`, `/prd`, `/plan`, `/tdd`, `/code-review`, `/security-gate`, `/commit`, `/checkpoint`, `/debug`, `/refactor`, `/resume`, `/feature`, `/fix`

Specialized: `/verify`, `/aside`, `/eval`, `/orchestrate`, `/deep-interview`, `/consensus-plan`, `/scan`, `/start-here`

Continuous learning: `/instinct-status`, `/instinct-export`, `/instinct-import`, `/evolve`, `/projects`, `/promote`

Advanced: `/retro`, `/benchmark`, `/canary`, `/cso`, `/investigate`, `/office-hours`, `/github-issue`, `/github-pr`, `/loop-start`, `/loop-status`

### Hooks (12)

**PreToolUse (3):** block-destructive, block-secrets-write, pre-config-protection

**PostToolUse (1):** warn-debug-output

**PreCompact (1):** preserve-on-compact

**InstructionsLoaded (1):** session-start

**Stop (4):** auto-review-on-stop, telemetry-log, stop-cost-tracker, stop-check-console-log

**Validation (2):** validate-scan-command, observe-instinct

## Context Files

Fill these with `/start-here` or `/scan`:

- `context/user.md` — profile, preferences (use `user.md.template`)
- `context/project.md` — stack, architecture, constraints
- `context/learnings.md` — accumulated session learnings (auto-updated)
- `context/decisions.md` — architectural decision log
- `context/security-standards.md` — project security requirements

## Installation Notes

### Python CLI (Optional)

The continuous learning system requires Python 3.6+:

```bash
# Check if available
python3 --version

# Install dependencies
cd scripts
pip install -r requirements.txt

# Bootstrap Phase 8
./bootstrap-phase8.sh
```

Without Python, instinct learning gracefully degrades (hooks become no-ops).

## Design Principles

1. **Skills = knowledge, MCP = execution** — Skills teach approach, MCP provides tools
2. **MCP isolated to one agent** — Prevents ~32K token overhead per message
3. **Review agents in fresh context** — Eliminates author bias
4. **Plan before 3+ files** — Compound reliability
5. **Directive imperatives in CLAUDE.md** — Survives context pressure
6. **Mandatory checklists** — Verifiable compliance
7. **Hooks are shell scripts** — Testable, linted
8. **Cross-session memory** — Gets smarter over time
9. **Drop-in portable** — No install, just copy

## Branch Comparison

- **sc_v1** (stable): 24 skills, 9 agents, 7 hooks, 18 commands — production-ready reference
- **comet** (this branch): 46 skills, 10 agents, 12 hooks, 38 commands — extended capabilities, continuous learning

## Research Foundation

Built against 91+ sources: Official Anthropic Docs, SkillsBench empirical benchmark, Boris Cherny (Claude Code creator), Long-Running Claude research, oh-my-claudecode, claude-skillz, New Stack Skills vs MCP framework.

Every architectural decision documented with citations in `docs/design-decisions.md`.

## License

MIT

---

**Note:** This is the development branch. For production stability, use `sc_v1`. For cutting-edge features and continuous learning, use `comet`.
