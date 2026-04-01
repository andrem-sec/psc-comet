---
name: cso
description: Chief Security Officer mode — multi-phase security audit covering OWASP, STRIDE, secrets, CI/CD, and LLM attack surfaces
version: 0.1.0
level: 3
triggers:
  - "/cso"
  - "security audit"
  - "check for vulnerabilities"
  - "run a security review"
  - "full security scan"
context_files:
  - context/project.md
  - context/security-standards.md
steps:
  - name: Architecture Detection
    description: Phase 0 — map data flows, trust boundaries, and component interactions before scanning anything
  - name: Entry Point Inventory
    description: Phase 1 — enumerate APIs, webhooks, CLI, file ingestion, and env var exposure
  - name: Secrets Archaeology
    description: Phase 2 — scan git history for credential prefixes, tracked .env files, and inline CI credentials
  - name: Dependency Vulnerabilities
    description: Phase 3 — check manifests against known CVEs
  - name: CI/CD Security
    description: Phase 4 — unpinned actions, dangerous pull_request_target, script injection, missing CODEOWNERS
  - name: Infrastructure and Webhooks
    description: Phases 5 and 6 — configuration audit, webhook and integration verification
  - name: LLM Attack Surfaces
    description: Phase 7 — prompt injection, unsanitized output rendering, tool-call validation, AI API key exposure
  - name: Supply Chain
    description: Phase 8 — scan SKILL.md and agent files for exfiltration, credential access, prompt injection
  - name: OWASP Top 10
    description: Phase 9 — systematic coverage of A01 through A10
  - name: STRIDE Threat Model
    description: Phase 10 — Spoofing, Tampering, Repudiation, Information Disclosure, DoS (cost-only), Elevation of Privilege
  - name: Data Classification
    description: Phase 11 — PII, credentials, and keys in logs or storage
  - name: False Positive Filtering
    description: Phase 12 — every finding must have a concrete step-by-step exploit path; drop theoretical risks
  - name: Independent Verification
    description: Phase 13 — spawn security-reviewer agent to verify findings before reporting
  - name: Report Generation
    description: Phase 14 — structured findings with severity, confidence, and remediation; save to context/security-reports/
---

# CSO Skill

A Chief Security Officer-grade audit that covers every meaningful attack surface: OWASP Top 10, STRIDE threat modeling, secrets archaeology, CI/CD pipeline security, LLM-specific vulnerabilities, and supply chain risks. The output is a verified, actionable report, not a theoretical checklist.

## What Claude Gets Wrong Without This Skill

Without a structured audit protocol, security reviews drift toward the obvious. SQL injection gets flagged; prompt injection in an AI pipeline does not. Hardcoded credentials in source are caught; credentials baked into git history are missed. CI/CD pipeline injection via untrusted event data goes unexamined entirely.

The other failure mode is noise: theoretical findings with no realistic exploit path, flagging the absence of hardening rather than the presence of a flaw. Both failures waste time and erode trust in the audit.

This skill enforces a systematic 15-phase protocol that starts with architecture understanding, ends with independent verification, and drops findings that cannot survive the exploit-path test.

## Flags

```
/cso                    # Full audit (confidence threshold: 8/10)
/cso --comprehensive    # Deep audit (confidence threshold: 2/10)
/cso --owasp            # OWASP Top 10 only
/cso --infra            # Infrastructure and CI/CD only
/cso --code             # Code security only
/cso --supply-chain     # Dependency and third-party skills only
/cso --diff             # Current branch changes only (combinable)
/cso --scope <domain>   # Focused on a specific domain
```

Scope flags are mutually exclusive. Error immediately on incompatible combinations.

## Phase 0 Is Mandatory

Regardless of flags, Phase 0 always runs first. You cannot audit what you do not understand. Map the application architecture: data flows, trust boundaries, authentication and authorization design, external integrations, and the components that process untrusted input. This is the mental model everything else depends on.

A rushed Phase 0 produces a rushed audit.

## The 15-Phase Protocol

| Phase | Name | What It Examines |
|-------|------|-----------------|
| 0 | Architecture detection | Data flows, trust boundaries, component interactions |
| 1 | Entry point inventory | APIs, webhooks, CLI, file ingestion, env vars |
| 2 | Secrets archaeology | Git history credential prefixes (AKIA, sk-, ghp_, xoxb-, AIza), tracked .env files, inline CI credentials |
| 3 | Dependency vulnerabilities | Package manifests against known CVEs |
| 4 | CI/CD security | Unpinned third-party actions, dangerous pull_request_target, script injection via ${{ github.event.* }}, missing CODEOWNERS |
| 5 | Infrastructure | Configuration audit |
| 6 | Webhooks and integrations | Verification and validation |
| 7 | LLM attack surfaces | Prompt injection vectors, unsanitized LLM output rendering, missing tool-call validation, exposed AI API keys, unbounded API cost amplification |
| 8 | Supply chain | SKILL.md and agent definition files scanned for exfiltration attempts, credential access, prompt injection |
| 9 | OWASP Top 10 | A01 broken access control through A10 per category |
| 10 | STRIDE threat model | All six threat categories (DoS included only for LLM cost amplification) |
| 11 | Data classification | PII, credentials, keys in logs or persistent storage |
| 12 | False positive filtering | Exploit path required; drop theoretical risks |
| 13 | Independent verification | security-reviewer agent verifies findings |
| 14 | Report generation | Structured findings, final verdict, saved to context/security-reports/ |

## The Exploit Path Rule

Every finding must include a concrete, step-by-step attack scenario. If you cannot write the steps an attacker would take to exploit it, it is not a verified finding. File it as LOW/tentative or drop it.

Example of an exploit path that passes:
```
1. Attacker submits user-controlled input containing: '; DROP TABLE users; --
2. Input flows to query builder at db/users.py:47 without parameterization
3. Query executes with database user privileges
4. Table is dropped or data is exfiltrated
```

"This could theoretically allow injection" does not pass.

## Hard Exclusions

Do not report:
- Denial of service or resource exhaustion (except LLM cost amplification)
- Memory or CPU leaks in memory-safe languages
- Test-only code and fixtures
- Absence of hardening versus concrete exploitable flaws
- Security concerns in .md documentation files
- Logging non-PII data
- React/Angular rendering (XSS-safe by default)
- Environment variables as input (trusted boundary)

## Report Format

For each finding:

```
Severity: CRITICAL | HIGH | MEDIUM
Confidence: [1-10]
Verified: YES | NO | TENTATIVE
Phase: [phase number]
Location: [file:line]
Exploit scenario: [step-by-step attack path]
Remediation: [specific fix, not a category]
```

Final verdict: PASS | CONDITIONAL PASS | FAIL

Save report to `context/security-reports/[YYYY-MM-DD]-cso.md`.

## Independent Verification (Phase 13)

Spawn the `security-reviewer` agent with the list of candidate findings. The agent reviews each independently and returns a verdict per finding: VERIFIED, UNVERIFIED, or FALSE_POSITIVE. Do not report unverified findings as VERIFIED. Unverified findings may still appear as TENTATIVE if there is reasonable concern.

This is not optional for CRITICAL or HIGH findings.

## Behavior Rules

- Use Grep for all code searches. Do not pipe through Bash.
- When a vulnerability pattern is confirmed, search the entire codebase for the same pattern.
- Never report a finding without a realistic exploit path.
- If uncertain on a security-sensitive finding, spawn security-reviewer rather than guessing.
- Phase 0 runs regardless of scope flags.

## Anti-Patterns

Do not start scanning before completing Phase 0. An audit without architectural understanding produces findings without context and misses entire attack surfaces.

Do not report findings in bulk without exploit paths. One verified finding with a clear exploit path is worth more than ten theoretical flags.

Do not skip Phase 13. The author of the scan has bias toward confirming hypotheses. The independent reviewer does not.

Do not flag hardening gaps as vulnerabilities. Hardening is good practice; its absence is not a flaw unless it creates a concrete attack path.

## Mandatory Checklist

1. Verify Phase 0 (architecture mapping) completed before any scan phase ran
2. Verify all applicable phases ran or were explicitly skipped due to scope flags
3. Verify every finding has a step-by-step exploit path
4. Verify all items on the hard exclusion list were filtered out
5. Verify the security-reviewer agent was invoked for CRITICAL and HIGH findings
6. Verify no unverified finding is labeled VERIFIED in the report
7. Verify the report was saved to context/security-reports/[date]-cso.md
