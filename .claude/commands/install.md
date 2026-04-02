# PSC Install

Run the PSC dependency installer.

## What It Does

Checks the status of all PSC components and installs what is missing. Safe to re-run -- each component checks its own state first.

## Components

| # | Component | Required | What it installs |
|---|-----------|----------|-----------------|
| 1 | Core hooks | Yes | Patches hook paths to absolute for this machine |
| 2 | Node.js check | Yes | Verifies Node.js 18+ is installed |
| 3 | Node.js deps | Yes | npm install for MCP server packages |
| 4 | Python / instincts | Optional | Continuous learning CLI dependencies |
| 5 | Obsidian MCP | Optional | Vault + Omnisearch integration (requires interactive terminal) |
| 6 | UI/UX Pro Max | Optional | Design skills (clones external repo) |

## Usage

```
/install
```

Claude will run `setup.sh --all`, which handles all non-interactive components automatically. Component 5 (Obsidian MCP) requires an interactive terminal and will be skipped with instructions.

## Running a Single Component

```bash
bash scripts/setup.sh --only 4
bash scripts/setup.sh --only 5
```

## Skipping Components

```bash
bash scripts/setup.sh --skip 5 6
```

## Status Only

```bash
bash scripts/setup.sh --status
```

---

## Instructions for Claude

When this command is invoked, run:

```bash
bash scripts/setup.sh --all
```

The `--all` flag runs all non-interactive components automatically. Components that require an interactive terminal (Obsidian MCP) will be skipped with a message telling the user how to run them manually.

After it finishes, remind the user to restart Claude Code if any MCP servers or hooks were installed.

If the script is not found, check that `scripts/setup.sh` exists in the project root.
