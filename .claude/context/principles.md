---
loaded-by:
  - reasoning-gates
  - plan-first
---

# Principles

Active operational principles derived from PSC decisions and session experience.
Claude checks these during entropy scans and plan scoping, surfacing any that apply.

## Override Protocol

Say "override P-XX" or "I know, proceed" to bypass a principle for the current task.
Claude will acknowledge, proceed, then ask:

```
P-XX bypassed. Log as one-time exception or update the principle?
  1. One-time exception (add a note to the principle entry)
  2. Update the principle (Claude edits it in-place)
  3. Archive it (Claude moves it to Archived section)
```

If the principle is updated or archived, apply the same change to psc_comet.

## Format

```
## P-XX: [Title]
Status: ACTIVE | SUSPENDED | ARCHIVED
Rule: [What Claude should do or avoid]
Caused-by: [ADR ID, session date, or learning that established this]
Exceptions: [logged one-time overrides with date and reason]
```

## Active Principles

## P-01: Security-sensitive changes require an isolated reviewer
Status: ACTIVE
Rule: Any change touching auth, secrets, permissions, or external-boundary validation must be reviewed by the security-reviewer agent in a fresh context before being committed. Do not review in the session that wrote the code.
Caused-by: CLAUDE.md Security Rules; ADR-005 (Config Protection Hook)
Exceptions:

## P-02: Fix code to meet standards -- do not lower standards to accept code
Status: ACTIVE
Rule: When a linter, formatter, or CI check fails, fix the underlying code. Do not weaken or comment out the config rule to make the failure disappear.
Caused-by: ADR-005 (Config Protection Hook -- exit 2 blocks writes to 43 linter config patterns)
Exceptions:

## P-03: Public repo requires sanitization check before any push
Status: ACTIVE
Rule: Before pushing changes to the public repo or opening a PR, verify that no personal data, private paths, client names, or credentials are present. Private repo context does not transfer automatically to public.
Caused-by: Public/private environment separation rule; past sanitization cross-contamination incident (meta-learnings.md)
Exceptions:

## Archived Principles

<!-- Principles that no longer apply. Retained for context. -->
