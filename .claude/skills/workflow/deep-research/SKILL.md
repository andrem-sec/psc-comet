---
name: deep-research
description: 6-step multi-source research workflow with inline citations and synthesis
version: 0.1.0
level: 3
triggers:
  - "/research"
  - "research this topic"
  - "investigate [topic]"
  - "what does the literature say"
context_files: []
steps:
  - name: Clarify Goal
    description: Define research question and scope boundaries
  - name: Plan Sub-Questions
    description: Break into 3-5 focused sub-questions
  - name: Multi-Source Search
    description: Gather 15-30 sources across multiple channels
  - name: Deep Read
    description: Fully read 3-5 key sources
  - name: Synthesize
    description: Integrate findings into thematic report with inline citations
  - name: Deliver
    description: Present report with Executive Summary, Key Takeaways, Sources, Methodology
---

# Deep Research Skill

Structured multi-source research workflow. Produces synthesis reports with inline citations and explicit methodology.

## What Claude Gets Wrong Without This Skill

Without structured research, Claude:
1. Jumps straight to synthesis without reading enough sources (superficial coverage)
2. Doesn't cite sources inline, making claims unverifiable
3. Stops at 3-5 sources instead of gathering diverse perspectives (narrow research)
4. Produces summaries instead of synthesis (lists facts, doesn't integrate themes)
5. Doesn't acknowledge gaps or limitations in available information

Deep research ensures comprehensive, verifiable, and transparent knowledge synthesis.

## The 6-Step Workflow

### Step 1: Clarify Goal

**Define the research question explicitly.**

Transform vague requests into focused questions:
- Vague: "Research React"
- Focused: "What are the performance implications of using Context API vs Redux for global state in React 18?"

**Specify scope boundaries:** Timeframe (last 12 months vs all history), domain (academic vs industry vs docs), depth (30 min survey vs 2-hour deep dive).

**Identify success criteria:** What decision does this inform? What confidence level is needed?

### Step 2: Plan 3-5 Sub-Questions

Break the research question into focused sub-topics.

**Example:** React Context vs Redux → sub-questions: performance difference, bundle size, official React 18 guidance, community trends, maintainability tradeoffs.

**Each sub-question:** answerable from 3-6 sources, focuses on one dimension, contributes to overall question.

### Step 3: Multi-Source Search (15-30 sources)

**Source diversity is critical.** Gather 15-30 sources from: official docs (APIs, RFCs, changelogs), academic papers (ArXiv, IEEE, ACM), industry blogs (Thoughtworks, company eng blogs), community signals (GitHub, Stack Overflow, Reddit), tools/data (npm trends, benchmarks).

Skim all, mark 3-5 for deep read, record metadata. **Prefer sources <12 months old** (tech moves fast).

### Step 4: Deep Read (3-5 key sources)

**Read the top 3-5 sources in full, not just abstracts.**

**Selection criteria:**
- Most authoritative (official docs, core maintainers, recognized experts)
- Most comprehensive (covers multiple sub-questions)
- Most recent (published within 12 months if possible)
- Most relevant to decision criteria

**While reading, extract:**
- Key claims and their supporting evidence
- Methodology (how was this measured/determined?)
- Limitations acknowledged by the author
- Contradictions with other sources (note these explicitly)

**Deep read time budget:**
- ~15-20 minutes per source
- Take notes in a temporary scratch file
- Mark direct quotes vs paraphrasing

### Step 5: Synthesize

**Synthesis is NOT summarization.**

**Summarization (wrong):**
- Source A says X
- Source B says Y
- Source C says Z

**Synthesis (correct):**
- Theme 1: Performance characteristics
  - Evidence from Source A, Source C, and Benchmark D
  - Consensus: [statement], with caveats: [limitations]
  - Minority view: Source B found [different result] due to [methodology difference]

**Organize by themes, not by sources.**

Identify:
- **Consensus**: What do most sources agree on?
- **Contradictions**: Where do sources disagree? Why?
- **Gaps**: What questions remain unanswered?
- **Context**: What factors affect the conclusions (scale, use case, constraints)?

**Every claim needs a citation.**

Use inline citations: [Source Title, Date] or [Author, Date]

Example:
> "React 18's automatic batching reduces re-renders by 30-50% in typical applications [React 18 RFC, 2021], making Context API performance comparable to Redux for moderate state complexity [Benchmark by Josh Comeau, 2022]. However, at >1000 component trees, Redux still outperforms due to selector memoization [Redux Toolkit Docs, 2023]."

### Step 6: Deliver

**Report Format:**

```markdown
# Research Report: [Question]

**Date:** [ISO date]
**Scope:** [Brief scope statement]

## Executive Summary

[3-5 sentence synthesis answering the research question directly. Decision-focused.]

## [Theme 1]

[Synthesis with inline citations]

## [Theme 2]

[Synthesis with inline citations]

## [Theme 3]

[Synthesis with inline citations]

## Key Takeaways

1. [Actionable insight 1]
2. [Actionable insight 2]
3. [Actionable insight 3]

## Limitations and Gaps

[What is uncertain or unknown? Where do sources contradict? What follow-up research is needed?]

## Sources

[Full citation list with URLs, sorted by relevance or alphabetically]

1. [Title] by [Author], [Date]. [URL]
2. [Title] by [Author], [Date]. [URL]
...

## Methodology

[Brief description of search strategy, source selection criteria, and analysis approach]
```

**Report should be:**
- Scannable: Executive Summary + Key Takeaways enough for quick decision
- Verifiable: Every claim has inline citation to source
- Transparent: Methodology and limitations explicitly stated
- Actionable: Focused on decision criteria, not exhaustive literature review

## Source Quality Standards

**High-Quality Sources:**
- Official documentation from authoritative bodies
- Peer-reviewed academic papers
- Industry analysis from recognized experts with track record
- Empirical benchmarks with published methodology
- Primary sources (author of the technology, core maintainer)

**Low-Quality Sources:**
- Opinion pieces without supporting evidence
- Marketing content disguised as analysis
- Uncited claims or "everyone knows" statements
- Sources >3 years old (unless historical context needed)
- Anonymous or pseudonymous sources without credibility signals

**When in doubt, apply the hierarchy:**
1. Official docs and RFCs (highest authority)
2. Academic papers and empirical benchmarks
3. Recognized industry experts with transparent methodology
4. Community consensus (Stack Overflow, GitHub discussions)
5. Individual blog posts (lowest, use for color only)

## Acknowledging Gaps

**Explicitly state when:**
- Sources contradict and no clear resolution exists
- No recent sources available (most recent is >2 years old)
- Only anecdotal evidence exists (no empirical benchmarks)
- Research is limited to specific context (single framework, single scale, single use case)

**Example gap acknowledgment:**
> "Performance comparisons are limited to client-side React applications. Server-side rendering (SSR) performance was not covered in available sources. Follow-up research needed for Next.js-specific implications."

**Gaps are not failures.** Transparency about limitations increases report credibility.

## Integration with Existing Skills

**Complements investigate skill:**
- investigate: codebase-internal debugging and root cause analysis
- deep-research: external knowledge synthesis (literature, tools, practices)

**Feeds into other skills:**
- prd: Research informs requirements (technical feasibility, best practices)
- consensus-plan: Research provides evidence for architectural decisions
- tdd: Research identifies testing patterns and coverage standards

## Anti-Patterns

**Stopping at 3 sources**: Insufficient diversity. You need 15-30 to identify consensus and contradictions.

**Summarizing instead of synthesizing**: Listing "Source A says X, Source B says Y" is not synthesis. Organize by themes, integrate evidence.

**Skipping inline citations**: Claims without citations are unverifiable. Every assertion needs a source reference.

**Using only recent sources**: Sometimes historical context matters. If researching "why does X exist", older sources (original RFC, launch announcement) are valuable.

**Ignoring contradictions**: When sources disagree, investigate why. Methodology differences? Different contexts? One source outdated?

## Mandatory Checklist

1. Verify research question clearly stated with explicit scope boundaries
2. Verify 3-5 sub-questions defined, each focusing on single dimension
3. Verify 15-30 sources gathered across multiple channels (docs, academic, industry, community)
4. Verify 3-5 key sources read in full (not just abstracts or summaries)
5. Verify synthesis organized by themes, not by sources
6. Verify every claim has inline citation with source and date
7. Verify report includes Executive Summary, Key Takeaways, Sources, Methodology, and Limitations sections
8. Verify gaps and contradictions explicitly acknowledged (transparency over false confidence)
