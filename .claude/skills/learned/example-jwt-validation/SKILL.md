---
name: jwt-algorithm-confusion-prevention
description: Prevent algorithm confusion attacks when validating JWTs — RS256 tokens accepted as HS256
version: 0.1.0
level: 2
triggers:
  - "jwt validation"
  - "token verification"
  - "verify jwt"
context_files: []
steps:
  - name: Check Algorithm Enforcement
    description: Verify the JWT library is configured to accept only the expected algorithm explicitly
  - name: Check Key Type Match
    description: Confirm the key type matches the declared algorithm — RSA key for RS256, secret for HS256
  - name: Check None Algorithm Rejection
    description: Verify the library rejects the "none" algorithm
---

# JWT Algorithm Confusion Prevention

**Note:** This is an example learned skill showing the format. Replace it with skills captured from your actual codebase using the `learner` skill.

## The Insight

JWT libraries that accept any algorithm will validate an RS256-signed token as HS256 if you use the public RSA key as the HMAC secret. The attacker signs a token with the public key using HS256 — the library accepts it because the signature is valid under HS256 with that key. This is not a theoretical attack.

## Why This Matters

The symptom that brings you here: authentication bypass with valid-looking tokens. No error in logs. The token passes signature verification. The bug is invisible unless you know to look for it.

## Recognition Pattern

This skill applies when:
- Using a JWT library that does not enforce algorithm on verify
- The verification function accepts an algorithm parameter at call time rather than configuration time
- RS256 (asymmetric) tokens are in use and the public key is accessible

## The Approach

**Explicit algorithm allowlist at configuration time, not call time.**

Wrong — algorithm from token header trusted:
```python
jwt.decode(token, key)  # uses alg from token header
```

Right — algorithm enforced by verifier:
```python
jwt.decode(token, key, algorithms=["RS256"])  # rejects anything else
```

Also verify:
1. `"none"` algorithm is explicitly rejected (not just "not in the list" — some libraries require explicit rejection)
2. The key type matches the algorithm — if RS256, the key must be an RSA public key object, not a string

## Mandatory Checklist

1. Verify the algorithm is specified at the call site or configuration, not inferred from the token header
2. Verify `"none"` algorithm is explicitly rejected
3. Verify the key type is validated to match the expected algorithm
4. Verify this check exists on every code path that processes JWTs, not just the main one
