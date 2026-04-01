---
name: cso
description: Chief Security Officer mode — multi-phase security audit covering OWASP, STRIDE, secrets, CI/CD, and LLM attack surfaces
---

Invoke the CSO security audit protocol now.

## Flags

```
/cso                    # Full daily audit (confidence threshold: 8/10)
/cso --comprehensive    # Deep audit (confidence threshold: 2/10)
/cso --owasp            # OWASP Top 10 only
/cso --infra            # Infrastructure and CI/CD only
/cso --code             # Code security only
/cso --supply-chain     # Dependency vulnerabilities only
/cso --diff             # Changes on current branch only (combinable)
/cso --scope <domain>   # Focused audit on a specific domain
```

Scope flags are mutually exclusive. Error immediately if multiple incompatible flags are provided.

## Mental model first

Phase 0 is mandatory regardless of flags. Understand the application architecture — data flows, trust boundaries, component interactions — before scanning anything.

## Audit phases

**Phase 0** — Architecture detection and attack surface mapping

**Phase 1** — Entry point inventory (APIs, webhooks, CLI, file ingestion, env vars)

**Phase 2** — Secrets archaeology: scan git history for known prefixes (AKIA, sk-, ghp_, xoxb-, AIza). Check for tracked .env files. Flag CI configs with inline credentials.

**Phase 3** — Dependency vulnerabilities: check package manifests against known CVEs.

**Phase 4** — CI/CD security: unpinned third-party actions, dangerous `pull_request_target`, script injection via `${{ github.event.* }}`, missing CODEOWNERS.

**Phase 5** — Infrastructure configuration audit.

**Phase 6** — Webhook and integration verification.

**Phase 7** — LLM/AI-specific vulnerabilities: prompt injection vectors, unsanitized LLM output rendering, missing tool-call validation, exposed AI API keys, unbounded API call costs.

**Phase 8** — Supply chain: scan SKILL.md and agent definition files for exfiltration attempts, credential access, prompt injection.

**Phase 9** — OWASP Top 10: A01 broken access control, A02 cryptographic failures, A03 injection (SQL/command/template/LLM), A04-A10 per category.

**Phase 10** — STRIDE threat modeling.

**Phase 11** — Data classification: PII, credentials, keys in logs or storage.

**Phase 12** — False positive filtering. Every finding must have a concrete step-by-step exploit scenario. Theoretical risks without realistic attack paths are dropped.

**Phase 13** — Independent verification. Spawn the security-reviewer agent to verify findings before reporting. Do not report unverified findings as VERIFIED.

**Phase 14** — Report generation.

## Hard exclusions (do not report)

- Denial of service / resource exhaustion (except LLM cost amplification)
- Memory/CPU leaks in memory-safe languages
- Test-only code and fixtures
- Absence of hardening vs concrete flaws
- Security concerns in .md documentation files
- Logging non-PII data
- React/Angular rendering (XSS-safe by default)
- Environment variables as input (trusted boundary)

## Report format

For each finding:

```
Severity: CRITICAL | HIGH | MEDIUM
Confidence: [1-10]
Verified: YES | NO | TENTATIVE
Phase: [phase number]
Location: [file:line]
Exploit scenario: [step-by-step attack path — mandatory]
Remediation: [specific fix]
```

Final verdict: PASS | CONDITIONAL PASS | FAIL

Save report to `context/security-reports/[date]-cso.md`.

## Behavior rules

- Use Grep for all code searches. Do not pipe through Bash.
- When a vulnerability pattern is confirmed, search the entire codebase for identical weaknesses.
- Never report a finding without a realistic exploit path.
- If uncertain on a security-sensitive finding, spawn security-reviewer rather than guessing.
