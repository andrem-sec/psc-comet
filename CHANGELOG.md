# Changelog

All notable changes are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

---

## [1.2.0] — 2026-04-16

### Added
- `reasoning-gates` skill — human-confirmed reasoning gates at high-reversal-cost decision points. Entropy scan produces 2–3 candidates with decision / why / options; user confirms which gates to set; execution pauses at confirmed gates for explicit rationale before continuing.
- `code-review --adversarial` mode — argues against the implementation rather than inspecting it. Five challenge questions (abstraction level, test coverage, over-engineering, hidden assumptions, rewrite triggers). Default `/code-review` behavior unchanged.
- `stop-wrap-guard` hook — opt-in Stop hook that blocks session end if uncommitted changes exist and `/wrap-up` has not run. Enable via `.claude/context/.wrap-guard` flag file.
- `stop-review-gate` hook — opt-in Stop hook that blocks session end if source files were modified and `/code-review` has not run. Enable via `.claude/context/.review-gate` flag file.
- `.gitignore` entries for opt-in flag files (`.wrap-guard`, `.review-gate`) and session markers (`.wrapup-done`, `.review-done`)

### Changed
- `telemetry-log.sh`, `stop-cost-tracker.sh` — emit `{"suppressOutput":true}` on stdout; these hooks write to JSONL files only and have no user-facing output
- `ember-gate.sh` — conditional suppressOutput: suppressed when idle, not suppressed when writing the ember-due trigger flag
- `agentic-engineering` skill — added failure cascading (blocked tasks wait on dependency resolution), auto-unblock on resolution, zombie prevention (permanently-failed dependency surfaces explicitly for human cancellation). Added per-role model assignment table: Opus for Architect/Planner, Sonnet for Implementer/Reviewer, Haiku for Classifier/Fetcher.
- `model-router` skill — added orchestrator-level routing note: assign models at the role level in agent spawn prompts, not at session level
- `code-review` skill — added marker-write step to Verdict phase (writes `.wrapup-done` for review gate integration)
- CLAUDE.md Agent Registry — standardized constraint notation: `readonly`, `readonly+isolated`, `no-impl`, `MCP-only`, `worktree-isolated`
- CLAUDE.md Skill Registry — added `reasoning-gates` row

---

## [1.1.0] — 2026-04-15

### Added
- `/reflect` skill — instinct extraction extracted from `/wrap-up` into a dedicated skill with trigger / action / domain quality gate and instinct-cli.py integration. Graceful degradation when Python CLI unavailable.
- Tag-based learnings MOC — `context/learnings-index.md` index with per-tag files (`context/learnings/[tag].md`). Replaces monolithic `learnings.md` load on every heartbeat. Tags: workflow, hook, bug, decision, security, tool, meta, platform.
- `context/handoff-template.md` — structured Part 1 (completed work) / Part 2 (open risks + next steps) handoff format.
- `/distill` command — 3-part process: compress learnings (merge near-duplicates, archive superseded entries), review instinct clusters (propose merges, not deletions), reset ember gate.
- `tests/test-learnings-structure.sh` — 35-assertion gate test covering handoff template, learnings MOC, reflect SKILL.md frontmatter, and command structure.
- `/start-here` command — onboarding tour for new users.
- Vault governance phase to `/obsidian-setup`.

### Changed
- `wrap-up` — routes learnings to tagged files via index; Step 5 is now an inline `/reflect` check.
- `heartbeat` — loads `learnings-index.md` MOC on every session; surfaces ember-due flag when present.
- `observe-instruct.sh` — retired. Stop hooks receive no conversation content; instinct extraction moved to `/wrap-up` and `/reflect`.
- CLAUDE.md — skill registry updated (`learner` replaced by `reflect`); context files section updated to document learnings-index.md and `learnings/` directory.
- eval-harness SKILL.md — cross-platform fixes.
- Hook scripts — executable bits set; shellcheck warnings resolved.

---

## [1.0.0] — 2026-03-31

Initial public release of the Comet branch.

### Skills (68)

**Core:** `heartbeat`, `wrap-up`, `lesson-gen`, `learner`, `remember`, `security-gate`, `project-scan`, `roe`

**Planning & implementation:** `prd`, `plan-first`, `tdd`, `deep-interview`, `consensus-plan`, `feature-pipeline`, `fix-pipeline`

**Review & quality:** `code-review`, `simplify`, `refactor`, `verification-loop`, `eval-harness`, `ai-regression-testing`, `skill-comply`

**Debugging & investigation:** `debug-session`, `investigate`, `checkpoint`, `intent-router`

**DevOps & deployment:** `security-gate`, `roe`, `canary`, `benchmark`, `retro`

**Memory & session management:** `distill`, `resume`, `token-budget`, `strategic-compact`, `context-budget`, `continuous-learning-v2`, `loop-operator`

**Multi-agent workflows:** `agentic-engineering`, `batch`, `deep-research`, `agent-harness-construction`

**Workflow utilities:** `git-commit`, `model-router`, `github-issue`, `github-pr`, `office-hours`, `safety-guard`, `codebase-onboarding`, `skill-stocktake`, `loop`, `public-mode`

**UI/Design:** `brand-context`, `inspiration-brief`, `site-teardown`, `screenshot-loop`, `component-spec`, `ui-slop-guard`, `design-token-guard`, `animation-safe`, `responsive-design`

### Agents (13)

`researcher`, `planner`, `architect`, `security-reviewer`, `code-reviewer`, `verifier`, `mcp-agent`, `orchestrator`, `docker-sandbox`, `harness-optimizer`, `ui-critic`, `a11y-reviewer`, `design-researcher`

### Hooks (25)

**PreToolUse:** `block-destructive`, `block-secrets-write`, `block-bypass-permissions`, `pre-config-protection`, `pre-edit-baseline`

**PostToolUse:** `warn-debug-output`, `warn-ai-slop`, `warn-token-violation`, `warn-missing-alt`, `warn-transition-all`, `warn-missing-reduced-motion`, `warn-outline-none`, `attribution-snapshot`, `post-edit-check`

**PreCompact:** `preserve-on-compact`, `session-memory-precompact`

**InstructionsLoaded:** `session-start`, `pre-context-load`

**Stop:** `auto-review-on-stop`, `telemetry-log`, `stop-cost-tracker`, `stop-check-console-log`, `observe-instinct`, `ember-gate`

### Commands (46)

Full slash command coverage for all core skills and workflows.

### Infrastructure

- CI: `validate.yml`, `validate-hooks.yml`, `release.yml`
- Scripts: `detect-platform.sh`, `validate-id.sh`, `safe-log.sh`, `bootstrap-phase8.sh`
- Cross-platform: Windows (Git Bash, MSYS2, Cygwin), Linux, macOS
- Python CLI for continuous learning system (optional, graceful degradation without it)

---

## Failed Approaches

*Approaches tried and rejected — preserved to prevent reinvention.*

- **Cost tracking via Stop hook** — Stop hooks receive only `{session_id, stop_reason, os, arch}`. Token counts and model name are not available. Stub implemented; requires upstream Claude Code enhancement to expose usage data in hook input.
- **PCRE patterns in injection scanner** — `grep -P` not available on macOS BSD grep. Migrated to ERE (`grep -E`). All injection patterns are ERE-compatible.
