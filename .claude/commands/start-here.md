---
name: start-here
description: First-time setup — interviews user, writes context files, verifies the system is ready
---

Run this protocol exactly. Do not skip steps. Do not ask all questions at once.

## Step 1 — Welcome

Say:
"Starting Santa Claus setup. I'll ask you a few questions one at a time, then write your answers to the context files. This takes about 2 minutes."

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

## Step 9 — Done

Say:
"Setup complete. Your session protocol:
- Start: /heartbeat
- End: /wrap-up
- New feature: /prd → /plan → /tdd
- Before commit: /code-review → /security-gate → /commit
- Stuck: /debug
- Long task: /checkpoint every 5 steps"

Do not add anything else. Setup is done.
