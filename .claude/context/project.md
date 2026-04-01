# Project Context

Populated by `/start-here` and updated by skills as the project evolves. Read by `heartbeat`, `plan-first`, `prd`, and `debug-session`.

## Identity

- **Project name:** Project Santa Claus (psc_comet branch)
- **Type:** Advanced Claude Code configuration suite (skills, agents, hooks, commands)
- **Status:** Active development (extends sc_v1 reference architecture)
- **Repository:** github.com/yourusername/project_santa_clause (branch: comet)

## Tech Stack

- **Language(s):** Markdown (skill/agent/command definitions), Bash (hooks), JSON (settings)
- **Framework(s):** Claude Code native primitives (skills, agents, hooks, CLAUDE.md)
- **Database:** None (local JSONL telemetry logs)
- **Infrastructure:** Local filesystem, no external dependencies
- **Key dependencies:**
  - Python 3.6+ (JSON parsing in hooks, optional with fallback)
  - Bash 4.0+ (hook execution)
  - Git 2.0+ (optional, for modified file detection)

## Architecture

psc_comet is the development branch of Project Santa Claus, extending sc_v1 (the stable reference architecture) with additional workflow skills, telemetry hooks, and ECC-inspired features. Skills teach Claude how to approach problems. Agents are specialized subprocesses with constrained tool access. Hooks are Bash scripts that fire on lifecycle events. Everything composes without external dependencies.

- **Entry points:** `.claude/CLAUDE.md` (loaded by Claude Code on session start)
- **Core modules:**
  - `.claude/skills/` -- Skills split into core/, workflow/, and ui/ subdirectories
  - `.claude/agents/` -- 12 specialized agents (9 original + ui-critic, a11y-reviewer, design-researcher)
  - `.claude/hooks/` -- 17 hooks (10 original + 7 new UI/a11y hooks)
  - `.claude/commands/` -- 46 slash commands (38 original + 8 new UI commands)
  - `.claude/context/` -- 5 persistent context files
  - `.claude/context/telemetry/` -- Local JSONL logs (skill-usage, costs, debug-warnings)
- **External services:** None (fully local)

## Hook Inventory (17 Total)

**PreToolUse Hooks (3):**
1. `block-destructive.sh` (Bash) -- Blocks rm -rf, git push --force, DROP TABLE
2. `block-secrets-write.sh` (Write) -- Blocks writes to .env, credentials files
3. `pre-config-protection.sh` (Write|Edit) -- Blocks writes to 43 linter/formatter configs

**PostToolUse Hooks (8):**
1. `warn-debug-output.sh` (Edit|Write) -- Warns on console.log, print(), debugger
2. `warn-ai-slop.sh` (Edit|Write) -- Warns on AI violet/purple hex palette and unanchored gradients
3. `warn-token-violation.sh` (Edit|Write) -- Warns on raw hex values in component files
4. `warn-missing-alt.sh` (Edit|Write) -- Warns on img elements missing alt attribute (WCAG 1.1.1)
5. `warn-transition-all.sh` (Edit|Write) -- Warns on transition: all (layout recalculation)
6. `warn-missing-reduced-motion.sh` (Edit|Write) -- Warns on animations without prefers-reduced-motion
7. `warn-outline-none.sh` (Edit|Write) -- Warns on outline: none without focus-visible replacement

**PreCompact Hooks (1):**
1. `preserve-on-compact.sh` -- Reminds to capture state before compaction

**InstructionsLoaded Hooks (1):**
1. `session-start.sh` -- Validates context files, frontloads skills

**Stop Hooks (5):**
1. `auto-review-on-stop.sh` -- Surfaces modified files, reminds review
2. `telemetry-log.sh` -- Logs session outcome to skill-usage.jsonl
3. `stop-cost-tracker.sh` -- Logs token/cost (STUB - awaiting upstream)
4. `stop-check-console-log.sh` -- Scans modified files for debug output
5. `observe-instinct.sh` -- Phase 8: continuous learning observation

## Constraints

Constraints that actively shape decisions. These are not preferences -- they are things that cannot be changed.

- No external dependencies -- must be fully portable (drop-in .claude/ directory)
- No package managers or build steps -- hooks must be plain Bash
- Python 3 recommended but optional (hooks have fallback handling)
- Hooks must pass shellcheck validation (enforced in CI on sc_v1)
- CLAUDE.md must stay under 200 lines (context window pressure)
- sc_v1 is the structural reference -- divergences require justification

## Current State

- **What works:** Full hook ecosystem (17 hooks), telemetry logging (3 JSONL files), agent framework (12 agents), skill registry (47 skills), slash commands (46 commands), frontend/UI/UX suite
- **In progress:** Nothing — all planned phases complete as of 2026-03-30
- **Known issues:**
  - stop-cost-tracker.sh is a stub (Stop hooks lack token/cost data from Claude Code)
  - Not a git repository locally (affects git-based hooks, fallback to 5-minute file scan)
  - Python 3 not installed on Windows (hooks use bash fallback for JSON encoding)
- **Frontend/UI/UX Suite (2026-03-30):**
  - 9 workflow skills: brand-context, inspiration-brief, site-teardown, screenshot-loop, component-spec, ui-slop-guard, design-token-guard, animation-safe, responsive-design
  - 3 agents: ui-critic, a11y-reviewer, design-researcher
  - 7 UI hooks (all PostToolUse): warn-ai-slop, warn-token-violation, warn-missing-alt, warn-transition-all, warn-missing-reduced-motion, warn-outline-none
  - 8 commands: /brand-context, /inspiration-brief, /site-teardown, /screenshot-loop, /component-spec, /ui-slop-guard, /design-token-guard, /a11y-review
  - ui-ux-pro-max knowledge layer: 76 CSV databases, BM25 search, 7 skill directories in skills/ui/

## Do Not

Approaches that were tried and rejected, or explicit prohibitions for this project:

- Do not add MCP tools to main agent -- use mcp-agent to avoid ~32K token overhead
- Do not have subagents write code to files -- subagents research/plan, parent implements
- Do not exceed 200 lines in CLAUDE.md -- context pressure degrades instruction following
- Do not add package manager or install step -- portability is hard constraint
- Do not diverge from sc_v1 structural patterns without documenting rationale in decisions.md

## Deployment

- **Environments:** Local installation
- **Deploy process:** Copy .claude/ directory to target project or ~/.claude/ for global scope
- **Rollback:** Restore previous .claude/ directory from backup or git checkout

## Recent Changes (2026-03-30)

**Frontend/UI/UX Suite (all phases complete):**
- Added 9 workflow skills for UI development lifecycle (brand → brief → build → QA → ship)
- Added 3 agents: ui-critic (visual critique), a11y-reviewer (WCAG 2.1 AA), design-researcher (teardown/inspiration)
- Added 7 UI/accessibility PostToolUse hooks (warn-ai-slop, warn-token-violation, warn-missing-alt, warn-transition-all, warn-missing-reduced-motion, warn-outline-none)
- Added 8 slash commands for UI workflow
- Integrated ui-ux-pro-max knowledge layer (76 CSVs, BM25 search, 49 reference markdowns)
- Updated CLAUDE.md registry: 185 lines (under 200-line limit)
- Hook count: 10 → 17 | Agent count: 9 → 12 | Command count: 38 → 46

---
*Last updated: 2026-03-30 (Frontend/UI/UX suite complete)*
