---
name: skill-stocktake
description: Quality audit of installed skills with portfolio health dashboard
version: 0.1.0
level: 3
triggers:
  - "/skill-stocktake"
  - "audit skills"
  - "skill health check"
  - "review skill quality"
context_files:
  - context/project.md
  - context/learnings.md
steps:
  - name: Mode Selection
    description: Choose Quick Scan (changed skills only) or Full Stocktake (all skills)
  - name: Skill Collection
    description: Gather all installed skills from .claude/skills/ directories
  - name: Evaluation
    description: Assess each skill against four dimensions using subagent
  - name: Verdict Assignment
    description: Assign one of four verdicts (Keep, Improve, Update, Retire, Merge)
  - name: Report Generation
    description: Generate portfolio health dashboard with findings
  - name: Cache Results
    description: Write results to ~/.claude/skills/skill-stocktake/results.json
---

# Skill Stocktake Skill

Quality audit of your installed skills. Identifies skills that are outdated, redundant, or underperforming.

## What Claude Gets Wrong Without This Skill

Without systematic skill audits, Claude:
1. Continues using outdated skills that conflict with current best practices
2. Fails to identify redundant skills that bloat context windows
3. Doesn't detect skills with poor actionability (vague or unverifiable)
4. Misses opportunities to merge overlapping skills into stronger unified versions
5. Accumulates technical debt in the skill portfolio over time

The skill stocktake ensures your skill collection stays lean, current, and effective.

## Two Modes

### Quick Scan
**Duration:** 5-10 minutes
**Scope:** Only skills modified in the last 30 days or flagged in learnings.md
**Use When:** Regular maintenance, after adding new skills, post-session cleanup

**Process:**
1. Scan git history for modified SKILL.md files in last 30 days
2. Check context/learnings.md for skill-related issues (failures, confusion, conflicts)
3. Evaluate only the changed skills
4. Report verdicts and recommended actions

### Full Stocktake
**Duration:** 20-30 minutes
**Scope:** All skills in .claude/skills/core/ and .claude/skills/workflow/
**Use When:** Quarterly reviews, major version upgrades, before skill evolution

**Process:**
1. Enumerate all installed skills (core + workflow + learned)
2. Spawn a subagent with read-only access to evaluate each skill
3. Generate comprehensive portfolio health report
4. Identify clusters of related skills that could merge
5. Cache results for Quick Scan reference

## Four Verdicts

**KEEP**: Skill is current, actionable, unique, and effective. No changes needed.

**IMPROVE**: Skill has value but needs refinement. Issues might include:
- Vague or unverifiable checklist items
- Missing anti-patterns section
- Unclear triggers
- No integration with context files

**UPDATE**: Skill content is outdated. Triggers might include:
- References deprecated tools or APIs
- Conflicts with newer skills
- Uses old architectural patterns
- Doesn't follow current SKILL.md format standards

**RETIRE**: Skill provides no value or is harmful. Reasons to retire:
- Functionality fully replaced by another skill
- Triggers never match user requests (check learnings.md for evidence)
- Anti-patterns outnumber patterns (skill is net-negative)
- Violates CLAUDE.md rules

**MERGE**: Skill overlaps significantly with 1-2 other skills. Merge candidates when:
- Two skills share 60%+ of checklist items
- Skills have similar triggers but slightly different focus
- One skill is a specialized case of another
- Combined skill would be under 250 lines (Level 3 limit)

## Evaluation Dimensions

**Actionability** (High / Medium / Low)
- Are checklist items concrete and verifiable?
- Does "What Claude Gets Wrong" clearly explain the problem?
- Are steps specific enough to follow?

**Scope Fit** (Right-Sized / Too Broad / Too Narrow)
- Does the skill address a single coherent problem?
- Is it specific enough to be useful but general enough to apply often?
- Right-sized skills: 100-240 lines, 6-8 checklist items, 3-5 triggers

**Uniqueness** (Unique / Overlaps / Redundant)
- Does another skill already cover this territory?
- If there's overlap, is it intentional (different abstraction levels) or accidental?
- Check for duplicate checklist items across skills

**Currency** (Current / Aging / Outdated)
- Does the skill reference current tools and practices?
- Has it been updated in the last 6 months?
- Does it conflict with learnings.md entries about what doesn't work?

## Subagent Evaluation Protocol

When running Full Stocktake, spawn a subagent with this configuration:

```yaml
subagent_type: researcher
tools: [Read, Grep, Glob]
prompt: |
  Evaluate the skill at [skill-path].

  Read the SKILL.md file and assess it against four dimensions:
  1. Actionability: concrete, verifiable steps?
  2. Scope Fit: single coherent problem, right-sized?
  3. Uniqueness: overlaps with other skills?
  4. Currency: uses current tools/practices?

  Also read context/learnings.md and check if this skill appears in failure patterns.

  Return a structured evaluation:
  - Dimension scores (High/Medium/Low, etc.)
  - Verdict (KEEP/IMPROVE/UPDATE/RETIRE/MERGE)
  - Reasoning (2-3 sentences)
  - If MERGE, list target skills
```

The subagent provides holistic AI judgment on subjective quality dimensions that resist simple rule-based checks.

## Results Cache

Store stocktake results at `~/.claude/skills/skill-stocktake/results.json`:

```json
{
  "timestamp": "2026-03-28T18:30:00Z",
  "mode": "full",
  "total_skills": 31,
  "verdicts": {
    "KEEP": 22,
    "IMPROVE": 5,
    "UPDATE": 2,
    "RETIRE": 1,
    "MERGE": 1
  },
  "skills": [
    {
      "name": "tdd",
      "path": ".claude/skills/workflow/tdd/SKILL.md",
      "verdict": "KEEP",
      "actionability": "High",
      "scope_fit": "Right-Sized",
      "uniqueness": "Unique",
      "currency": "Current",
      "reasoning": "Well-defined Red-Green-Refactor phases, concrete coverage targets, no conflicts"
    }
  ]
}
```

Quick Scan reads this cache to identify skills already evaluated recently.

## Anti-Patterns

**Audit paralysis**: Spending more time auditing skills than using them. Run Full Stocktake quarterly at most.

**Over-retiring**: Removing skills just because they're rarely used. Low-frequency high-value skills (like security-gate) should stay.

**Subjective aesthetics**: Retiring skills because "the writing style feels old." If the skill works and is current, keep it.

**Ignoring merge recommendations**: When two skills have 60%+ overlap, merging reduces context bloat and eliminates confusion about which to invoke.

**Skipping the subagent**: Evaluating all skills manually takes 2-3x longer and misses patterns. Use the subagent for holistic judgment.

## Mandatory Checklist

1. Verify mode selected matches intent (Quick Scan for maintenance, Full Stocktake for comprehensive review)
2. Verify all skills in scope were evaluated (check skills/ directories match results count)
3. Verify each verdict has supporting reasoning (actionability, scope fit, uniqueness, currency scores recorded)
4. Verify MERGE verdicts identify specific target skills to merge with
5. Verify IMPROVE verdicts list specific issues to fix (vague checklist items, missing sections, etc.)
6. Verify RETIRE verdicts cite replacement skill or evidence of non-use from learnings.md
7. Verify results cached to ~/.claude/skills/skill-stocktake/results.json with timestamp
8. Verify context/learnings.md updated if skill failures or redundancies were discovered
