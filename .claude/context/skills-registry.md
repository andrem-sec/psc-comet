# Skills Registry

Load this file on demand when selecting or invoking a skill. Do not load at session start.

| Skill | Level | Trigger |
|-------|-------|---------|
| heartbeat | 1 | session start |
| wrap-up | 1 | session end |
| lesson-gen | 1 | "extract pattern", "save this" |
| reflect | 2 | inline from wrap-up, "any patterns this session?" |
| remember | 1 | "remember this", `<remember>` |
| prd | 3 | new feature, before implementation |
| plan-first | 2 | 3+ files, cross-domain, security |
| tdd | 2 | writing new code |
| checkpoint | 1 | decision point, after 5 steps |
| code-review | 3 | "review this", pre-merge |
| doc-review | 2 | "/doc-review", "review this doc", "check for hallucinations", "hallucination check" |
| security-gate | 3 | pre-deploy, security changes |
| debug-session | 3 | "debug", stuck, unknown error |
| git-commit | 1 | committing non-trivial changes |
| model-router | 1 | complex task, cost-sensitive work |
| refactor | 2 | "refactor", "clean this up" |
| token-budget | 2 | "running out of context", long sessions |
| project-scan | 2 | "/scan", first-time setup, after major restructure |
| deep-interview | 3 | "/deep-interview", "before we spec", complex features |
| consensus-plan | 3 | "/consensus-plan", high-risk, architectural decisions |
| resume | 2 | "/resume", "pick up where we left off" |
| feature-pipeline | 3 | "/feature", new feature end-to-end |
| fix-pipeline | 2 | "/fix", "fix this bug" |
| roe | 3 | before security ops, scanning, autonomous operations |
| intent-router | 1 | ambiguous request, "where do I start", "what should I do" |
| investigate | 2 | "investigate", "root cause", systematic debugging |
| cso | 3 | security audit, "check for vulnerabilities", pre-deploy deep scan |
| retro | 2 | "retro", "how did the week go", end of sprint |
| benchmark | 2 | "benchmark", "is it fast enough", performance regression check |
| canary | 2 | "canary", post-deploy monitoring, "watch production" |
| office-hours | 3 | "validate my idea", "should I build this", before /prd on new products |
| github-issue | 1 | "open an issue", "file a bug", "request a feature" |
| github-pr | 1 | "open a PR", "create a pull request", "update the PR", "submit for review" |
| skill-stocktake | 3 | "/skill-stocktake", "audit skills", "skill health check" |
| strategic-compact | 2 | "compact now", "context getting full", "running out of space" |
| agentic-engineering | 3 | "decompose this task", "break down the work", "agent workflow" |
| deep-research | 3 | "/research", "research this topic", "investigate [topic]" |
| codebase-onboarding | 3 | "onboard to codebase", "understand this project", "getting started" |
| safety-guard | 2 | "enable safety guard", "careful mode", "freeze writes" |
| skill-comply | 3 | "measure compliance", "does claude follow this skill", "test skill effectiveness" |
| agent-harness-construction | 3 | "design an agent", "agent quality framework", "harness construction" |
| context-budget | 2 | "audit context usage", "token budget", "optimize context" |
| continuous-learning-v2 | 3 | "/instinct-status", "/instinct-export", "/evolve", "learned patterns" |
| loop-operator | 2 | "/loop-start", "/loop-status", "autonomous loop" |
| loop | 2 | "/loop", "run every", "schedule this", "repeat every" |
| distill | 2 | "/distill", "distill memory", "consolidate memory", "update memory files" |
| simplify | 2 | "/simplify", "simplify this", "clean up the code", "review for quality" |
| public-mode | 1 | "/public-mode", "public mode", "working on a public repo", "clean output mode" |
| batch | 3 | "/batch", "parallel agents", "swarm this", "run in parallel" |
| brand-context | 1 | "brand context", "load brand", "/brand-context" |
| inspiration-brief | 2 | "inspiration brief", "design brief", "new landing page", "/inspiration-brief" |
| site-teardown | 2 | "site teardown", "clone this site", "analyze this website", "/site-teardown" |
| screenshot-loop | 2 | "screenshot loop", "visual review", "compare to reference", "/screenshot-loop" |
| component-spec | 2 | "component spec", "spec this component", "/component-spec" |
| ui-slop-guard | 2 | "slop check", "check for ai slop", "audit this UI", "/ui-slop-guard" |
| design-token-guard | 2 | "token guard", "check tokens", "enforce tokens", "/design-token-guard" |
| animation-safe | 2 | "animation audit", "check animations", "motion review", "/animation-safe" |
| responsive-design | 2 | "responsive check", "mobile review", "breakpoint audit", "/responsive-design" |
| reasoning-gates | 2 | "/reasoning-gates", "where should we think carefully", "identify branch points", "where could we go wrong" |
