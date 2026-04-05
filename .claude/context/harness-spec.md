# PSC Harness Specification

Version 1.0. Last updated: 2026-04-04.

---

## What PSC Is

A portable configuration layer that runs on top of Claude Code.
A standardized session protocol that makes Claude behavior consistent across machines, sessions, and users.
A security-first harness -- permission invariants, isolated reviewers, ROE requirements.
A self-improving system -- instincts, memory, continuous learning.
A workflow enabler for DevSecOps practices.

## What PSC Is Not

- A replacement for Claude Code -- it extends it, never replaces it
- A model provider -- it does not change which LLM runs underneath
- An AI framework or agent runtime -- it is static configuration files and skills
- A security tool itself -- it enforces security practices, it is not a scanner or analyzer
- Production enterprise software with uptime SLAs -- it is a community configuration suite

## Core Invariants

These must always be true regardless of any other change:

- bypassPermissions is never enabled under any circumstance
- Security-sensitive changes are always reviewed in an isolated context
- No unreviewed code reaches remote
- Session state is always captured and transferable

## Target Users

1. Individual security/software professional wanting consistent Claude behavior across machines
2. Team lead or DevOps engineer deploying a standard Claude workflow for an engineering team

---

## Quality Gate

### Components

1. `harness-spec.md` (this file) -- SLA-grade definition for contributors and team deployers
2. `scripts/psc-health-check.sh` -- binary floor checks, exits 0/1
   - CLAUDE.md exists and is under 200 lines
   - All agents in registry have corresponding files
   - All skills in registry have corresponding directories
   - All hooks in settings.json exist on disk
   - settings.json is valid JSON
   - No registered component missing required frontmatter
3. `.github/workflows/psc-health.yml` -- runs health check on every PR, blocks merge on failure
4. `CONTRIBUTING.md` -- PR criteria, references spec and health check
5. `scripts/scoring/psc-score.sh` -- deployer-configured scoring runner (framework only, no hardcoded metrics)
6. `scripts/scoring/rubric-template.yaml` -- deployer fills in their own metrics before scoring activates

**Design constraints on scoring:**
- PSC ships the infrastructure, deployer configures the metrics
- Reward hacking risk documented explicitly -- developer must acknowledge before enabling
- Hard floors are binary gates, not weighted dimensions
- A failing hard floor scores 0 regardless of other dimensions
- Human review remains the final gate
- Behavioral regressions (not caught by floor checks) are the deployer's call

**What is deliberately excluded:**
- Hardcoded metrics
- Machine vs machine adversarial verification as sole gate
- Fully autonomous hill-climbing without human review gate
