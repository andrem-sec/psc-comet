---
name: context-budget
description: Token audit across agents, skills, and MCP with cost optimization guidance
version: 0.1.0
level: 2
triggers:
  - "audit context usage"
  - "token budget"
  - "context cost"
  - "optimize context"
context_files:
  - context/project.md
steps:
  - name: Inventory Collection
    description: Count skills, agents, MCP servers, and hooks
  - name: Token Estimation
    description: Estimate tokens per component category
  - name: Cost Calculation
    description: Calculate per-session cost at current model pricing
  - name: Bottleneck Identification
    description: Identify highest token consumers
  - name: Optimization Recommendations
    description: Suggest consolidation or reduction strategies
---

# Context Budget Skill

Token audit and cost optimization for Claude Code configurations. Identifies context bloat and suggests fixes.

## What Claude Gets Wrong Without This Skill

Without context budgeting, you:
1. Don't know which components consume most context (blind optimization)
2. Add skills/agents/MCP servers without tracking cumulative cost
3. Hit context limits unexpectedly mid-session
4. Pay for unused MCP tools loaded on every message
5. Can't compare context cost vs value for components

Context budgeting makes token consumption visible and actionable.

## Token Cost Breakdown

### Skills
~300 tokens per skill, loaded only when invoked. Typically 1-3 per session = 600-1,500 tokens. Already efficient (on-demand loading).

### Agents
~1,500 tokens per agent, loaded when spawned. Typically 1-2 per session = 1,500-3,000 tokens. Session-isolated. Consolidate if spawning 5+ per session.

### MCP Servers
**Base cost per tool:** ~500 tokens (tool schema with parameters, descriptions, examples)
**Loaded when:** MCP server connected at session start

**Critical insight:** 30-tool MCP server = 15,000 tokens **per message**. Example: 4 MCP servers (filesystem, github, brave-search, obsidian) = ~19,000 tokens per message. 50-turn session: 950K tokens just for schemas. **Primary cost driver.**

### CLAUDE.md
~1,500 tokens (loaded per message). Keep under 200 lines.

### Context Files
~1,000 tokens per file when loaded. 5 files = 5,000 tokens. Low priority.

### Hooks
~75 tokens per hook. Hooks run outside LLM. Negligible cost.

## Cost Calculation Example

**Session Configuration:**
- 30 skills (on-demand, avg 2 invoked): 600 tokens
- 10 agents (1 spawned): 1,500 tokens
- 4 MCP servers (38 tools total): 19,000 tokens per message
- CLAUDE.md: 1,500 tokens
- 3 context files loaded: 3,000 tokens
- 10 hooks: 750 tokens

**Per-Message Cost:** 19,000 (MCP) + 1,500 (CLAUDE.md) + 3,000 (context) + 750 (hooks) = 24,250 tokens
**50-Turn Session:** 24,250 × 50 = 1,212,500 tokens input
**At Sonnet pricing ($3/MTok):** $3.64 per session (input only)

**MCP contribution:** 19,000 / 24,250 = 78% of per-message cost

## Optimization Strategies

### Strategy 1: Reduce MCP Tool Count

**Problem:** 38 tools loaded, only using 12 regularly

**Solution:** Split MCP servers by usage frequency
- Core server (12 frequently-used tools): Always connected
- Extended server (26 occasional tools): Connect only when needed

**Savings:** 26 tools × 500 = 13,000 tokens per message
**50-turn session:** 650,000 tokens saved = $1.95 per session

### Strategy 2: Use mcp-agent Isolation

**Problem:** MCP tools loaded on main agent even though only subagents use them

**Solution:** Follow psc_comet pattern (mcp-agent with MCP-only access)
- Main agent: 0 MCP tools
- mcp-agent: All MCP tools, spawned only when needed

**Savings:** 19,000 tokens × 40 turns (if mcp-agent needed for 10/50 turns) = 760,000 tokens = $2.28

### Strategy 3: Consolidate Skills

**Problem:** 8 skills with 60%+ overlap (e.g., multiple research skills)

**Solution:** Merge into 1-2 unified skills
- Reduces cognitive load (fewer options to choose from)
- Reduces per-invocation cost (single larger skill cheaper than multiple small ones)

**Savings:** Marginal (skills are on-demand), but improves usability

### Strategy 4: Compress CLAUDE.md

**Problem:** CLAUDE.md at 180 lines with verbose descriptions

**Solution:** Use directive imperatives (short commands) instead of explanations
- "Write tests first" vs "Testing is important. You should always write tests before implementation to ensure..."

**Savings:** 500-1,000 tokens per message = 25,000-50,000 per session = $0.08-$0.15

### Strategy 5: Lazy-Load Context Files

**Problem:** All 5 context files loaded at session start, even if only 2 are needed

**Solution:** Skills specify which context files they need (already implemented in frontmatter)
- Load on-demand when skill invoked

**Savings:** 3 files × 1,000 tokens × 50 turns = 150,000 tokens = $0.45 per session

## Budget Report Template

```markdown
# Context Budget Report

**Date:** 2026-03-28
**Configuration:** psc_comet

## Component Inventory

- Skills: 31 (on-demand)
- Agents: 10 (spawn-on-need)
- MCP Servers: 4 (38 tools total)
- CLAUDE.md: 140 lines
- Context Files: 5
- Hooks: 10

## Token Breakdown (Per Message)

| Component | Tokens | % of Total |
|-----------|--------|------------|
| MCP Tools | 19,000 | 78% |
| CLAUDE.md | 1,500 | 6% |
| Context Files | 3,000 | 12% |
| Hooks | 750 | 3% |
| Skills | 600 | 2% |
| **Total** | **24,850** | **100%** |

## Session Cost Estimate

**50-turn session:** 24,850 × 50 = 1,242,500 input tokens
**Model:** Sonnet ($3/MTok input, $15/MTok output)
**Input cost:** $3.73
**Output cost (est 50K tokens):** $0.75
**Total:** ~$4.48 per session

## Optimization Opportunities

1. **MCP isolation** (high impact): Move MCP to mcp-agent only
   - Savings: ~$2.28 per session (51% reduction)

2. **MCP server splitting** (high impact): Separate core vs extended tools
   - Savings: ~$1.95 per session (44% reduction)

3. **Context file lazy-loading** (medium impact): Load only when skill requires
   - Savings: ~$0.45 per session (10% reduction)

**Combined potential savings:** $4.68 → $2.00 per session (57% reduction)
```

## Anti-Patterns

**Premature optimization**: Optimizing context before measuring. Audit first, optimize second.

**Ignoring MCP cost**: Focusing on skill consolidation (2% of cost) while ignoring MCP bloat (78% of cost).

**No tracking over time**: Running audit once. Context bloat accumulates. Audit quarterly.

**Optimizing for tokens, ignoring value**: Removing high-value MCP tools to save tokens. Optimize low-value components first.

## Mandatory Checklist

1. Verify component inventory collected (skills, agents, MCP servers, context files, hooks counted)
2. Verify token estimates calculated per component category (use ~500 tokens per MCP tool baseline)
3. Verify per-message token total calculated (MCP + CLAUDE.md + context + hooks + skills)
4. Verify session cost estimated (50-turn baseline, model pricing applied)
5. Verify MCP contribution percentage calculated (typically 70-80% of total)
6. Verify optimization strategies ranked by impact (MCP isolation/splitting = highest)
7. Verify recommendations are actionable (specific changes, not generic advice)
