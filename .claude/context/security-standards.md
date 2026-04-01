# Security Standards

Standards enforced by the `security-gate` skill and `security-reviewer` agent.

## Baseline Requirements (All Projects)

### Secrets
- No hardcoded credentials, API keys, tokens, or passwords anywhere in the codebase
- All secrets via environment variables or a secrets manager
- `.env` files excluded from version control via `.gitignore`
- Secret scanning enabled in CI

### Input Validation
- All external inputs validated at system boundaries (user input, API responses, file reads)
- No trust of internal data that passed through an external boundary without re-validation
- Parameterized queries for all database interactions — no string concatenation in SQL

### Authentication & Authorization
- Authentication required before any sensitive operation
- Authorization checked on every request, not just at login
- Session tokens rotated on privilege escalation

### Dependencies
- No dependencies with known critical CVEs
- Dependency pinning with lockfiles committed to version control
- Regular dependency audit cadence

### Output
- No sensitive data in logs
- Error messages sanitized before returning to clients
- No stack traces exposed to end users

## Project-Specific Standards

<!-- Add project-specific requirements here -->

---
*Update this file when project security requirements are established.*
