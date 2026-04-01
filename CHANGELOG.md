# Changelog

All notable changes are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

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
