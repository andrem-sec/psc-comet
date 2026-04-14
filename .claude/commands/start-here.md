---
name: start-here
description: First-time setup — interviews user, writes context files, verifies the system is ready
---

Run this protocol exactly. Do not skip steps. Do not ask all questions at once.

## Step 1 — Welcome

Say:
"Starting Santa Clause setup. I'll ask you a few questions one at a time, then write your answers to the context files. This takes about 2 minutes."

Then ask only this question and wait for the answer:

"What's your role? (e.g., senior backend engineer, indie developer, security researcher, data scientist)"

## Step 2 — Languages

After they answer Step 1, ask:

"What are your primary programming languages and frameworks?"

## Step 3 — Project

After they answer Step 2, ask:

"What project will you be using this with? Give me a one-line description and its current status."

## Step 4 — Style

After they answer Step 3, ask:

"Two quick preferences:
1. Response style — brief and direct, or detailed with reasoning?
2. Anything you want Claude to always avoid doing?"

## Step 5 — Write context/user.md

After they answer Step 4, write their answers to `.claude/context/user.md`. Replace the template placeholders with their actual answers. Confirm: "Written to context/user.md."

## Step 6 — Project scan

Say: "Now I'll scan the project to populate context/project.md."

Invoke the project-scan skill. After it completes, say: "Written to context/project.md."

If there is no project to scan (standalone Claude Code setup), ask:
"What's the project name and type? I'll set up a starter template."
Then write a minimal context/project.md with what they provide.

## Step 7 — Verify registry

Read `.claude/CLAUDE.md`. Confirm the skill and agent registries are present. Report the count:
"Registry confirmed: [N] skills, [N] agents, [N] hooks active."

## Step 8 — Run heartbeat

Invoke the heartbeat skill. This confirms the full session protocol works.

## Step 9 — Tour

Present PSC's capabilities in three parts. Be conversational and concise -- this is a tour, not documentation.

**Part A -- Core workflow (always show)**

Tell the user:

- "Session memory: /heartbeat at the start and /wrap-up at the end. Each session, Claude reads what was learned before and adds to it. Over time it stops repeating the same mistakes and asking the same questions."
- "Three automatic gates: /plan-first before any change touching 3+ files. /code-review before merging. /security-gate before deploying. Same structured checklist every time -- not a reminder, a gate."
- "Hooks enforce standards at the tool level without reminders: shellcheck on every shell script edit, secret detection before writes, bypass permission blocks. It happens automatically."

**Part B -- Role-adaptive skill highlights**

Based on the role the user gave in Step 1, surface 2-3 relevant skills. Name each one, one line on what it does, and the slash command.

| If role includes... | Highlight these |
|---------------------|-----------------|
| security / pentest / red team | /cso (multi-phase OWASP audit), /roe (rules of engagement gate before any probe), /investigate (root-cause locked before any fix) |
| frontend / design / UI | /brand-context (load brand assets before any UI code), /ui-slop-guard (catch AI slop patterns in components), /design-token-guard (enforce token layer, no raw hex) |
| backend / engineer / developer | /tdd (test-first with explicit phase gates), /debug (structured root-cause, no blind retries), /feature (full pipeline: interview to spec to plan to build to review) |
| data / ML / research | /deep-research (multi-source synthesis with citations), /deep-interview (Socratic exploration before writing requirements) |
| manager / lead / architect | /consensus-plan (planner + architect deliberation loop, produces ADR), /retro (git-based engineering retrospective with velocity and quality breakdown) |

If the role does not match any category, highlight: /tdd, /debug, /checkpoint, /code-review.

**Part C -- Integration menu**

Before presenting the catalog, detect the user's platform by running:

```bash
uname -s 2>/dev/null || echo "Windows"
```

Store the result as one of: `windows`, `linux`, `macos`. Use it to show the correct setup instructions below.

Say: "PSC also ships with optional integrations. Here is what is available:"

Present this catalog:

1. **Obsidian vault** -- connects Claude to your Obsidian notes as a second brain. Read and write notes, search the vault full-text, and declare exactly which folders Claude can access. Command: `/obsidian-setup` (handles platform differences automatically)

2. **Continuous Learning** -- extracts patterns from your sessions and promotes them to a searchable instinct library. Use `/instinct-status`, `/evolve`, and `/instinct-export` to manage what Claude has learned.

3. **UI/UX Pro Max** -- extended design skill suite for production UI work across 17 frameworks. Includes design system generation, slide creation, and logo and icon design.

<!-- INTEGRATION CATALOG: Add new integrations here as they are built.
     Format: **Name** -- one-line description of what it adds. Command or setup instruction.
     Keep entries in this list so the tour stays current as PSC grows. -->

Then ask: "Which of these would you like to set up now? Say the name or number, or say 'skip' to come back later."

For each integration the user selects, use the platform-appropriate instructions:

**Obsidian vault**
- All platforms: invoke `/obsidian-setup` -- it handles platform differences internally

**Continuous Learning**
- Linux / macOS: `bash scripts/setup.sh --only 4`
- Windows (Git Bash): `bash scripts/setup.sh --only 4` (run in Git Bash, not PowerShell)
- Windows (no Git Bash): `! bash scripts/setup.sh --only 4` in the Claude Code prompt, or install Git for Windows first

**UI/UX Pro Max**
- Linux / macOS: `bash scripts/setup.sh --only 6`
- Windows (Git Bash): `bash scripts/setup.sh --only 6` (run in Git Bash, not PowerShell)
- Windows (no Git Bash): `! bash scripts/setup.sh --only 6` in the Claude Code prompt, or install Git for Windows first

If they say 'skip' or 'none', acknowledge and proceed to Step 10.

## Step 10 — Done

Say:
"Setup complete. Your session protocol:
- Start: /heartbeat
- End: /wrap-up
- New feature: /prd → /plan → /tdd
- Before commit: /code-review → /security-gate → /commit
- Stuck: /debug
- Long task: /checkpoint every 5 steps"

Do not add anything else. Setup is done.
