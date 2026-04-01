---
name: codebase-onboarding
description: 4-phase systematic codebase onboarding with reconnaissance and artifact generation
version: 0.1.0
level: 3
triggers:
  - "onboard to codebase"
  - "understand this project"
  - "getting started with this codebase"
  - "project overview"
context_files:
  - context/project.md
steps:
  - name: Reconnaissance
    description: Parallel detection of manifests, frameworks, and entry points
  - name: Architecture Mapping
    description: Identify key modules, data flow, and component relationships
  - name: Convention Detection
    description: Extract naming patterns, directory structure, testing approach
  - name: Generate Artifacts
    description: Create Onboarding Guide and suggest CLAUDE.md enhancements
---

# Codebase Onboarding Skill

Systematic new-project onboarding. Produces a 2-minute onboarding guide and CLAUDE.md enhancements.

## What Claude Gets Wrong Without This Skill

Without systematic onboarding, Claude:
1. Jumps into code changes without understanding architecture
2. Violates project conventions (naming, structure, patterns)
3. Asks repetitive questions that could be answered by manifest files
4. Produces generic advice that doesn't match the actual stack
5. Misses critical context (deployment constraints, testing requirements, domain concepts)

Codebase onboarding ensures Claude understands the project before making changes.

## The 4 Phases

### Phase 1: Reconnaissance

**Parallel detection across 3 dimensions:**

**Manifests and Dependencies:**
- package.json, requirements.txt, go.mod, Cargo.toml, pom.xml, build.gradle
- Extract: language, framework, key dependencies, dev dependencies
- Note: monorepo markers (lerna.json, nx.json, turbo.json)

**Framework Detection:**
- React: Check for react in dependencies, look for src/App.tsx or pages/
- Next.js: next.config.js, app/ or pages/ directory
- Django: manage.py, settings.py, models.py patterns
- FastAPI: main.py with @app decorators
- Go: main.go, pkg/ structure, go.work for workspaces

**Entry Points:**
- Web apps: index.html, main.tsx, App.tsx, _app.tsx
- CLIs: main.go, __main__.py, bin/ scripts
- APIs: server.ts, app.py, main.go
- Libraries: index.ts, __init__.py, lib.rs

Run these searches **in parallel** (3 concurrent Glob/Grep operations). Total reconnaissance time: <60 seconds.

### Phase 2: Architecture Mapping

**Identify key modules:**
- Core business logic (models/, services/, lib/)
- API layer (routes/, api/, controllers/)
- Data layer (db/, repositories/, queries/)
- UI layer (components/, views/, pages/)
- Infrastructure (config/, docker/, .github/)

**Trace data flow:**
- Request entry point → routing → business logic → data access
- Example: pages/api/users.ts → services/userService.ts → repositories/userRepo.ts → db

**Component relationships:**
- Shared utilities (used by 3+ modules)
- Core types/interfaces (referenced everywhere)
- External service integrations (auth, payments, email)

**Architecture documentation check:**
- docs/ARCHITECTURE.md, ADRs in docs/decisions/
- README sections on project structure
- Inline comments in entry points

### Phase 3: Convention Detection

**Naming Patterns:**
- File naming: camelCase vs kebab-case vs snake_case
- Component naming: UserProfile.tsx vs user-profile.tsx
- Test files: *.test.ts vs *.spec.ts vs *_test.go

**Directory Structure:**
- Colocation: tests next to source (user.ts + user.test.ts)
- Separation: tests/ directory parallel to src/
- By feature: features/users/ contains routes, services, tests
- By layer: routes/, services/, models/ across all features

**Testing Approach:**
- Unit test framework: Jest, pytest, Go testing, Rust cargo test
- Integration tests: separate directory or mixed with units
- E2E tests: Playwright, Cypress, Selenium location
- Coverage targets: check CI config or package.json scripts

**Code Style:**
- Linter config: .eslintrc, .ruff.toml, .golangci.yml
- Formatter: .prettierrc, black, rustfmt
- Type checking: tsconfig.json strict mode, mypy.ini

### Phase 4: Generate Artifacts

**Onboarding Guide (2-minute read target, ~300 words):**

```markdown
# [Project Name] Onboarding

**Stack:** [Language + Framework + Key Dependencies]
**Type:** [Web App / API / CLI / Library]

## Quick Start
[3-5 command sequence to get running locally]

## Architecture
[1 paragraph: request flow or component hierarchy]

## Key Directories
[4-6 most important directories with one-line descriptions]

## Conventions
- File naming: [pattern]
- Test location: [pattern]
- Import style: [absolute vs relative]

## Common Tasks
- Add new feature: [where to start]
- Add new test: [command + location]
- Run locally: [command]
- Deploy: [process or link to docs]

## Domain Concepts
[3-5 project-specific terms new developers must know]

## Where to Find Things
- Auth: [location]
- API routes: [location]
- Database schema: [location]
- Config: [location]
```

**CLAUDE.md Enhancements:**

Suggest additions to context/project.md:
- Tech stack verification (if stack section incomplete)
- Constraints discovered (deployment targets, browser support, API rate limits)
- Key entry points (for future navigation)
- Testing conventions (for test-first skill)

**Do NOT suggest:**
- Listing every dependency (bloat)
- Describing obvious directories (node_modules, .git)
- Copying the README verbatim (redundant)
- >100 lines of CLAUDE.md additions (exceeds context budget)

## Anti-Patterns

**Analysis paralysis**: Spending 30+ minutes on reconnaissance. Reconnaissance should take <5 minutes. Missing a detail is fine.

**Listing every dependency**: Onboarding guide mentions 40 npm packages. Only list 3-5 most critical dependencies that shape architecture.

**Copying the README**: README is user-facing marketing. Onboarding guide is developer-facing technical context.

**Describing obvious directories**: "src/ contains source code, tests/ contains tests" is noise. Only mention non-obvious structure.

**Exceeding 2-minute read**: Onboarding guide over 500 words means new developers won't read it. Be ruthlessly concise.

## Integration with Existing Skills

**Feeds into:**
- project-scan: Onboarding guide informs project.md population
- prd: Understanding architecture shapes feasibility assessment
- tdd: Testing conventions guide test file creation

**Uses:**
- researcher agent: For parallel reconnaissance searches

## Mandatory Checklist

1. Verify manifests detected and language/framework identified correctly
2. Verify entry points found (web: index.html/App.tsx, CLI: main.go/main.py, API: server file)
3. Verify architecture mapping identifies core modules and data flow (at least 3 key modules)
4. Verify conventions documented (file naming, test location, directory structure)
5. Verify onboarding guide generated and ≤2-minute read (~300 words max)
6. Verify CLAUDE.md enhancement suggestions made but ≤100 lines of additions
7. Verify no obvious directories described (src/, tests/, node_modules/)
8. Verify domain concepts section populated if project has specialized terminology
