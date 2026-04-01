---
name: verification-loop
description: 6-phase pre-PR verification sweep with structured PASS/FAIL reporting
version: 1.0.0
level: 2
triggers:
  - "/verify"
  - "verify before commit"
  - "pre-commit check"
  - "ready for PR"
context_files:
  - context/project.md
steps:
  - name: Language Detection
    description: Auto-detect project language and available tooling
  - name: Build Phase
    description: Run build and capture errors
  - name: Type Check Phase
    description: Run type checker (if applicable)
  - name: Lint Phase
    description: Run linter (full mode only)
  - name: Test Suite Phase
    description: Run tests with coverage (full mode only)
  - name: Security Scan Phase
    description: Scan for secrets and debug output (pre-pr mode only)
  - name: Generate Report
    description: Output structured VERIFICATION REPORT with final verdict
---

# Verification Loop Skill

Comprehensive pre-commit and pre-PR verification. Runs the quality checks humans forget.

## What Claude Gets Wrong Without This Skill

Without structured verification, Claude either:
1. Skips checks entirely and creates broken PRs
2. Runs checks ad-hoc without recording results
3. Stops at the first failure instead of collecting all issues
4. Doesn't provide a clear READY/NOT READY verdict

The verification loop ensures every check runs, every failure is recorded, and the final state is unambiguous.

## Verification Modes

**quick** (default): Build + type check only. Fast feedback for iterative development.

**full**: Build + types + lint + tests + coverage (80% minimum). Standard pre-commit sweep.

**pre-commit**: Full suite + git status verification (no uncommitted changes in critical paths).

**pre-pr**: Full suite + security scan (secrets, debug output, credential files). Release gate.

## The 6 Phases

### Phase 1: Language Detection

Auto-detect from project files:
- **Python**: pytest, mypy, ruff/pylint, coverage.py
- **TypeScript/JavaScript**: tsc, eslint, jest/vitest, c8/nyc
- **Go**: go build, go vet, golangci-lint, go test -cover
- **C++**: cmake/make, clang-tidy, ctest/gtest
- **Bash**: shellcheck, bats

If multiple languages present, run checks for all detected languages.

### Phase 2: Build

Run the build command appropriate to the detected language:
- Python: Import all modules to verify syntax
- TypeScript/JavaScript: `tsc --noEmit` or build script
- Go: `go build ./...`
- C++: `cmake --build` or `make`
- Bash: `bash -n` on all .sh files

Capture all errors. Do not stop at first failure.

### Phase 3: Type Check

Language-specific type checking:
- Python: `mypy` with strict mode
- TypeScript: `tsc --noEmit`
- Go: Type checking included in build
- C++: Compile-time type checking included in build

Record all type errors with file:line references.

### Phase 4: Lint (full+ modes only)

Run linter and capture warnings/errors:
- Python: `ruff check` or `pylint`
- TypeScript/JavaScript: `eslint`
- Go: `golangci-lint run`
- C++: `clang-tidy`
- Bash: `shellcheck`

Treat errors as blocking. Warnings are informational only.

### Phase 5: Test Suite (full+ modes only)

Run test suite with coverage:
- Python: `pytest --cov --cov-report=term`
- TypeScript/JavaScript: `jest --coverage` or `vitest --coverage`
- Go: `go test -cover ./...`
- C++: `ctest` or run test binaries

Coverage threshold: 80% minimum for PASS verdict.

If tests exist but coverage is below threshold: FAIL with specific gap report.

If no tests exist: WARN but do not fail (legacy code exception).

### Phase 6: Security Scan (pre-pr mode only)

Three scans:

**Secrets scan**: Grep staged files for:
- API keys (pattern: `api[_-]?key\s*[=:]\s*['\"][a-zA-Z0-9_-]{10,}`)
- Passwords (pattern: `password\s*[=:]\s*['\"][^'\"]{4,}`)
- Tokens (pattern: `token\s*[=:]\s*['\"][a-zA-Z0-9_-]{20,}`)

**Debug output scan**: Grep source files for:
- `console.log` (JavaScript/TypeScript)
- `print(` or `pprint(` (Python)
- `fmt.Print` (Go)
- `std::cout` (C++)

**Credential files**: Check for staged:
- `.env`, `.env.local`, `.env.production`
- `credentials.json`, `secrets.json`
- `*.pem`, `*.key`, `id_rsa`, `id_ed25519`

## Verification Report Format

```
VERIFICATION REPORT
Mode: [quick|full|pre-commit|pre-pr]
Timestamp: [ISO 8601]
Language(s): [detected languages]

Phase Results:
[✓] Build .................... PASS
[✓] Type Check ............... PASS
[✓] Lint ..................... PASS (full+ only)
[✗] Test Suite ............... FAIL: 3 tests failing
[✓] Coverage (80% min) ....... PASS: 87%
[✓] Security Scan ............ PASS (pre-pr only)

Verdict: NOT READY

Blocking Issues:
1. test_auth.py::test_login_flow - AssertionError at line 45
2. test_auth.py::test_logout - KeyError: 'session_id'
3. test_api.py::test_rate_limit - Timeout after 5s
```

## When to Use Each Mode

**quick**: After each significant edit, before committing. Fast iteration.

**full**: Before `git commit`. Ensures local quality bar.

**pre-commit**: In pre-commit hook (optional). Prevents broken commits.

**pre-pr**: Before `git push` or creating PR. Release gate.

## Anti-Patterns

Do not skip phases when they fail. Collect all failures before reporting.

Do not treat warnings as errors unless the project has a zero-warning policy.

Do not run full verification in a tight loop. Use quick mode for iteration.

Do not fix issues during verification. This is read-only assessment. Report and exit.

## Integration with Hooks

Verification-loop is manual/command-driven (`/verify`). Hooks are automatic/event-driven (PostToolUse).

Hooks catch issues immediately during editing. Verification-loop catches issues comprehensively before PR.

Both are needed. Hooks prevent introduction. Verification confirms absence.

## Mandatory Checklist

1. Verify language detection ran and found at least one language
2. Verify all applicable phases ran (based on mode)
3. Verify failures were collected, not halted at first error
4. Verify the final verdict (READY/NOT READY) matches the phase results
5. Verify blocking issues list file:line references for every failure
6. Verify coverage percentage is reported if tests ran
7. Verify security scan results are included in pre-pr mode
8. Verify the report uses the exact format specified above
