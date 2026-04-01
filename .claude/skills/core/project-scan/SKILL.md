---
name: project-scan
description: Auto-populate context/project.md by reading the current codebase
version: 0.1.0
level: 2
triggers:
  - "scan project"
  - "scan codebase"
  - "populate project context"
  - "/scan"
context_files: []
steps:
  - name: Detect Stack
    description: Identify language, framework, and package manager from manifest files
  - name: Find Entry Points
    description: Locate main entry points — where execution begins
  - name: Map Key Modules
    description: Identify the top-level modules and their single-line purpose
  - name: Check Infrastructure
    description: Detect database, external services, Docker, CI configuration
  - name: Check Existing Docs
    description: Read README and any existing architecture docs for context
  - name: Write project.md
    description: Populate context/project.md with findings — replacing template placeholders
---

# Project Scan Skill

Reads the current codebase and auto-populates `context/project.md`. Run once on setup, re-run when the project's structure changes significantly.

## What Claude Gets Wrong Without This Skill

Without a scan, `context/project.md` stays as a template. Every skill that reads it gets nothing useful. The context layer is only as good as the data in it.

## Detection Protocol

### Stack Detection

Check for manifest files in order:

| File | Indicates |
|------|-----------|
| `package.json` | Node.js — check `dependencies` for framework (next, express, fastapi via py) |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Python — check for FastAPI, Django, Flask, etc. |
| `go.mod` | Go — check module name and key imports |
| `Cargo.toml` | Rust |
| `pom.xml` / `build.gradle` | Java/Kotlin |
| `Gemfile` | Ruby |
| `composer.json` | PHP |
| `*.csproj` | .NET/C# |

Read the manifest. Extract: language, framework, key dependencies (non-obvious ones only — not lodash, not requests).

### Entry Points

| Stack | Look For |
|-------|---------|
| Node.js | `"main"` in package.json, `src/index.ts`, `app.ts`, `server.ts` |
| Python | `main.py`, `app.py`, `__main__.py`, `manage.py` (Django) |
| Go | `cmd/*/main.go`, `main.go` |
| Rust | `src/main.rs`, `src/lib.rs` |

Read the entry point file. Note what it initializes.

### Module Mapping

List directories at the top level of `src/`, `lib/`, `app/`, `pkg/`, or equivalent. For each:
- Read the directory listing
- If there's an `index.ts`, `__init__.py`, or equivalent, read the first 20 lines
- Write a one-line description of what that module does

Cap at 10 modules. If there are more, note the count and describe the most significant.

### Infrastructure Detection

| File/Pattern | Indicates |
|-------------|-----------|
| `docker-compose.yml` | Local Docker services — read service names |
| `Dockerfile` | Containerized deployment |
| `.github/workflows/` | GitHub Actions CI |
| `*.tf` files | Terraform infrastructure |
| `k8s/` or `kubernetes/` | Kubernetes deployment |
| `.env.example` | Read to understand required environment variables |

### Existing Docs

Read `README.md` (first 50 lines). Extract anything that describes architecture, constraints, or setup requirements not already captured.

## Output Format

Write directly to `context/project.md`, replacing template placeholders. Do not append — overwrite the template sections with real data.

Sections to populate:
- **Identity** — name, type (derived from stack), status (assume "active development" unless README says otherwise)
- **Tech Stack** — language, framework, database (from docker-compose or env vars), infrastructure
- **Architecture** — 2-3 sentences from README + entry point reading
- **Current State** — leave "In Progress" and "Known Issues" blank for user to fill — note this
- **Do Not** — leave blank for user to fill — note this

## After Writing

State: "context/project.md populated. Please review and fill in:
- Current State → In Progress and Known Issues
- Do Not → approaches specific to this project
- Constraints → anything that can't be changed"

## Anti-Patterns

Do not guess at framework from file extensions alone. Read the manifest.

Do not list every dependency — only the non-obvious ones that shape how the project works.

Do not overwrite anything the user has already filled in. If a section has real content (not template placeholder text), preserve it.

## Mandatory Checklist

1. Verify at least one manifest file was read (not guessed from extensions)
2. Verify entry points were read, not just listed
3. Verify key modules have one-line descriptions from reading, not inference
4. Verify context/project.md was written (not just displayed in chat)
5. Verify user was told which sections still need manual input
