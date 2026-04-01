---
name: design-token-guard
description: Enforce the token layer — find raw hex values and magic numbers in component files, replace with token references
---

Invoke the design-token-guard skill now. Locate the token definition file(s) first. Scan component files for raw hex values, arbitrary Tailwind color values, and raw font-size/spacing numbers. Classify each finding as TOKEN_VIOLATION (token exists, use it), TOKEN_GAP (token missing, create it), or TOKEN_CONFLICT (token exists but differs — escalate). Fix TOKEN_VIOLATIONs by replacing with existing token references. Fix TOKEN_GAPs by creating intent-named semantic tokens first, then updating components. Escalate TOKEN_CONFLICTs to the user. Re-scan after remediation to confirm zero raw values in component files.
