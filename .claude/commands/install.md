# PSC Install

Run the interactive PSC dependency installer.

## What It Does

Presents a menu of all PSC components with their current status, lets you choose what to install, and runs each selected component. Safe to re-run — each component checks its own state first.

## Components

| # | Component | Required | What it installs |
|---|-----------|----------|-----------------|
| 1 | Core hooks | Yes | Patches hook paths to absolute for this machine |
| 2 | Node.js check | Yes | Verifies Node.js 18+ is installed |
| 3 | Node.js deps | Yes | npm install for MCP server packages |
| 4 | Python / instincts | Optional | Continuous learning CLI dependencies |
| 5 | Obsidian MCP | Optional | Vault + Omnisearch integration (interactive) |

## Usage

```
/install
```

Claude will run:

```bash
bash scripts/setup.sh
```

## Running a Single Component Later

If you skipped a component, re-run the setup and skip the ones already done:

```bash
bash scripts/setup.sh
```

The status column shows what is already configured so you can skip those.

---

## Instructions for Claude

When this command is invoked, run:

```bash
bash C:/psc-comet-main/scripts/setup.sh
```

The script is interactive — wait for it to complete. After it finishes, remind the user to restart Claude Code if any MCP servers or hooks were installed.

If the script is not found, check that `C:/psc-comet-main/scripts/setup.sh` exists.
