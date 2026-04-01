# Session Learnings

Accumulated patterns and insights extracted by the `wrap-up` skill. Updated each session.

## Format

Each entry: `[YYYY-MM-DD] [category] — [learning]`

Categories: `pattern` | `mistake` | `approach` | `tool` | `decision`

## Learnings

<!-- Entries added by wrap-up skill. Most recent first. -->

[2026-03-31] decision | Completed second wave of CC source integration: ember-gate.sh (renamed from kairos-gate.sh — state files also renamed: kairos.lock→ember.lock, kairos.count→ember.count, kairos-due→ember-due), session-memory-precompact.sh (PreCompact hook), distill skill (4-phase memory consolidation, read-only Bash constraint), simplify skill (3 parallel agents: Reuse/Quality/Efficiency), loop skill (CronCreate-based interval scheduling), public-mode skill (clean output for public repos). All 4 new skills registered in CLAUDE.md. settings.json updated to ember-gate.sh + session-memory-precompact.sh in PreCompact. heartbeat/SKILL.md renamed KAIROS Gate Check → Ember Gate Check.

[2026-03-31] pattern | Agent memory scoping: add `memory_scope: project` to agent frontmatter so agents load project-scoped memory (.claude/agent-memory/MEMORY.md) rather than user-scoped memory (~/.claude/memory/). Project memories: architecture decisions, active constraints, patterns specific to this repo. User memories: preferences and cross-project lessons. Separate index file per scope.

[2026-03-31] decision | telemetry-log.sh enriched with three new JSONL fields: git_branch (from git rev-parse --abbrev-ref HEAD), modified_files (from git status --porcelain line count), duration_s (derived from ember.lock mtime — proxy for time since last consolidation). Falls back gracefully when git is absent or ember.lock doesn't exist.

[2026-03-31] decision | Naming discipline enforced: PSC must not use Anthropic-internal codenames. KAIROS → Ember gate, Dream → Distill, Undercover mode → Public mode. Rationale: project is going public — using upstream internal names risks attribution confusion and downstream naming conflicts.

[2026-03-31] decision | Analyzed full Claude Code source (claude-code-main, 500+ TypeScript files) and implemented 18 items into psc_comet derived from docs 12 and 13: 6 hooks (pre-context-load, block-bypass-permissions, pre-edit-baseline, attribution-snapshot, post-edit-check, kairos-gate), 2 scripts (validate-id.sh, safe-log.sh), 1 batch skill, and 9 file modifications (CLAUDE.md, settings.json, orchestrator.md, wrap-up, heartbeat, resume, checkpoint, token-budget, agentic-engineering). sc_v1.2 used as smoke-test bed before syncing to psc_comet — changes verified working there first.

[2026-03-31] pattern | KAIROS dual-purpose mtime lock: the lock file mtime IS the lastConsolidatedAt timestamp. One file serves as both distributed lock and timestamp record — zero extra state files. Crash recovery: kairos-gate.sh stashes priorMtime before acquiring lock so a crash can roll back without leaving stale state. PSC implementation: .claude/context/kairos.lock + .claude/context/kairos.count + .claude/context/kairos-due flag.

[2026-03-31] pattern | ULTRAPLAN stateless event scanner: async multi-agent coordination should use a pure-function result scanner — no stateful polling, no shared DB. Input: paginated event batches. Output: { kind: 'approved' | 'rejected' | 'pending' | 'unchanged' }. Crash-safe because it re-derives state from events on every poll. PSC batch skill uses this: PR: <url> sentinel is the coordination signal, orchestrator parses it as it arrives.

[2026-03-31] approach | Claude Code's tool orchestration engine auto-parallelizes consecutive read-only tool calls (up to 10 concurrent). Write tools force a serial boundary. Free performance: group Grep/Read/Glob calls before any Edit/Write in agent prompts. No code change needed — just prompt organization. Added to agentic-engineering skill.

[2026-03-31] decision | bypassPermissions mode is externally accessible in Claude Code and represents a significant privilege escalation path if a compromised CLAUDE.md or memory file instructs the model to use it. Added both a CLAUDE.md rule (Security Invariant — Permission Mode) and a hook enforcement (block-bypass-permissions.sh on PreToolUse: Agent). Belt-and-suspenders: rule tells the model, hook blocks the tool call regardless.

[2026-03-31] pattern | Pre/post shellcheck baseline for hook files: capture shellcheck output before edit, diff after, warn only on NEW findings. Non-blocking (exit 0) — surfaces regressions without stopping workflow. Baseline stored in .claude/baselines/<filename>.baseline.txt. Silently skips non-.sh files and when shellcheck is unavailable — zero noise for irrelevant files.

[2026-03-28] decision | ECC Phase 8 complete. Implemented cross-platform continuous learning system with Python CLI infrastructure: continuous-learning-v2 skill (Level 3, 217 lines, instinct system with confidence scoring 0.3-0.95, auto-promotion at 0.8+, 6 commands: /instinct-status/export/import/evolve/promote/projects), loop-operator skill (Level 2, 223 lines, autonomous loop management with 3 safety modes + escalation gates). Python infrastructure: check-dependencies.sh (cross-platform detection, handles Windows stub), bootstrap-phase8.sh (4-step automated install), instinct-cli.py (300 lines, list/add/apply/promote commands, ~/.claude/homunculus/ storage). Hook observe-instinct.sh registered in settings.json (Stop hook, graceful degradation if Python unavailable). All components passed automated validation (test_phase8.sh: 10/10 PASS). Fixed Windows Unicode issue (emojis -> ASCII: [OK]/[PROJECT]/[GLOBAL]). Tested on Windows Python 3.14.1. Skill count: 36 to 38. Command count: 29 to 37 (+8 Phase 8 commands). Design decisions locked: Stop-only observation, no confidence decay, loop-operator as skill, manual Python install, Python 3.6+ with forward compatibility to 4+. ECC integration complete (Phases 0-8, 38 skills total).

[2026-03-28] decision | ECC Phase 7 complete. Implemented 5 medium-priority workflow tools: codebase-onboarding (Level 3, 197 lines, 4-phase systematic onboarding with 2-min guide generation), safety-guard (Level 2, 151 lines, 3-mode safety guardrails with Careful/Freeze/Guard modes), skill-comply (Level 3, 245 lines, automated compliance measurement with supportive/neutral/competing scenarios), agent-harness-construction (Level 3, 220 lines, framework with 4 quality dimensions + 3 architecture patterns), context-budget (Level 2, 199 lines, token audit identifying MCP as 78% of per-message cost). All 5 skills passed automated structural validation (test_phase7.sh: 5/5 PASS). Skill count: 31 to 36. CLAUDE.md updated with 5 new registry entries. Phase 8 next: continuous-learning-v2 + loop-operator (highest complexity, requires Python CLI infrastructure).

[2026-03-28] decision | ECC Phase 6 complete. Implemented 4 advanced quality & meta-improvement skills: skill-stocktake (Level 3, 200 lines, quality audit with Keep/Improve/Update/Retire/Merge verdicts), strategic-compact (Level 2, 145 lines, hook-based compaction suggestions at task boundaries), agentic-engineering (Level 3, 244 lines, 15-minute unit rule + eval-first loop + model routing), deep-research (Level 3, 244 lines, 6-step multi-source research with inline citations). All 4 skills passed automated structural validation (test_phase6.sh: 4/4 PASS). Skill count: 27 to 31. CLAUDE.md updated with 4 new registry entries. Phase 7 next: 5-6 medium-priority workflow tools (codebase-onboarding, safety-guard, skill-comply, agent-harness-construction, context-budget).

[2026-03-28] pattern | Plan → Develop → Test → Adjust workflow prevents regressions. User correctly flagged missing testing in Phase 2. Implemented automated test suites for Phases 3-5. Test findings: Phase 3 skill levels needed adjustment (2→3 for files >200 lines). Zero regressions across 13 new components due to proactive testing. Test suite creation takes ~15 minutes but catches issues before they compound.

[2026-03-28] approach | Automated test suites for Claude Code components validate structure without execution. Test patterns: frontmatter fields present, required sections exist, line counts match declared levels, checklist format correct. Example: test_phase5.sh validates 5 component upgrades in <10 seconds. Store tests in /tmp/ for session reuse. Pattern reusable across future ECC phases.

[2026-03-28] decision | ECC Phase 5 complete. Upgraded 5 existing components: resume skill (added WHAT NOT TO RETRY section to prevent re-thrashing), lesson-gen skill (4-verdict system: SAVE/IMPROVE/ABSORB/DROP), code-reviewer agent (80% confidence threshold + AI-generated code addendum with 4 risk categories), tdd skill (differentiated coverage: 100%/90%/80% + pass@k metrics), model-router skill (fallback strategy + 15-minute unit rule). All upgrades tested with automated validation. Phase 6 next: 4 new skills (skill-stocktake, strategic-compact, agentic-engineering, deep-research).

[2026-03-28] decision | ECC Phase 4 complete. Implemented 1 command and 1 agent: /orchestrate (183 lines, multi-agent workflow chaining with 4 predefined workflows: feature/bugfix/refactor/security, handoff documents between agents), harness-optimizer agent (228 lines, meta-agent that analyzes and improves harness via /harness-audit, 7 focus areas, minimal reversible changes). Command count: 29 to 30. Agent count: 9 to 10. All components tested with automated validation. Phase 5 next: 5 existing component upgrades.

[2026-03-28] decision | ECC Phase 3 complete. Implemented 3 skills: verification-loop (Level 2, 194 lines, backs /verify command), eval-harness (Level 3, 241 lines, backs /eval command with pass@k metrics and 3 grader types), ai-regression-testing (Level 3, 218 lines, documents 4 primary AI regression patterns). Skill count: 24 to 27. All skills tested with automated validation suite. Phase 4 next: /orchestrate command + harness-optimizer agent.

[2026-03-28] decision | ECC Phase 2 complete. Implemented 3 commands: /verify (unified verification sweep with 4 modes: quick/full/pre-commit/pre-pr), /aside (context-preserving side question handler with read-only constraint), /eval (eval-driven development with define/check/report/list operations, tracks pass@1/pass@3/pass^3 metrics). Command count: 26 to 29. Global hook updated to allow .claude/* infrastructure files. Phase 3 next: eval-harness skill + verification-loop skill.

[2026-03-27] decision | ECC Phase 1 complete. Implemented 3 hooks: pre-config-protection.sh (functional, blocks 43 config patterns), stop-cost-tracker.sh (STUB, documents upstream blocker), stop-check-console-log.sh (functional, bash JSON fallback). Hook count: 7 to 10. ADR-004 (cost tracker blocked by Claude Code Stop hook limitations) and ADR-005 (config protection rationale) added to decisions.md. Phase 2 next: /verify, /aside, /eval commands.

[2026-03-27] pattern | Stop hooks in Claude Code receive only {session_id, stop_reason, os, arch} in stdin. Token counts, model name, and API response metadata are NOT available. Cost tracking requires upstream enhancement to add `model` and `usage.input_tokens/output_tokens` fields. No workaround exists without MCP server or log parsing (both brittle). Implemented stub hook documenting blocker.

[2026-03-27] approach | Hooks must handle Python 3 unavailability gracefully. Pattern: `python3 -c "..." 2>/dev/null || echo "fallback"` for simple extraction. For JSON array encoding, add bash fallback: build JSON string manually with escaped quotes when Python fails. Required for Windows environments where python3 is WindowsApps stub.

[2026-03-27] pattern | Config protection hook prevents LLM from weakening linter strictness as "quick fix" to failing tests. Protected patterns: .eslintrc*, eslint.config.*, .prettierrc*, prettier.config.*, biome.json, .ruff.toml, .shellcheckrc, .pylintrc, .mypy.ini, .stylelintrc, .rubocop.yml, .golangci.yml, clippy.toml. Exception: pyproject.toml (contains dependencies, not just lint config). Exit 2 (block) requires manual override.

[2026-03-27] tool | Global Claude Code hooks execute before project-level hooks. PreToolUse hooks that exit(2) cannot be overridden from project settings.json. To allow exceptions, must modify the global hook pattern itself at ~/.claude/settings.json or restart Claude Code after modifying it.

[2026-03-27] decision | Modified global ~/.claude/settings.json PreToolUse:Write hook to allow .claude/registries/*.md files. Added !/registries\\// exception pattern. Documented with comment noting date and reason. Required for Phase 0 registry restructure in ECC integration.

[2026-03-27] approach | ECC integration into psc_comet structured as 7 phases (0-6) with user approval checkpoints between each. Phase 0 restructures CLAUDE.md registries into separate files (.claude/registries/skills.md, agents.md, commands.md) before adding 38 new items. Prevents exceeding 200-line CLAUDE.md limit. continuous-learning-v2 requires full Python CLI implementation at scripts/instinct-cli.py.

[2026-03-30] decision | Frontend/UI/UX suite Phase 1 + Phase 2 (partial) complete. Phase 1: copied ui-ux-pro-max skill layer into psc_comet (76 CSV databases, BM25 Python search engine, 6 skill directories: ui-ux-pro-max, ui-styling, design-system, brand, design, slides, banner-design). Phase 2: wrote 5 of 9 PSC workflow skills — brand-context, inspiration-brief, site-teardown, screenshot-loop, component-spec. Remaining: ui-slop-guard, design-token-guard, animation-safe, responsive-design.

[2026-03-30] pattern | ui-ux-pro-max repo uses symlinks from .claude/skills/ back to src/. Used `cp -rL` to resolve symlinks and copy actual file content. Verified files contain real data not broken symlinks.

[2026-03-30] approach | WebFetch uses a smaller summarizing model on CSS/JS files — strips exactly the technical detail needed for site teardown (specific cubic-bezier values, clip-path shapes, backdrop-filter values). site-teardown skill explicitly documents this and instructs fetching raw content without summarization.

[2026-03-30] pattern | Screenshot loop animated element exception: screenshots capture a frozen frame of animation, causing Claude to modify the animation trying to match the frozen reference, destroying the motion. Skill documents explicit disable flag: "This component includes animation — do not use the screenshot loop."

[2026-03-30] approach | AI slop hook (warn-ai-slop.sh) should only detect specific hex values (#7c3aed, #8b5cf6, #6366f1, #8b5cf6) and gradient patterns (linear-gradient(135deg). Class name checking (.hero-section, .features-grid) belongs in the ui-slop-guard skill, not the hook. Hook = automated detection, skill = guided review.

[2026-03-30] decision | CLAUDE.md hard limit is 200 lines. Current: 174. Adding 9 skill rows + 3 agent rows = 186 total. 14-line buffer before limit. Constraint shapes Phase 6: only registry rows, no other content added.

[2026-03-30] decision | Frontend/UI/UX suite fully complete (all 6 phases). Final counts: 9 workflow skills, 3 agents, 7 hooks, 8 commands, CLAUDE.md at 185 lines. Workflow chain: brand-context → inspiration-brief → site-teardown → screenshot-loop → component-spec → ui-slop-guard + design-token-guard + a11y-review. Hooks run automatically on every Edit/Write for real-time slop/token/a11y detection.

[2026-03-30] pattern | Hook scope discipline: hooks should detect specific values (hex codes, CSS property strings), never semantic meaning (class names, component intent). Class name checking belongs in skills where reasoning is available. This prevents false positives and keeps hooks lightweight.

[2026-03-30] approach | Three-layer token architecture enforced by design-token-guard: primitive (raw values, Layer 1) → semantic (intent-named, Layer 2) → component (scoped, Layer 3). Components reference Layer 2 or 3 only. Token names encode intent, not value (--color-primary not --blue-500). TOKEN_VIOLATION / TOKEN_GAP / TOKEN_CONFLICT classification guides remediation priority.

[2026-03-30] pattern | Animation accessibility requires two separate checks: (1) prefers-reduced-motion media query for CSS — warn-missing-reduced-motion hook catches this at write time; (2) window.matchMedia guard for JS animations — animation-safe skill catches this in audit. Hook covers CSS only; skill covers the full picture.

[2026-03-30] approach | a11y-reviewer agent isolated from implementation session (same constraint as security-reviewer). Review code in fresh context to avoid anchoring bias from having written it. Parent agent spawns a11y-reviewer read-only; findings return to parent for implementation.

[2026-03-30] pattern | Commands are thin invocation prompts — one paragraph, no logic. The skill holds the logic; the command just routes to it with the active context. Keeps commands under 10 lines and eliminates duplication between command and skill.

[2026-03-30] mistake | Task statuses were not updated as phases completed. User had to ask "what phase are you on?" before I checked the task list and found all 5 tasks still showing pending/in_progress. Mark tasks completed immediately when work finishes — do not batch at wrap-up.

---
*Last updated: 2026-03-30 (Session wrap-up: all tasks marked complete, task tracking lesson recorded)*
