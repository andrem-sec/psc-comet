---
name: reasoning-gates
description: Scan task for high-cost branch points, confirm which get deep reasoning, execute with gates active
version: 0.1.0
level: 2
triggers:
  - "/reasoning-gates"
  - "where should we think carefully"
  - "identify branch points"
  - "reasoning gates"
  - "where could we go wrong"
context_files:
  - context/principles.md
steps:
  - name: Principles Check
    description: Before scanning for branch points, read context/principles.md and surface any active principles that apply to this task. Present them to the user with the override protocol.
  - name: Entropy Scan
    description: Scan the task and identify 2-3 branch points where a wrong decision has high reversal cost
  - name: Gate Confirmation
    description: Present candidate gates as a numbered list; user confirms which get a reasoning gate
  - name: Execute with Gates
    description: Proceed with the task; at each confirmed gate, pause and reason through all options before continuing
  - name: Fallback Instruction
    description: For unexpected branches that emerge mid-execution, flag and ask before proceeding
---

# Reasoning Gates Skill

Concentrate reasoning effort where decisions are hardest to reverse. By default, reasoning is
applied uniformly -- the same depth whether choosing a variable name or a database schema.
This skill identifies the specific points in a task where deeper reasoning is worth the cost,
then confirms with the user before investing it.

## What Claude Gets Wrong Without This Skill

Without explicit gate placement, Claude applies uniform reasoning across easy and hard decisions
alike. Low-stakes choices (file naming, minor formatting) consume the same mental effort as
high-stakes choices (data model shape, auth strategy, interface boundaries). The result is
over-engineering on simple decisions and under-reasoning on the ones that matter.

## What Makes a Branch Point High-Cost

A branch point warrants a reasoning gate when **two or more** of these are true:

1. **High reversal cost** -- if the wrong path is taken, unwinding it requires significant rework
2. **Competing valid options** -- multiple approaches appear reasonable; it's not obvious which to pick
3. **Hidden assumption** -- the correct choice depends on an assumption that might be wrong
4. **Downstream impact** -- the decision constrains multiple future decisions
5. **Ambiguous requirement** -- the specification doesn't clearly dictate the answer

One-way-door decisions always get a gate. Two-way-door decisions usually don't.

## Principles Check

Before the entropy scan, read `context/principles.md` and identify any active principles
relevant to the current task. Surface them before presenting branch point candidates:

```
Active principles for this task:
  P-XX: [rule summary] -- say "override P-XX" to bypass
  P-XX: [rule summary] -- say "override P-XX" to bypass
```

If no principles apply, skip this section silently and proceed to the scan.
If the user overrides a principle, follow the override protocol in principles.md before continuing.

## Entropy Scan Format

Output a numbered list of candidates. For each:

```
1. [Branch point name]
   Decision: [What must be decided here]
   Why it's high-cost: [One sentence -- reversal cost / competing options / assumption / downstream]
   Options: [2-3 concrete alternatives]
```

Present the full list before asking for confirmation. Do not reason through them yet -- the scan
is identification only.

## Gate Confirmation

After presenting candidates:

```
Which of these should get a reasoning gate?
  all / [numbers] / none
```

User responds. Confirmed gates get deep reasoning before that decision point is reached during
execution. Unconfirmed gates proceed normally.

## Gate Execution

At each confirmed gate, before making the decision:

1. **Enumerate options** -- list each viable path explicitly
2. **State assumptions** -- what must be true for each option to be correct
3. **Identify the dominant risk** -- what breaks if this choice is wrong
4. **Pick with explicit rationale** -- state the choice and why it wins

Then continue execution. Do not gate indefinitely -- the goal is one well-reasoned decision per
gate, not a committee meeting.

**Depth without extended thinking:** If extended thinking is unavailable, use multi-step verbal
reasoning. Work through the options out loud before committing.

## Fallback Standing Instruction

The fallback applies to two scenarios that emerge during execution:

**1. Unexpected fork** -- a discrete decision point appears that wasn't in the scan:

```
BRANCH DETECTED: [description of the unexpected decision point]
This was not in the original gate list. Do you want to:
  1. Gate it (pause here and reason through it)
  2. Continue with my best judgment
  3. Stop and re-scan
```

**2. Complexity buildup** -- within a continuous output section (plan, report, ADR), complexity
accumulates mid-generation to the point where the next tokens depend on an assumption that
hasn't been verified. This is not a fork -- it's a local concentration of reasoning cost that
wasn't visible from the upfront scan.

When this occurs, pause before continuing that section:

```
COMPLEXITY BUILDUP: [section name]
Reasoning before continuing: [work through the assumption explicitly]
Continuing with: [the resolved path]
```

Do not surface complexity buildup to the user unless it changes the overall approach. Resolve
it inline and continue.

Never silently resolve an unexpected branch. Surface it and wait for a response.

## Anti-Patterns

**Over-gating:** Gating on obviously correct decisions wastes time. If there's one clear answer
and no competing options, it's not a gate candidate.

**Under-gating:** Treating one-way-door decisions as two-way-door decisions is the most common
failure mode. When in doubt about reversibility, gate it.

**Gating the whole task:** Reasoning gates are for branch points, not for every step. If you
find more than 5 candidates in a scan, the task needs decomposition first.

**Post-hoc gating:** Gating after execution has already begun at that point. Gates must be
confirmed before reaching them, not at the moment of decision.

## Mandatory Checklist

1. Verify entropy scan produced 2-3 candidates (not 0, not 6+)
2. Verify each candidate has a stated reason for high reversal cost
3. Verify user confirmed which gates are active before execution began
4. Verify each confirmed gate was paused on with explicit option enumeration
5. Verify unexpected branches during execution were surfaced, not silently resolved
