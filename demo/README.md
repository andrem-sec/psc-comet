# Demo — Santa Claus in Action

This directory shows what Santa Claus produces after a real session. The files here are filled examples of the five context files and a sample session walkthrough.

Use these as references when filling in your own context files with `/start-here` or `/scan`.

---

## Sample Session Walkthrough

This is what a typical session looks like from start to finish.

### 1. Session Start — `/heartbeat`

Claude loads all five context files and surfaces relevant learnings:

```
Session start — 2026-03-25

Goal: Add rate limiting to the auth endpoints
Relevant context:
  - [decision] We use Redis for session storage (context/decisions.md ADR-3)
  - [constraint] Auth service must not add runtime dependencies without architecture review
  - [learning] JWT validation edge case: algorithm confusion attack — always verify alg header
Plan: Use the feature-pipeline — deep-interview first to clarify scope, then prd, then tdd
```

### 2. Classify the Request — `intent-router`

```
Intent: new feature
Reason: "add rate limiting" is a net-new capability, not a fix or refactor
First step: deep-interview — clarify scope (which endpoints, what limits, Redis or in-memory)
```

### 3. Explore Before Speccing — `/deep-interview`

Claude asks focused questions to surface critical unknowns before writing any spec:

- Which endpoints need rate limiting? (login only, or all auth endpoints?)
- What are the limits? (per IP, per user, or both?)
- What happens when a limit is hit? (429, lockout, CAPTCHA?)
- Does this need to survive service restarts? (Redis persistence or in-memory only?)

Ambiguity gate: once unknowns are below 20%, the interview closes and spec begins.

### 4. Spec — `/prd`

```
Feature: Auth Rate Limiting
Acceptance Criteria:
1. POST /auth/login returns 429 after 5 failed attempts within 60 seconds per IP
2. POST /auth/login returns 429 after 10 attempts (any result) within 60 seconds per user
3. 429 response includes Retry-After header
4. Limits reset after the window expires (not on success)
5. Rate limit state persists across service restarts (Redis-backed)
6. Test: verify limit triggers on attempt 6, not attempt 5
```

### 5. Plan — `/plan`

```
Plan: Auth Rate Limiting
Files affected: 4 — auth.service.ts, auth.controller.ts, redis.service.ts, auth.spec.ts
Risk: MEDIUM (auth path — requires security review after implementation)

Step 1: Write failing tests for rate limit behavior (auth.spec.ts)
Step 2: Implement RateLimitService using Redis — src/rate-limit/rate-limit.service.ts
Step 3: Inject into AuthService, check before processing login
Step 4: Add Retry-After header to 429 responses in AuthController
  Checkpoint: run test suite — all rate limit tests should pass
Step 5: Spawn security-reviewer on the auth path
```

### 6. TDD — `/tdd`

Red → Green → Refactor. Tests written first, implementation only after tests fail for the right reason.

### 7. Security Review — automatic via `feature-pipeline`

The feature pipeline spawns `security-reviewer` in an isolated context after implementation. It cannot see the session that wrote the code — eliminates author-bias.

### 8. Session End — `/wrap-up`

```
Session end — 2026-03-25

Completed: Auth rate limiting — all 6 acceptance criteria verified
Learnings logged:
  - Redis TTL behavior with NX flag differs between Redis 6 and 7 — always test both
  - Rate limiting on user ID requires extracting ID before auth check (not after)

context/learnings.md updated. context/decisions.md updated (ADR-7: rate limit strategy).
Commit written with decision trailers.
```

---

## Context Files

The `context/` directory contains filled examples showing what these files look like after a real project session. Read them to understand the format before filling in your own.

- `context/user.md` — profile example
- `context/project.md` — project state example
- `context/learnings.md` — accumulated learnings after multiple sessions
- `context/decisions.md` — ADR log with three example decisions
