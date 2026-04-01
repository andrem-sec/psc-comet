# Project Context

<!-- Auto-populated by /scan, maintained manually. Update after major changes. -->

## Identity

**Name:** auth-service
**Type:** REST API microservice
**Purpose:** Authentication and authorization for the platform — JWT issuance, session management, OAuth2 provider integration

## Stack

- **Runtime:** Node.js 22, TypeScript 5.4
- **Framework:** NestJS 10
- **Database:** PostgreSQL 16 (users, sessions) + Redis 7 (rate limits, token blacklist)
- **Auth:** JWT (RS256), Google OAuth2, TOTP (2FA)
- **Test:** Jest + Supertest for integration
- **CI:** GitHub Actions — lint → test → build → deploy (staging on PR merge, prod on tag)

## Architecture

```
src/
├── auth/           # Login, logout, token refresh, OAuth callback
├── users/          # User CRUD, profile
├── sessions/       # Session management, blacklist
├── rate-limit/     # Redis-backed rate limiting
└── common/         # Guards, interceptors, pipes, decorators
```

Entry point: `src/main.ts`. Config: `src/config/` (env-validated with Zod).

## Current State

Working:
- JWT login/logout with refresh tokens
- Google OAuth2 integration
- TOTP 2FA enrollment and verification
- Rate limiting on auth endpoints (Redis-backed, per-IP and per-user)

In progress:
- Passkey (WebAuthn) support — branch `feat/passkey`, blocked on spec clarification

Known issues:
- Token refresh does not rotate the refresh token (tracked in GitHub issue #47)
- TOTP recovery codes are single-use but not invalidated on password reset (security gap — issue #52)

## Constraints

- No synchronous crypto operations on the main event loop — use worker threads or async alternatives
- Auth service must not add runtime npm dependencies without architecture review
- All secrets via environment variables — no defaults in code
- Database migrations must be backward-compatible (zero-downtime deploys)

## Key Commands

```bash
npm run dev          # development server with hot reload
npm test             # Jest unit + integration tests
npm run test:e2e     # Supertest end-to-end
npm run build        # TypeScript compile
npm run migrate      # Run pending database migrations
```
