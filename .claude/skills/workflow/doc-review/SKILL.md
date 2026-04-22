---
name: doc-review
description: Dual-dimension document quality gate — presentation rubric + hallucination grounding check
version: 0.1.0
level: 2
triggers:
  - "/doc-review"
  - "review this doc"
  - "check for hallucinations"
  - "hallucination check"
  - "doc quality check"
context_files:
  - context/user.md
steps:
  - name: Scope
    description: Identify the document type and its stated sources. If no sources are declared, ask the user before proceeding.
  - name: Presentation Pass
    description: Evaluate structure, clarity, and completeness against the rubric.
  - name: Hallucination Pass
    description: For each factual claim, verify it against the stated source material. Flag ungrounded claims.
  - name: Verdict
    description: PASS / REVISE / BLOCK with specific, line-referenced feedback.
---

# Doc Review Skill

Two-pass quality gate for generated documents. Run before delivering any report, PRD, ADR,
email, research summary, wiki page, or other prose output where accuracy matters.

## What Claude Gets Wrong Without This Skill

Without explicit review, generated documents can pass a surface quality check while containing
factual claims that were hallucinated — plausible-sounding assertions with no grounding in the
source material. Claude Code averages 10+ hallucinations per generated research paper.
A one-pass review catches presentation issues but misses grounding failures.

The two-pass structure separates these concerns: Presentation checks quality; Hallucination
checks truth. Both must pass independently.

## Overview-Anchor Pattern

For long documents (PRDs, ADRs, research summaries), use the overview-anchor pattern before
writing the full document:

1. Generate a brief overview (title, 3-5 bullet points, sources list) first
2. Present the overview to the user for confirmation
3. Generate the full document from the confirmed overview

This reduces hallucination risk: the overview forces explicit source declaration upfront, and
each section of the full document is anchored to a confirmed claim.

## Pass 1 -- Presentation

Evaluate the document against this rubric:

| Dimension | Score (1-5) | Criteria |
|-----------|-------------|---------|
| Structure | | Clear sections, logical flow, no orphaned content |
| Clarity | | No ambiguous claims, jargon explained, terms consistent |
| Completeness | | All stated goals addressed, no missing sections |
| Audience fit | | Appropriate for the stated reader (technical vs. non-technical) |

Score 1-2 on any dimension = REVISE. Score 1 on any = BLOCK.

**Common presentation failures:**
- Section headings that do not match their content
- Claims in the introduction not addressed in the body
- Inconsistent terminology for the same concept
- Conclusions that go beyond what the body supports

## Pass 2 -- Hallucination Check

For each factual claim in the document:

1. Identify the source it should be grounded in (stated explicitly or inferable from context)
2. Verify the claim against that source
3. Flag any claim that cannot be verified

**Claim categories:**

| Category | Grounding requirement |
|----------|----------------------|
| Statistics / numbers | Must match source verbatim or cite approximate |
| Named entities (people, orgs, tools) | Must be verifiable from source or prior session context |
| Causal claims ("X causes Y") | Must be explicitly stated in source, not inferred |
| Recommendations | Must follow logically from verified claims |
| Quotes | Must be exact; partial quotes must not change meaning |

**Ungroundable claims** (not necessarily wrong, but unverifiable):
- Claims about future behavior
- Claims about user intent not stated in source
- Generalizations from single examples

Flag ungroundable claims separately from hallucinations. They may be valid but must be
surfaced for the user to validate.

## Verdict Format

**PASS:** Document meets presentation standards and all factual claims are grounded.
State any minor observations that do not require changes.

**REVISE:**
```
Issue: [description]
Location: [section or line reference]
Dimension: [presentation / hallucination / ungrounded]
Fix: [specific recommendation]
Blocking: No
```

**BLOCK:**
```
Issue: [description]
Location: [section or line reference]
Dimension: [presentation / hallucination / ungrounded]
Impact: [what the reader would believe incorrectly]
Fix: [specific recommendation]
Blocking: YES
```

Hallucination findings that would mislead the reader are always BLOCK, not REVISE.

## Document Types and Source Expectations

| Document type | Expected sources |
|--------------|-----------------|
| Research summary | Source papers/URLs declared upfront |
| PRD | User-stated requirements from deep-interview or conversation |
| ADR | Decision drivers stated in the ADR's Context section |
| Email / client report | Facts from session context or user-provided data |
| Wiki page | Library source file (PDF/EPUB path) |
| Slide content | Source document or user-stated outline |

If the document type does not match a known pattern, ask the user to declare sources
before running Pass 2. Do not guess at source material.

## Anti-Patterns

Do not combine doc-review with code-review. They are separate passes with different criteria.

Do not skip Pass 2 because "the document looks reasonable." Plausible hallucinations are
the most dangerous kind.

Do not flag ungrounded claims as hallucinations. They are different: a hallucination
contradicts the source; an ungrounded claim has no source to contradict.

## Mandatory Checklist

1. Verify document type and sources were identified before any scoring
2. Verify Presentation Pass scored all 4 dimensions (not just the failing ones)
3. Verify Hallucination Pass checked every factual claim, not just obvious ones
4. Verify ungrounded claims are listed separately from hallucinations
5. Verify every REVISE or BLOCK finding has a location reference and specific fix
6. Verify verdict is one of: PASS / REVISE / BLOCK
7. Verify BLOCK was used for any hallucination that would mislead the reader
