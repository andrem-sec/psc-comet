---
name: continuous-learning-v2
description: Cross-session instinct learning with confidence-based promotion and global scope
version: 0.1.0
level: 3
triggers:
  - "/instinct-status"
  - "/instinct-export"
  - "/instinct-import"
  - "/evolve"
  - "learned patterns"
  - "session observations"
context_files:
  - context/learnings.md
  - context/project.md
steps:
  - name: Load Instincts
    description: Read project instincts from ~/.claude/homunculus/
  - name: Filter by Domain/Confidence
    description: Apply filters if specified
  - name: Display or Modify
    description: List, add, apply, or promote instincts
  - name: Update Storage
    description: Persist changes to JSON with atomic writes
  - name: Evaluate for Promotion
    description: Check if confidence >= 0.8 for global promotion
  - name: Cluster into Skills
    description: Group related instincts for /evolve command
---

# Continuous Learning v2 Skill

Cross-session learning system that captures behavioral patterns as instincts with confidence scoring and automatic promotion to global scope.

## What Claude Gets Wrong Without This Skill

Without continuous learning, Claude:
1. Rewrites skills manually instead of learning from patterns
2. Forgets project-specific patterns between sessions
3. Cannot differentiate high-confidence vs low-confidence patterns
4. Applies one-size-fits-all rules instead of context-specific instincts
5. Has no path for local instincts to become global best practices

Continuous learning tracks what works, increases confidence with successful applications, and promotes proven patterns globally.

## The Instinct System

**Instinct:** Atomic behavioral unit with trigger (when), action (what), and confidence (0.0-1.0).

**Example:**
```json
{
  "id": "inst_001",
  "trigger": "writing test file",
  "action": "colocate test next to source (src/user.ts -> src/user.test.ts)",
  "confidence": 0.85,
  "domain": "testing",
  "evidence": ["2026-03-28: Created tests/user.test.ts next to src/user.ts"],
  "scope": "project",
  "apply_count": 12
}
```

**Key Fields:**
- `trigger`: Natural language condition for when to apply
- `action`: Specific, actionable instruction
- `confidence`: 0.3 (new) to 0.95 (max), increases +0.05 per application
- `domain`: Category (testing, security, architecture, style, etc.)
- `scope`: "project" or "global"
- `apply_count`: Successful application count

## Six Commands

### /instinct-status

**Purpose:** Display all instincts with filters.

**Usage:**
- `/instinct-status` - Show all
- `/instinct-status --domain testing` - Filter by domain
- `/instinct-status --confidence 0.7` - Minimum confidence

**Output:** Lists PROJECT and GLOBAL instincts with confidence, domain, apply count.

### /instinct-export

**Purpose:** Export instincts to JSON for sharing.

**Usage:**
- `/instinct-export` - Export to stdout
- `/instinct-export --output instincts.json` - Save to file

**Format:** Portable JSON with project metadata removed.

### /instinct-import

**Purpose:** Import instincts from teammates or other projects.

**Usage:**
- `/instinct-import instincts.json` - Merge imported instincts

**Conflict Resolution:** If ID exists, keep higher confidence version.

### /evolve

**Purpose:** Cluster related instincts into skill suggestions.

**Algorithm:**
1. Group by domain
2. Find instincts with shared trigger patterns (cosine similarity > 0.7)
3. Suggest skill structure with clustered actions

**Output:** Proposed SKILL.md structure for manual review.

### /promote

**Purpose:** Manually promote project instinct to global.

**Requirements:**
- Confidence >= 0.8
- Instinct scope = "project"

**Effect:** Moves instinct to global_instincts array, applies to all projects.

### /projects

**Purpose:** List all projects with learned instincts.

**Output:** Project names, remote URLs, instinct counts, last updated.

## Storage Architecture

**Location:** `~/.claude/homunculus/projects/<git-remote-hash>/instincts.json`

**Why git-remote-hash:** Unique per repository, consistent across local clones and team members.

**Fallback:** If no git remote, use directory path hash.

**Structure:**
```json
{
  "project": {
    "name": "psc_comet",
    "git_remote": "https://github.com/...",
    "remote_hash": "a3f5b9c2",
    "created": "2026-03-28T20:00:00Z"
  },
  "instincts": [...],          // project-scoped
  "global_instincts": [...]    // applies to all projects
}
```

**Atomic Writes:** Write to temp file, then rename to prevent corruption.

## Auto-Promotion

**Trigger:** Instinct applied in 2+ projects AND confidence >= 0.8.

**Process:**
1. Hook observes instinct applied in project A
2. Same instinct (by action similarity) applied in project B
3. System detects cross-project usage
4. Auto-promotes to global scope
5. Logs promotion to learnings.md

**Manual Override:** User can run `/promote inst_NNN` to force promotion.

## Observation Mechanism

**Hook:** observe-instinct.sh runs at session Stop (end).

**Current:** Logs that observation occurred (Phase 8.0.1 stub).

**Future Phases:**
- Parse tool call traces
- Identify repeated patterns (e.g., always running tests before commit)
- Auto-generate instinct suggestions
- Surface for user approval

**Frequency:** Stop-only (v0.1.0). Higher frequency optional later (trade-off: interruptions vs learning rate).

## Anti-Patterns

**Over-promoting:** Promoting instincts with confidence < 0.8. Premature globalization spreads unvalidated patterns.

**Ignoring low-confidence instincts:** Not reviewing instincts with confidence < 0.5. May indicate conflicting patterns or context-specific exceptions.

**No evidence review:** Accepting instinct suggestions without checking evidence field. Evidence shows when/where pattern was observed.

**Manual skill writing instead of /evolve:** Writing skills from scratch when instincts exist. /evolve generates skill scaffolds automatically.

**No confidence decay:** (Not implemented v0.1.0). Future: Confidence should decay if not applied for 30+ days (pattern no longer relevant).

**Exporting without review:** Sharing instincts.json without removing project-specific secrets or proprietary patterns.

## Implementation Notes

**Dependencies:** Python 3.6+, jsonschema (validation), watchdog (optional, Linux only).

**Bootstrap:** `bash scripts/bootstrap-phase8.sh` detects Python, installs deps, validates CLI.

**Graceful Degradation:** If Python unavailable, hook exits silently. Core psc_comet features unaffected.

**Cross-Platform:** Tested on Windows (Python 3.14.1) and Linux (Python 3.6+).

## Mandatory Checklist

1. Verify Python 3.6+ detected or bootstrap instructions provided
2. Verify instinct-cli.py implements list, add, apply, promote commands
3. Verify storage location at ~/.claude/homunculus/projects/<hash>/instincts.json
4. Verify confidence increases +0.05 per application, capped at 0.95
5. Verify promotion requires confidence >= 0.8
6. Verify observe-instinct.sh hook registered in settings.json Stop section
7. Verify graceful degradation when Python unavailable (hook exits cleanly)
8. Verify /instinct-status displays both project and global instincts
9. Verify git remote hash used for project identification (fallback to directory hash)
10. Verify atomic JSON writes prevent file corruption
