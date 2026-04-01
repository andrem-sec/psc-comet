---
name: security-gate
description: Pre-deploy security assessment — validates against OWASP Top 10 and project standards
version: 0.2.0
level: 3
triggers:
  - "security check"
  - "security gate"
  - "pre-deploy review"
  - "before deploying"
  - "security audit"
context_files:
  - context/security-standards.md
steps:
  - name: Scope
    description: Identify files and modules in scope. List them explicitly.
  - name: Injection Scan
    description: Check all database queries, shell calls, template rendering for injection vectors
  - name: Secrets Scan
    description: Check for hardcoded credentials, tokens, keys, passwords in any literal form
  - name: Auth Check
    description: Verify authentication and authorization are enforced — not just at login
  - name: Input Validation
    description: Verify all external inputs are validated at system boundaries
  - name: Output Sanitization
    description: Verify error messages and logs do not leak sensitive data
  - name: Dependency Review
    description: Flag unpinned dependencies and known CVEs
  - name: Standards Comparison
    description: Compare findings against context/security-standards.md
  - name: Verdict
    description: PASS / CONDITIONAL PASS (with required fixes) / FAIL (blocking issues found)
---

# Security Gate Skill

Pre-deployment security assessment. Run before code reaches production or a shared environment.

## What Claude Gets Wrong Without This Skill

Without an explicit security gate, Claude applies security review inconsistently — thorough when it seems relevant, skipped when under pressure to finish. The most dangerous vulnerabilities are in code that looked safe at a glance.

## OWASP Top 10 Assessment

For each category, actively look for it — do not assume absence without checking:

**A01 — Broken Access Control**
- Can a user access resources they should not?
- Are authorization checks on every request, not just at login?
- Are direct object references validated against the current user's permissions?

**A02 — Cryptographic Failures**
- Is sensitive data transmitted without TLS?
- Are weak algorithms in use (MD5, SHA1 for passwords, ECB mode)?
- Are secrets stored in plaintext or reversibly encoded?

**A03 — Injection**
- Are any user inputs concatenated into SQL, shell commands, or LDAP queries?
- Are template engines used with user-controlled input without escaping?
- Are XML parsers configured to prevent XXE?

**A04 — Insecure Design**
- Are there rate limits on sensitive operations (login, password reset)?
- Is sensitive business logic enforced server-side only?

**A05 — Security Misconfiguration**
- Is debug mode enabled? Are stack traces exposed to users?
- Are default credentials in use?
- Are security headers missing (CSP, HSTS, X-Frame-Options)?

**A06 — Vulnerable Components**
- Are dependencies pinned?
- Are any direct dependencies flagged with known CVEs?

**A07 — Authentication Failures**
- Are passwords hashed with bcrypt, scrypt, or Argon2 (not MD5/SHA)?
- Are session tokens rotated after login and privilege changes?
- Is there brute-force protection on auth endpoints?

**A08 — Integrity Failures**
- Is user-supplied data deserialized without validation?
- Are CI/CD pipelines configured to prevent unauthorized modification?

**A09 — Logging Failures**
- Are authentication failures logged?
- Is sensitive data (passwords, tokens, PII) excluded from logs?
- Are log injection vectors sanitized?

**A10 — SSRF**
- Are any server-side HTTP requests made to user-supplied URLs?
- Are outbound requests restricted to an allowlist?

## Verdict Format

**PASS:** No issues found in scope. State scope explicitly.

**CONDITIONAL PASS:**
```
Issue: [description]
Location: [file:line]
Severity: LOW/MEDIUM
Fix: [specific remediation]
Blocking: No — fix before next release
```

**FAIL:**
```
Issue: [description]
Location: [file:line]
Category: [OWASP category]
Attack vector: [how it could be exploited]
Fix: [specific remediation]
Blocking: YES — do not deploy
```

## Anti-Patterns

Do not issue a PASS without checking every category. A fast PASS is a false PASS.

Do not scope-creep into architecture review. Report the finding and the fix category; do not redesign the system.

Do not combine security-gate with code-review. They are separate passes for a reason.

## Mandatory Checklist

1. Verify all 10 OWASP categories were actively checked (not assumed safe)
2. Verify scope was defined before the review (not inferred after)
3. Verify context/security-standards.md was read
4. Verify verdict is one of: PASS / CONDITIONAL PASS / FAIL
5. Verify every FAIL issue has a file:line location and specific fix
6. Verify the scope limitations are stated in the verdict
