# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | Yes       |

## Reporting a Vulnerability

If you discover a security vulnerability in Project Santa Clause, please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

### How to Report

Open a [GitHub Security Advisory](https://github.com/andrem-sec/psc-comet/security/advisories/new) on this repository. This creates a private disclosure thread visible only to maintainers.

Alternatively, email the maintainer directly via the contact on the GitHub profile.

### What to Include

- Description of the vulnerability and its potential impact
- Steps to reproduce (proof of concept if applicable)
- Affected version(s)
- Any suggested remediation

### Response Timeline

- **Acknowledgement:** within 48 hours
- **Initial assessment:** within 7 days
- **Fix or mitigation:** within 30 days for critical issues

### Scope

In scope:
- Hook scripts that could allow privilege escalation or command injection
- Memory scanning bypass in `pre-context-load.sh`
- Permission-mode enforcement bypass in `block-bypass-permissions.sh`
- Any pattern that allows secrets to be written to disk or transmitted

Out of scope:
- Claude Code itself (report to Anthropic)
- Issues requiring physical access to the machine
- Social engineering attacks

## Disclosure Policy

Once a fix is released, we will publish a security advisory with full details. We follow a 90-day coordinated disclosure timeline. Researchers who report valid vulnerabilities will be credited in the advisory unless they prefer to remain anonymous.
