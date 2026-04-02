# Design Decisions

Research-backed rationale for Santa Clause architectural choices. Each decision links to the source(s) that validated it.

---

## 1. Skills as Knowledge Layer, Not Execution Layer

**Decision:** Skills are markdown knowledge packages (SKILL.md format). They do not run code, call APIs, or execute shell commands.

**Rationale:** The canonical distinction (Source 46 — The New Stack / Skills vs MCP) is: Skills = knowledge layer, MCP = execution layer. Skills teach Claude how to approach a problem. MCP servers give Claude tools to act on the world. Conflating them produces skills that become stale when APIs change and that create implicit runtime dependencies.

**Consequence:** Execution lives in MCP tools, hooks, and agents. Skills stay portable and dependency-free.

---

## 2. MCP Tools Isolated to a Single Agent

**Decision:** Only `mcp-agent.md` is authorized to use MCP tool servers.

**Rationale:** Source 81 (TDS — Claude Skills and Subagents) documents the MCP isolation principle. A realistic multi-server MCP setup carries ~32K tokens per message. Loading this on the main agent or every subagent wastes ~95% of context budget. Lazy loading (one MCP-capable agent, invoked only when needed) recovers that overhead. Additionally, MCP access to external systems should have an explicit authorization boundary.

---

## 3. Review Agents Run in Isolated Fresh Context

**Decision:** The `security-reviewer`, `code-reviewer`, and `architect` agents always run in a fresh context, isolated from the session that wrote the code.

**Rationale:** Source 73 (O'Reilly Auto-Review) documents the Writer/Reviewer anti-pattern: a reviewer who wrote the code sees what they meant to write, not what is actually there. Fresh context eliminates this bias.

**Implementation note:** Fresh context is inherent to all subagents — every subagent runs in its own context window by definition (Official Anthropic Docs, sub-agents.md). The `context: fork` field used in earlier versions is not a real frontmatter field and has been removed. The isolation behavior it was intended to enforce already exists at the platform level.

---

## 4. Plan Mode Required at 3+ Files

**Decision:** Plan mode is mandatory when 3 or more files are affected, for cross-domain work, or for security-sensitive changes.

**Rationale:** Validated by four independent sources: Boris Cherny (Source 48 — Claude Code creator), Official Anthropic Docs (Source 54), SkillsBench benchmark (Source 65 — planning before implementation raised completion rates), and O'Reilly Auto-Review (Source 73 — plan-then-execute pattern). Threshold of 3 files is empirical: below that, context cost of planning exceeds benefit.

---

## 5. CLAUDE.md Line Limit: 200 Lines

**Decision:** CLAUDE.md must not exceed 200 lines.

**Rationale:** Source 48 (Boris Cherny) — the Claude Code creator's direct guidance: CLAUDE.md content competes with working context. Every line of configuration is a line that cannot be used for task context. 200 lines is the confirmed practical limit where Claude begins to deprioritize rules under context pressure.

---

## 6. Progressive Skill Disclosure (Three-Tier Loading)

**Decision:** Skills load in three tiers — frontmatter (~100 tokens, always visible), SKILL.md body (~5K tokens, on activation), references/ directory (loaded per step only).

**Rationale:** Source 65 (SkillsBench) found that focused 2-3 module skills outperform comprehensive documentation dumps. Median effective skill size: 2.3 KB. Loading everything upfront wastes context; loading nothing until needed creates latency on first invocation. Three-tier loading is the balance: frontmatter gives enough signal to decide whether to activate, body gives full guidance on activation, references load only for the specific step that needs them.

---

## 7. No Install Script — Drop-In .claude/ Folder

**Decision:** There is no installation script. The `.claude/` folder is the product. Users copy it to their project root or `~/.claude/` for global authority.

**Rationale:** Installation scripts add complexity, platform dependencies, and failure modes. The Claude Code CLAUDE.md loading hierarchy (global `~/.claude/` → project `.claude/` → project root) provides the authority mechanism without scripting. Drop `~/.claude/` = global authority. Drop into project = project authority. The user controls scope through file placement.

---

## 8. Cowork Variants Are First-Class

**Decision:** Cowork single-file variants in `skills/cowork/` are maintained as complete, standalone documents — not degraded copies of the Claude Code versions.

**Rationale:** Source 47 (Ruben Hassid Cowork) confirmed Cowork's single-file constraint: no subdirectory structure, no multi-file skill packages. Cowork is a different runtime with different constraints, not a lesser version of Claude Code. The variants are adapted for Cowork's strengths (conversational flow, no persistent filesystem) rather than stripped-down approximations of the Claude Code versions.

---

## 9. Subagents Research, Parent Implements

**Decision:** Subagents (researcher, planner) produce findings and plans but never write code or edit files. The parent agent holds implementation context and acts on agent outputs.

**Rationale:** Sources 3 and 4 from the Agents MOC (Claude Code Sub-Agents notes) confirm this as the canonical pattern. Subagents have isolated context. If a subagent implements, the parent loses visibility into what was done. The parent must re-read files to understand state. This creates synchronization overhead and drift risk. Keeping subagents in researcher/planner roles maintains a single source of implementation truth in the parent session.

**Platform clarification:** This is a project convention, not a platform constraint. The official docs (sub-agents.md) confirm subagents *can* write files when tools permit. The `tools` allowlist on researcher and planner agents enforces this as a hard constraint, not just a behavioral instruction.

---

## 10. Max 5 Sequential Steps Without Checkpoint

**Decision:** No more than 5 sequential steps without a verification checkpoint.

**Rationale:** Source 61 (Long-Running Claude — Anthropic Research Blog) establishes compound reliability math: each step has error probability p. After n steps, reliability = (1-p)^n. At p=0.1 (10% error rate), 5 steps = 59% success, 10 steps = 35%. Checkpoint at step 5 resets the error accumulation. Source 65 (SkillsBench) sets empirical agent saturation at 4 agents — beyond this, coordination overhead exceeds task throughput. The 5-step rule applies to sequential chains; parallel steps do not compound in the same way.

---

## 11. CLAUDE.md Uses Directive Imperatives, Not Descriptions

**Decision:** Every rule in CLAUDE.md is written as an imperative instruction ("Write tests before implementation") not a description ("You are an assistant who writes tests first").

**Rationale:** Source 2 (claude-skillz) makes this explicit: system prompts are INSTRUCTIONS, not descriptions of Claude's identity. Descriptive language is interpreted as context that can be deprioritized. Imperative language is interpreted as a rule that must be followed. The difference matters most under context pressure — when the window is full, descriptions are dropped before instructions.

---

## 12. Every Skill Ends With a Mandatory Numbered Checklist

**Decision:** All core and workflow SKILL.md files end with a `## Mandatory Checklist` section containing numbered items starting with "Verify."

**Rationale:** Source 2 (claude-skillz) requires this pattern for all skills. Abstract principles are probabilistic — Claude applies them when it remembers to. A numbered checklist at the end of a skill is deterministic — it forces a systematic verification pass before the skill is considered complete. The "Verify" prefix makes each item action-oriented and unambiguous.

---

## 13. Read-Only Agents Use `tools` Allowlist + `permissionMode: dontAsk`

**Decision:** Read-only agents (`architect`, `code-reviewer`, `security-reviewer`, `verifier`, `mcp-agent`) use a `tools` allowlist in frontmatter combined with `permissionMode: dontAsk`.

**Rationale:** Source 3 (agent-teams.pdf — Anthropic Official) establishes tool-level permission enforcement. The updated implementation (informed by Official Anthropic Docs, sub-agents.md) uses two independent enforcement layers:

1. **`tools` allowlist** — only explicitly listed tools are available. Anything not in the list cannot be called.
2. **`permissionMode: dontAsk`** — if a tool call is attempted that isn't in the allowed set, it is auto-denied without prompting. This prevents edge cases where the allowlist alone might not catch something.

**Why `disallowedTools` was removed from agents that also have a `tools` allowlist:** When both fields are set, `disallowedTools` is redundant — the `tools` allowlist is already stricter. Using both creates false complexity. The correct pattern is: use `tools` for allowlisting, use `disallowedTools` only when you want to inherit most tools but remove a few specific ones.

---

## 14. Hooks Are Shell Scripts, Not Inline Strings

**Decision:** Hooks are dedicated `.sh` files in `.claude/hooks/` rather than escaped inline command strings in `settings.json`.

**Rationale:** Inline escaped strings in JSON are untestable, unreadable, and break easily on edge cases. Shell scripts in a dedicated directory can be linted with shellcheck (enforced in CI), reviewed like any other code, and tested independently. The CI `validate-hooks.yml` workflow runs shellcheck on every hook script on every push.

---

## 15. Separate settings.json and settings.global.json

**Decision:** Two settings files exist — `settings.json` for project-level placement (`.claude/hooks/` paths) and `settings.global.json` for global `~/.claude/` placement (`~/.claude/hooks/` paths).

**Rationale:** Hook paths are different depending on whether the configuration is placed at the project level or globally. Rather than requiring users to edit paths manually, providing both templates makes deployment unambiguous. Users copy the appropriate file and rename it to `settings.json`.

---

## 16. Agent Teams Architecture for Orchestrator

**Decision:** The `orchestrator` agent uses Claude Code's agent teams feature (lead + teammates) rather than sequential subagent spawning.

**Rationale:** Source 3 (agent-teams.pdf — Anthropic Official) defines the canonical agent teams architecture: a team lead coordinates teammates who communicate directly with each other and share a task list with file-locked claiming. Agent teams are the right pattern when tasks are genuinely parallel across independent domains. The 3-5 teammate limit and 5-6 tasks-per-teammate guidance comes directly from Anthropic's official documentation.

**Session-boundary clarification (Official Anthropic Docs, sub-agents.md):** Subagents work *within* a single session — they are isolated context windows inside the same conversation. Agent teams coordinate *across* separate Claude Code sessions. This is a fundamental distinction: use subagents for focused subtask delegation within a session; use agent teams when tasks require sustained parallelism or exceed what a single context window can hold.

**Invocation constraint:** The `Agent` tool (for spawning teammates) is only available when the orchestrator runs as the main thread via `claude --agent orchestrator`. Subagents cannot spawn other subagents. When invoked as a regular subagent, the orchestrator produces the mission plan and teammate spawn prompts but the parent session must execute the spawning.

---

## 17. ROE Skill as Authorization Gate for Security and Autonomous Operations

**Decision:** The `roe` skill is a mandatory pre-execution gate for any security operation, autonomous scan, or action that touches systems outside the local codebase. It enforces five elements: authorization reference, scope in, scope out, time window, and escalation contact. Verdict is PROCEED or HOLD — no conditionals.

**Rationale:** Scanning systems without authorization is illegal in most jurisdictions regardless of intent. The ROE gate makes authorization explicit before execution begins rather than implied or assumed. This mirrors standard red team engagement protocols (Source 79 — RedAmon) where written ROE is a prerequisite for any testing activity. Encoding this as a skill rather than a prompt instruction makes it invokable, auditable, and reproducible across sessions.

**Why five elements specifically:** Each element closes a specific failure mode — authorization (legality), scope in (prevents under-scoping), scope out (prevents production impact), time window (prevents stale authorization), escalation (prevents silent incidents). A gate with fewer elements has known gaps.

---

## 18. Intent Router Before Execution on Ambiguous Requests

**Decision:** The `intent-router` skill classifies ambiguous requests into one of eight categories and names the first skill to invoke before any implementation begins. It is a Level 1 skill — lightweight, runs early.

**Rationale:** Claude's default behavior on ambiguous requests is to pick the most familiar interpretation and start executing. This produces wrong answers at the worst possible time — after work has begun. Intent classification costs one step; backtracking costs many. The routing table is designed so that security operations are always routed to `roe` first, regardless of how the request is framed.

**Why "first skill only" not the full pipeline:** Presenting the full pipeline before any work has started is premature — the pipeline changes based on what is discovered at each step. Routing to the first step and letting the pipeline emerge from the work produces more accurate paths than specifying the full sequence upfront.

---

## 19. docker-sandbox Agent Uses Native Platform Isolation Primitives

**Decision:** The `docker-sandbox` agent uses three independent isolation layers from the official Claude Code platform rather than a hand-rolled Docker-outside-agent approach: `isolation: worktree` (temporary git worktree), `permissionMode: dontAsk` (auto-deny anything not in the tools allowlist), and a `PreToolUse: Bash` hook that validates every shell command before execution.

**Rationale:** Official Anthropic Docs (sub-agents.md, 2026-03-25) introduced native frontmatter fields that provide filesystem isolation, permission enforcement, and command validation without requiring external orchestration. Three layers in combination:

1. `isolation: worktree` — the agent works on a temporary copy of the repo; host files are not directly modified; the worktree is auto-cleaned if no permanent changes are made
2. `permissionMode: dontAsk` — any tool call outside the explicit `tools` allowlist is auto-denied without prompting, closing the gap between allowlist declaration and runtime enforcement
3. `validate-scan-command.sh` PreToolUse hook — validates every Bash command against a denylist of destructive operations, git write operations, and data exfiltration patterns; exits with code 2 to block

**The `roe` skill is preloaded via the `skills` frontmatter field** — ROE authorization content is injected into the agent's context at startup, not left as a prompt instruction the agent might skip. This enforces the authorization gate from within the agent's own context.

---

*This document is a publish artifact. It documents why the system is built as it is, using research that any reviewer can verify.*
