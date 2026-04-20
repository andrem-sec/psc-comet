# Agents Registry

Load this file on demand when selecting or spawning an agent. Do not load at session start.

The Constraint column is PSC operational policy — it is not enforced by Claude Code itself.
Respect it when writing agent spawn prompts.

| Agent | Constraint | Role |
|-------|-----------|------|
| researcher | readonly | research and synthesis |
| planner | readonly | phased implementation plans |
| architect | readonly | system design, ADR generation |
| security-reviewer | readonly+isolated | security audit |
| code-reviewer | readonly+isolated | quality and semantic review |
| verifier | readonly | acceptance criteria verification |
| mcp-agent | MCP-only | all MCP tool operations |
| orchestrator | no-impl | multi-agent mission coordination |
| docker-sandbox | worktree-isolated, permissionMode: dontAsk, ROE required | autonomous security scanning |
| ui-critic | readonly | visual design critique against reference |
| a11y-reviewer | readonly+isolated | WCAG 2.1 AA accessibility audit |
| design-researcher | readonly | site teardown, inspiration curation, design vocabulary |
