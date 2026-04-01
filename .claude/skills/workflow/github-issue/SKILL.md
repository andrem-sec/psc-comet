---
name: github-issue
description: File a structured GitHub issue — reads the actual template at runtime, auto-gathers context, enforces one concept per issue
version: 0.1.0
level: 1
triggers:
  - "open an issue"
  - "file a bug"
  - "request a feature"
  - "github issue"
  - "/github-issue"
context_files: []
steps:
  - name: Detect Type and Read Template
    description: Ask bug or feature, then read the corresponding template from .github/ISSUE_TEMPLATE/ at runtime
  - name: Gather Context Silently
    description: Run git log, status, and branch in parallel before prompting further
  - name: Draft
    description: Fill every template section using gathered context, present for review, iterate
  - name: Scope Check
    description: Verify the issue covers exactly one concept before submitting
  - name: Submit
    description: gh issue create with title, body, and labels from the template
---

# GitHub Issue Skill

A structured GitHub issue filing protocol that reads the project's actual template at runtime, pre-fills context from git state, and enforces one concept per issue. The template is the source of truth: section names are never assumed or hardcoded.

## What Claude Gets Wrong Without This Skill

Without a protocol, issue drafts either skip sections from the template (because the section names were guessed wrong), include sensitive data that should be redacted, or bundle multiple problems into one issue because nobody enforced the scope check.

The other failure mode is manual context gathering: the user fills in branch, recent commits, and affected files manually, when all of that is available from git in seconds.

## Step 1: Detect Type and Read Template

Ask (one question, wait for the answer): "Is this a bug report or a feature request?"

Then read the corresponding template:
- Bug: `.github/ISSUE_TEMPLATE/bug_report.md` or `.github/ISSUE_TEMPLATE/bug.md`
- Feature: `.github/ISSUE_TEMPLATE/feature_request.md` or `.github/ISSUE_TEMPLATE/feature.md`
- Fallback: `.github/ISSUE_TEMPLATE.md` if no directory exists

Parse the template to extract:
- Section headers and field names (do not assume: the file is the source of truth)
- Dropdown options and required fields
- Labels defined in the frontmatter

## Step 2: Gather Context Silently

Before prompting the user further, run in parallel without announcing it:

```bash
git log -5 --oneline
git status --short
git branch --show-current
```

Use the output to pre-fill context-dependent fields: affected files, recent changes, current branch. Do not ask the user for information git already has.

## Step 3: Draft

Using the template structure and gathered context, produce a complete issue body with every section filled. Present it:

```
## Issue Draft: <title>
Type: bug | feature
Labels: <from template frontmatter>

<full body with all sections filled>
```

Ask: "Review this draft: let me know what to change, or say 'submit' to file it."

Iterate until the user approves.

## Step 4: Scope Check

Before submitting, verify: does this issue cover exactly one concept?

If it covers multiple independent problems or features, offer to split:
"This covers [X] and [Y]: should I file them as separate issues?"

Only proceed if the user confirms single scope or explicitly chooses to keep them together.

## Step 5: Submit

```bash
gh issue create --title "<title>" --body "$(cat <<'ISSUE_EOF'
<full body>
ISSUE_EOF
)" --label "<labels>"
```

Return the issue URL.

## Anti-Patterns

Do not hardcode section names. If the template has a "Steps to Reproduce" section, use that exact name. If it has "Reproduction Steps", use that. The template is not a suggestion.

Do not include sensitive data: tokens, API keys, personal information, internal hostnames, or production credentials must be redacted before filing.

Do not file a multi-concept issue without offering to split it. One issue, one thing.

Do not ask the user for context that git already provides.

## Mandatory Checklist

1. Verify the template file was read from .github/ before any section was drafted
2. Verify git context was gathered silently before additional prompts
3. Verify every section in the template was filled in the draft
4. Verify any sensitive data was redacted before submitting
5. Verify the scope check ran and confirmed a single concept
6. Verify the issue was filed via gh CLI and the URL was returned
