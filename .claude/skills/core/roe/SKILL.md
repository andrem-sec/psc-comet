---
name: roe
description: Rules of Engagement authorization gate — required before any security operation, autonomous scanning, or action with real-world effects outside the local codebase
version: 0.1.0
level: 3
triggers:
  - "before scanning"
  - "security operation"
  - "roe"
  - "rules of engagement"
  - "am I authorized"
  - "check authorization"
  - "before running docker-sandbox"
  - "penetration test"
  - "autonomous operation"
context_files:
  - context/security-standards.md
steps:
  - name: Authorization
    description: Confirm who authorized this operation — get a reference. Ticket number, written approval, contract clause, or explicit in-session user statement. "I think it's okay" is not authorization.
  - name: Scope
    description: Define what is explicitly in scope — list systems, IP ranges, domains, repositories, or services by name. Vague scope ("everything") is not acceptable.
  - name: Exclusions
    description: Define what is explicitly out of scope — production systems, third-party services, systems owned by others, anything with a blast radius beyond this engagement.
  - name: Time Window
    description: Confirm when this is authorized — start time, end time, or "this session only." Operations outside the window require re-authorization.
  - name: Escalation Contact
    description: Name who to contact if something unexpected happens — unintended impact, discovered live breach, access beyond scope, system degradation.
  - name: Verdict
    description: PROCEED if all five are answered. HOLD if any are missing — state exactly what is needed before proceeding.
---

# Rules of Engagement Skill

Authorization gate. Run before any security operation, autonomous scanning, or action that touches systems outside the current local codebase.

## What Claude Gets Wrong Without This Skill

Without an ROE gate, Claude executes security operations on the assumption that authorization exists. This assumption is wrong often enough to matter. Scanning systems you are not authorized to test is illegal in most jurisdictions regardless of intent. The ROE gate makes authorization explicit before execution begins — not implied, not assumed.

## When ROE Is Required

| Operation | ROE Required |
|-----------|-------------|
| Network scanning (nmap, masscan) | Yes |
| Web application scanning (nikto, nuclei, gobuster) | Yes |
| Vulnerability scanning | Yes |
| Credential testing | Yes |
| Fuzzing external endpoints | Yes |
| docker-sandbox autonomous execution | Yes |
| Reviewing local code for vulnerabilities | No — use security-gate |
| Running tests against localhost | No |
| Reading files in the current project | No |

## ROE Document Format

When ROE is confirmed, produce this document and present it to the user before proceeding:

```
## Rules of Engagement

Date: [date]
Operation: [what will be performed]

### Authorization
Reference: [ticket / approval / explicit user statement]
Authorized by: [who]

### Scope (In)
[List of systems, domains, IPs, repositories — specific, not vague]

### Scope (Out)
[Explicit exclusions]

### Time Window
Start: [time or "session start"]
End: [time or "session end"]

### Escalation Contact
[Name / channel — who to notify if something unexpected occurs]

### Verdict: PROCEED
```

## HOLD Format

```
## ROE: HOLD

Missing before proceeding:
- [ ] [what is needed]
- [ ] [what is needed]

Do not begin the operation until these are provided.
```

## Anti-Patterns

Do not accept vague authorization. "My manager said it's fine" without a ticket or written record is not authorization.

Do not skip ROE because the operation "seems small." Scope creep starts with small operations.

Do not proceed if scope is undefined. An undefined scope is an unlimited scope.

Do not re-use an ROE from a previous session without re-confirming it still applies.

## Mandatory Checklist

1. Verify all five elements were answered — authorization, scope in, scope out, time window, escalation contact
2. Verify scope is specific — named systems, not "everything relevant"
3. Verify exclusions are stated — even if the answer is "none explicitly excluded"
4. Verify the ROE document was produced and presented before any execution began
5. Verify verdict is PROCEED or HOLD — not a conditional that assumes missing information will be fine
6. Verify HOLD lists exactly what is needed to unblock
