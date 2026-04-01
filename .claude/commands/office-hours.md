---
name: office-hours
description: YC-style product idea validation — forces specificity on demand, problem, and approach before any code is written
---

Invoke the office-hours protocol now. No implementation code is written in this skill. Output is a design document only.

## Phase 1 — Context and mode

Read any existing docs, PRD, or context/project.md. Then ask (one question, wait for answer):

"Are you validating a new product idea (Startup mode) or planning how to build something you've already decided on (Builder mode)?"

## Phase 2A — Startup mode (6 forcing questions, one at a time)

Ask each question and wait for the full answer before asking the next.

**Q1 — Demand reality:** "Give me a specific example of someone asking for this — not expressing interest, but taking an action that cost them something (money, time, switching)."

**Q2 — Status quo:** "What does this person do today without your solution? What does that cost them weekly in time or money?"

**Q3 — Desperate specificity:** "Name the actual person. Job title, company size, the exact situation they were in."

**Q4 — Narrowest wedge:** "What is the smallest version someone would pay for today — not the vision, the wedge."

**Q5 — Observation and surprise:** "What surprised you when you watched someone try to solve this problem?"

**Q6 — Future fit:** "Why does this become more essential in 3 years, not less?"

Push twice on each answer. The first answer is polished. The real answer comes on the second or third push.

## Phase 2B — Builder mode

Ask: "What are you building and what is the coolest version of it?" Then: "What's the most interesting technical or UX constraint you're working within?"

Brainstorm generatively — delight, unexpected angles, the version that would make someone tell a friend.

## Phase 3 — Premise challenge

Regardless of mode, identify and challenge the 2-3 foundational assumptions. For each: "What would have to be true for this to work? How do you know it is?"

Do not proceed to Phase 4 until premises are examined. This phase is never optional.

## Phase 3.5 — Second opinion (optional)

Ask: "Do you want a cold-read second opinion? Options: [C]laude subagent / [G]emini CLI / [X]Codex CLI / [S]kip"

- **Claude subagent**: Spawn a fresh Claude subagent with only the problem statement and no prior conversation. Ask it: "What are the three biggest risks and the strongest counterargument to building this?" Compare with your own assessment.
- **Gemini CLI**: Instruct user to run `gemini` with the problem statement if Gemini CLI is configured.
- **Codex CLI**: Instruct user to run `codex` with the problem statement if Codex CLI is configured.
- **Skip**: Proceed directly to Phase 4.

## Phase 4 — Alternatives (mandatory)

Generate at least 2 approaches:
1. Minimal viable — smallest thing that tests the core premise today
2. Ideal architecture — full vision if constraints were removed

For each: what it validates, what it costs, what it defers.

## Phase 5 — Design document

Write the design document and save to `context/design/[slug]-[date].md`.

Structure:
- Problem statement
- Demand evidence (from Phase 2 answers)
- Core premises and validation status
- Second opinion findings (if run)
- Approaches considered
- Recommended approach
- Open questions
- Concrete next action (mandatory — not "go build", but a specific verifiable step)

Status: DRAFT until user confirms → APPROVED

## Rules

- One question per AskUserQuestion call. Never batch independent questions.
- Specificity is the standard. "Healthcare enterprises" → "Sarah at Acme, ops manager, $200/week pain."
- Behavior beats interest. Waitlist signups are not demand. Money paid, panic when broken, organic expansion — those are demand.
- No code written in this skill. Hand off to /prd or /plan when design doc is APPROVED.
