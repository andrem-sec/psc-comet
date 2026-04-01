# Changelog

All notable changes to Santa Claus are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

---

## [Unreleased]

### Phase 7 — Added
- `CONTRIBUTING.md` — full contributor guide covering skills, agents, hooks, CI, and quality bar
- `demo/` directory — filled context file examples (user, project, learnings, decisions) and session walkthrough showing heartbeat → intent-router → deep-interview → prd → plan → tdd → security review → wrap-up
- `release.yml` GitHub Actions workflow — fires on `v*.*.*` tags; runs full pre-release validation, builds `.zip` archive, extracts CHANGELOG notes, creates GitHub Release
- `README.md` — final pass with accurate counts (24 skills, 9 agents, 7 hooks, 18 commands, 14 cowork variants), corrected design principles, updated agent constraint descriptions
- Tagged `v1.0.0`

### Phase 6 — Added
- New core skill: `roe` — Rules of Engagement authorization gate with five mandatory elements (authorization, scope in, scope out, time window, escalation contact); PROCEED / HOLD verdict; required before any security operation or autonomous scan
- New workflow skill: `intent-router` — classifies ambiguous requests into eight categories and routes to the correct first skill before any execution; security operations always route to `roe` first
- New agent: `docker-sandbox` — isolated autonomous scanning agent using three native platform layers: `isolation: worktree`, `permissionMode: dontAsk`, and `PreToolUse: Bash` hook (`validate-scan-command.sh`); `roe` skill preloaded via `skills` frontmatter field
- New hook: `validate-scan-command.sh` — PreToolUse Bash validator for docker-sandbox; blocks destructive operations, git write operations, data exfiltration patterns, and runtime package installation
- New Cowork variants: `roe.md`, `intent-router.md` — Cowork layer now at 14 skills
- Design decisions 17–19 added (ROE gate, intent routing, native isolation primitives)
- CLAUDE.md updated with 2 new skills and 1 new agent in registries (111 lines)

### Phase 5 — Added
- New workflow skill: `deep-interview` — Socratic problem exploration with 7-category critical unknown identification and ≤20% ambiguity gate
- New workflow skill: `consensus-plan` — Planner → Architect deliberation loop, steelman protocol, pre-mortem for HIGH risk, ADR output to context/decisions.md
- New workflow skill: `resume` — reconstructs interrupted mid-task session from context/learnings.md state entries
- New workflow skill: `feature-pipeline` — full feature workflow orchestrator (deep-interview → prd → plan → tdd → review → security-gate) with gate protocol and stage selection matrix
- New workflow skill: `fix-pipeline` — bug fix workflow orchestrator (debug-session → regression test → fix → review) with mandatory learnings close
- `planner` agent updated with consensus mode: revision round protocol, explicit acknowledgment of objection required
- `architect` agent updated with structured consensus mode output format: one objection, steelman, minimum resolution, verdict
- New commands: `/deep-interview`, `/consensus-plan`, `/resume`, `/feature`, `/fix`
- New Cowork variants: `deep-interview.md`, `resume.md` — Cowork layer now at 12 skills
- CLAUDE.md updated with 5 new skills in registry (105 lines)

### Phase 4 — Added
- `/start-here` rewritten as a real interactive protocol — runs interview, writes context files, runs heartbeat, confirms registry
- New core skill: `project-scan` — auto-populates `context/project.md` by reading manifests, entry points, key modules, infrastructure
- `mcp-agent.md` fully configured — real tool names for filesystem, github, brave-search, obsidian (mcpvault) with setup instructions
- New commands: `/plan`, `/tdd`, `/refactor`, `/commit`, `/scan` — every skill now has a slash command
- New Cowork variants: `git-commit.md`, `refactor.md`, `model-router.md` — Cowork layer now at 10 skills
- `skills/learned/example-jwt-validation/` — example learned skill demonstrating format and quality bar
- README updated with commands table and corrected Cowork count
- CLAUDE.md updated with project-scan in skill registry (100 lines)

### Phase 3 — Added
- `context/project.md` — project identity, stack, constraints, current state template
- `context/decisions.md` — running architectural decision log
- New workflow skills: `refactor` (coverage gate, behavior contract, one-change rule), `token-budget` (context window management, pre-compact capture protocol)
- New agent: `verifier` (acceptance criteria verification, read-only, no-write)
- New hooks: `preserve-on-compact.sh` (PreCompact), `session-start.sh` (InstructionsLoaded)
- `settings.global.json` — template for global `~/.claude/` deployment (correct `~/.claude/hooks/` paths)
- New Cowork variants: `code-review.md`, `debug-session.md`, `tdd.md`
- `.claude/skills/learned/` directory for learner skill output
- `.github/workflows/validate-hooks.yml` — shellcheck + settings.json script reference validation
- `validate.yml` updated: checks `level:` frontmatter, validates mandatory checklists in core/workflow skills
- `docs/design-decisions.md` updated with Phase 2+3 decisions (11-16)
- `README.md` rewritten with full skills/agents/hooks/context reference
- heartbeat skill updated to load `context/project.md` and `context/decisions.md`
- `CLAUDE.md` updated with verifier agent and full context file registry

### Phase 2 — Added
- `CLAUDE.md` rewritten as directive imperatives — per claude-skillz research
- All skills updated with `level:`, `pipeline:`, anti-patterns, mandatory checklists
- New core skills: `learner` (quality-gated capture), `remember` (in-session memory tagging)
- New workflow skills: `prd`, `code-review`, `debug-session`, `git-commit`, `model-router`
- New agents: `architect` (read-only, ADR), `code-reviewer` (isolated), `orchestrator` (agent teams)
- Hooks refactored from inline strings to shell scripts in `.claude/hooks/`
- Stop hook upgraded to auto-surface modified files
- `settings.json` enables agent teams experimental flag
- New commands: `prd`, `code-review`, `debug`, `security-gate`
- New Cowork variants: `prd.md`, `checkpoint.md`

### Phase 1 — Added
- Initial `.claude/` directory structure
- `CLAUDE.md` — master config
- `settings.json` — hooks configuration
- Core skills: `heartbeat`, `wrap-up`, `lesson-gen`, `security-gate`
- Workflow skills: `plan-first`, `tdd`, `checkpoint`
- Agents: `researcher`, `planner`, `security-reviewer`, `mcp-agent`
- Path-specific rules: `no-secrets`, `test-first`, `skill-format`
- Commands: `start-here`, `heartbeat`, `wrap-up`, `checkpoint`
- Cowork single-file variants: `heartbeat.md`, `wrap-up.md`
- Shared context files: `user.md`, `learnings.md`, `security-standards.md`
- `docs/design-decisions.md` — research-backed rationale

### Design Decisions
- Skills as knowledge layer only — no runtime execution in skills
- MCP tools isolated to `mcp-agent` — prevents 32K token overhead on main agent
- `security-reviewer` always spawned with `context: fork` — eliminates author-bias in review
- No install script — `.claude/` is the product, dropped at project root or `~/.claude/`
- Cowork variants are first-class, not degraded copies

---

## Failed Approaches Log

*Approaches tried and rejected — preserved to prevent reinventing the wheel.*

<!-- Format: [date] [approach] — [why rejected] -->
