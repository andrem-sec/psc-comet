# Session Learnings

<!-- Auto-updated by /wrap-up at session end. Most recent entries first. -->
<!-- Format: [category] description — session date -->

---

## 2026-03-20

[learning] Redis TTL behavior with SET NX EX differs between Redis 6 and 7 when the key already exists — in Redis 6, SET NX on an existing key does not update the TTL; in Redis 7 it does. Always test rate limit reset behavior against both versions.

[decision] Rate limit state keyed on `ip:${ip}:${endpoint}` not just `ip:${ip}` — more granular, allows different limits per endpoint without global counters.

[constraint] TOTP recovery codes must be invalidated on password reset — currently they are not (issue #52). Do not implement anything that assumes recovery codes are always valid post-password-change.

---

## 2026-03-15

[learning] JWT algorithm confusion: always verify the `alg` header matches the expected algorithm before validating. The `jsonwebtoken` library does this by default when you pass `algorithms: ['RS256']` — do not pass an array that includes 'none' or 'HS256'.

[learning] NestJS guards run before interceptors, but after middleware. If rate limiting must run before any business logic (including logging), it belongs in middleware, not a guard.

[decision] Refresh token rotation is deferred — issue #47. When implementing, use a rotation table approach (store issued refresh tokens, invalidate on use) rather than single-token rotation to prevent race conditions on concurrent requests.

---

## 2026-03-08

[preference] User prefers tests to live in the same directory as the source file (`auth.service.spec.ts` next to `auth.service.ts`), not in a separate `__tests__/` directory.

[learning] Google OAuth2 `id_token` expiry is 1 hour by default. Do not cache the token — verify on each use or extract the sub claim and cache that instead.

[constraint] Database migrations must not lock tables in production. Use `ADD COLUMN` with a default, then backfill, then add constraint — never `ADD COLUMN NOT NULL` without a default on a populated table.
