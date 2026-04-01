---
name: office-hours
description: YC-style product idea validation — forces specificity on demand, problem, and approach before any code is written
version: 0.1.0
level: 3
triggers:
  - "validate my idea"
  - "should I build this"
  - "office hours"
  - "/office-hours"
  - "is this worth building"
context_files:
  - context/project.md
  - context/user.md
steps:
  - name: Context and Mode
    description: Read existing docs and PRD if present, then ask Startup vs Builder mode
  - name: Forcing Questions
    description: Startup mode: six demand-reality questions, one at a time, pushing twice per answer
  - name: Builder Brainstorm
    description: Builder mode: generative ideation on delight, constraints, and the version worth telling someone about
  - name: Premise Challenge
    description: Identify and challenge 2-3 foundational assumptions regardless of mode
  - name: Second Opinion
    description: Optional independent risk assessment via Claude subagent, Gemini CLI, or Codex CLI
  - name: Alternatives
    description: Minimum viable approach and ideal architecture: what each validates, costs, and defers
  - name: Design Document
    description: Write structured design document to context/design/[slug]-[date].md, status DRAFT until confirmed
---

# Office Hours Skill

A product idea validation protocol modeled on YC partner sessions. No code is written. The output is a design document that either has a defensible demand case or honestly documents where the gaps are. Think of it as stress-testing a bridge blueprint before pouring any concrete.

## What Claude Gets Wrong Without This Skill

Without structured validation, building starts on expressed interest rather than demonstrated demand. "People said they'd use it" is not demand. A waitlist is not demand. Money paid, panic when broken, organic expansion: those are demand.

The other failure mode is abstraction: "healthcare enterprises" instead of "Sarah, ops manager at a 200-person logistics company, $200/week pain." Specificity is the test of whether the problem is real or imagined.

This skill does not let either failure mode survive to implementation.

## Two Modes

Ask at the start (one question, wait for the answer):

"Are you validating a new product idea (Startup mode) or planning how to build something you have already decided on (Builder mode)?"

### Startup Mode: Six Forcing Questions

Ask one question at a time. Wait for the full answer. Push twice on each response. The first answer is polished. The real answer usually comes on the second or third push.

**Q1: Demand reality**
"Give me a specific example of someone asking for this: not expressing interest, but taking an action that cost them something: money, time, or switching."

**Q2: Status quo cost**
"What does this person do today without your solution? What does that cost them weekly in time or money?"

**Q3: Desperate specificity**
"Name the actual person. Job title, company size, the exact situation they were in."

**Q4: Narrowest wedge**
"What is the smallest version someone would pay for today: not the vision, the wedge."

**Q5: Observation and surprise**
"What surprised you when you watched someone try to solve this problem?"

**Q6: Future fit**
"Why does this become more essential in three years, not less?"

### Builder Mode

Ask: "What are you building and what is the coolest version of it?"

Then: "What is the most interesting technical or UX constraint you are working within?"

Brainstorm generatively: focus on delight, unexpected angles, and the version someone would tell a friend about.

## Phase 3: Premise Challenge (Never Optional)

Regardless of mode, identify the 2-3 foundational assumptions the idea rests on. For each:

"What would have to be true for this to work? How do you know it is?"

This phase does not end until each premise is either substantiated with evidence or honestly flagged as unvalidated. An unvalidated premise is not a blocker: it is a named risk. Hiding it is.

## Second Opinion (Optional)

Ask: "Do you want a cold-read second opinion? Options: [C] Claude subagent / [G] Gemini CLI / [X] Codex CLI / [S] Skip"

- **Claude subagent:** Spawn a fresh subagent with only the problem statement, no prior conversation. Ask it: "What are the three biggest risks and the strongest counterargument to building this?" Compare with your own assessment.
- **Gemini CLI / Codex CLI:** Instruct the user to run the respective tool with the problem statement if configured locally.
- **Skip:** Proceed to alternatives.

## Phase 4: Alternatives (Mandatory)

Generate at minimum two approaches:

1. **Minimal viable**: the smallest thing that tests the core premise today. What does it validate? What does it cost? What does it defer?
2. **Ideal architecture**: the full vision if constraints were removed. Same three questions.

This is not a preference question. Both must be written out, because the gap between them reveals the assumptions embedded in the preferred approach.

## Design Document

Save to `context/design/[slug]-[date].md`.

Required sections:
- Problem statement
- Demand evidence (direct quotes or specific behaviors from Phase 2)
- Core premises and validation status (validated / unvalidated / refuted)
- Second opinion findings (if run)
- Approaches considered (with tradeoffs)
- Recommended approach
- Open questions
- Concrete next action (not "go build": a specific, verifiable step)

Status field: DRAFT until user confirms. APPROVED once confirmed.

Hand off to `/prd` or `/plan` only after the document is APPROVED.

## Anti-Patterns

Do not accept "people want this" as demand evidence. Demand is behavior that costs something: money paid, friction absorbed, alternatives abandoned.

Do not batch questions. One question per AskUserQuestion call. Batching lets the user give one polished answer instead of facing each question individually.

Do not skip the premise challenge. A well-articulated demand case can still rest on a false foundational assumption.

Do not write any code in this skill. If the user starts asking about implementation, redirect: "Let us get the design document to APPROVED first, then hand off to /prd."

## Mandatory Checklist

1. Verify mode was asked and answered before proceeding to questions
2. Verify each question in Startup mode was asked individually with a wait for the answer
3. Verify each answer was pushed back on at least twice before accepting it
4. Verify the premise challenge ran regardless of mode
5. Verify at least two approaches (minimal and ideal) were documented
6. Verify the design document was saved to context/design/[slug]-[date].md
7. Verify the concrete next action is a specific verifiable step, not a category
8. Verify no implementation code was written or suggested in this skill
