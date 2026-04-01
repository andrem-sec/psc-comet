---
name: verify
description: Unified verification sweep before commits and PRs
---

Invoke the verification protocol now.

## Invocation

```
/verify                # Quick mode (build + type check)
/verify quick          # Explicit quick mode
/verify full           # Full suite (build + types + lint + tests + coverage)
/verify pre-commit     # Full suite + git status check
/verify pre-pr         # Full suite + security scan (secrets + debug output)
```

## Protocol

1. Detect project language and tooling automatically
2. Run applicable checks based on mode
3. Report structured PASS/FAIL for each phase
4. Output final verdict: READY / NOT READY
5. If NOT READY, list blocking issues with file:line references

## Verification Report Format

```
VERIFICATION REPORT
Mode: [quick|full|pre-commit|pre-pr]
Timestamp: [ISO 8601]

Phase Results:
[ ] Build .................... PASS/FAIL
[ ] Type Check ............... PASS/FAIL
[ ] Lint ..................... PASS/FAIL (full+ only)
[ ] Test Suite ............... PASS/FAIL (full+ only)
[ ] Coverage (80% min) ....... PASS/FAIL (full+ only)
[ ] Security Scan ............ PASS/FAIL (pre-pr only)

Verdict: READY FOR PR / NOT READY

Blocking Issues:
[List if NOT READY]
```

## Language/Tool Detection

- **Python**: pytest, mypy, ruff/pylint, coverage.py
- **TypeScript/JavaScript**: tsc, eslint, jest/vitest, c8/nyc
- **Go**: go build, go vet, golangci-lint, go test -cover
- **C++**: cmake/make, clang-tidy, ctest/gtest
- **Bash**: shellcheck, bats

## Security Scan (pre-pr mode only)

Check for:
- Secrets in staged files (API keys, tokens, passwords)
- Debug output (console.log, print, fmt.Print)
- Credential files (.env, credentials.json, *.pem, *.key)

## Important

This is a read-only verification sweep. Do NOT fix issues. Only report them.

If mode is not specified, use **quick**.
