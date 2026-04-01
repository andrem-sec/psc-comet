# Architectural Decision Log

<!-- Updated by the architect agent and consensus-plan skill. -->
<!-- Format: ADR-N — title — date — status -->

---

## ADR-7: Rate Limit Storage — Redis vs In-Memory
Date: 2026-03-20
Status: ACCEPTED

### Context
Auth endpoints need rate limiting. Two viable options: Redis-backed (persistent across restarts, shared across instances) or in-memory (simpler, lost on restart).

### Decision
Redis-backed rate limiting using SET NX EX with per-endpoint keys.

### Rationale
The service runs as multiple instances behind a load balancer. In-memory rate limits are per-instance — an attacker hitting different instances could exceed the limit without triggering it. Redis-backed limits are shared. The service already has Redis as a dependency (token blacklist), so no new infrastructure is required.

### Consequences
- Positive: limits enforced across all instances consistently
- Negative: Redis becomes a dependency for auth availability (already the case)
- Neutral: adds ~1ms latency per auth request for the Redis call

---

## ADR-3: Session Storage — Database vs Redis
Date: 2026-02-10
Status: ACCEPTED

### Context
Sessions need to be stored somewhere. Options: PostgreSQL (existing), Redis (existing), or stateless JWT only.

### Decision
Stateless JWT (RS256) with Redis token blacklist for logout/revocation. No session table in PostgreSQL.

### Rationale
Stateless JWTs scale horizontally without shared session storage. The only stateful operation is revocation (logout, password reset, account lockout), which is handled by a Redis blacklist. PostgreSQL session tables add write load on every request; Redis lookups are sub-millisecond.

### Consequences
- Positive: horizontal scaling without sticky sessions
- Negative: tokens cannot be inspected server-side without a blacklist lookup
- Neutral: refresh token rotation still requires some statefulness (deferred — issue #47)

---

## ADR-1: TypeScript Strict Mode
Date: 2026-01-15
Status: ACCEPTED

### Context
Whether to enable TypeScript strict mode from project start or add it incrementally.

### Decision
Full strict mode from day one: `strict: true`, `noUncheckedIndexedAccess: true`, `exactOptionalPropertyTypes: true`.

### Rationale
Retrofitting strict mode onto an existing codebase is expensive. Starting strict forces explicit handling of undefined/null at boundaries, which catches authentication and authorization bugs early (unauthenticated user objects, missing claims, optional fields treated as present).

### Consequences
- Positive: entire class of auth bugs eliminated at compile time
- Negative: higher upfront cost; new contributors must understand strict mode
- Neutral: `noUncheckedIndexedAccess` requires array access to handle undefined explicitly
