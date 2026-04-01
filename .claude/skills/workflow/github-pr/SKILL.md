---
name: github-pr
description: Open or update a GitHub PR — reads the actual template at runtime, auto-detects create vs update mode, reconstructs body section-by-section
version: 0.1.0
level: 1
triggers:
  - "open a PR"
  - "create a pull request"
  - "update the PR"
  - "submit for review"
  - "github-pr"
  - "/github-pr"
context_files: []
steps:
  - name: Mode Detection
    description: Check for existing open PR on current branch; default to Update if found, Open otherwise
  - name: Read Template
    description: Read .github/pull_request_template.md and parse section headers before doing anything else
  - name: Open: Gather Context
    description: Run branch, commits not in base, diff stat, and push status in parallel
  - name: Open: Draft and Submit
    description: Pre-fill template, present for review, push branch if needed, create PR via gh CLI
  - name: Update: Identify and Show
    description: Auto-detect PR from branch, verify authorship, show current state
  - name: Update: Apply Changes
    description: Parse body by sections, modify only requested sections, reconstruct full body, submit
---

# GitHub PR Skill

A pull request creation and update protocol that reads the project's actual PR template at runtime, auto-detects whether to open or update, and for updates modifies only the requested sections without touching the rest. The template is always the source of truth.

## What Claude Gets Wrong Without This Skill

Without a protocol, PR bodies are written from memory: sections are guessed, some are skipped, and the title format is inconsistent. On updates, the entire body is replaced instead of surgically editing one section, which clobbers concurrent edits.

The auto-detect mode fix is equally important: when a PR already exists, the user usually wants to update it, not open a second one. Defaulting to Open when a PR exists is the wrong default.

## Mode Detection

Check for an open PR on the current branch:
```bash
gh pr view --json number,title,state 2>/dev/null
```

If an open PR exists and the user did not say "open a new PR" or "create a new PR": use **Update** mode.
Otherwise: use **Open** mode.

Read `.github/pull_request_template.md` before doing anything else in either mode. Parse its `## ` section headers, required fields, and field markers. Never assume or hardcode section names.

---

## Open Mode: Create a New PR

### Step 1: Gather Context

Run in parallel:

```bash
git branch --show-current
git log origin/HEAD..HEAD --oneline
git diff origin/HEAD...HEAD --stat
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

Review changed files and commit messages to understand the nature of the change.

### Step 2: Pre-Fill the Template

Draft a complete PR body using the parsed template structure:
- Fill every section from commits, diff, and changed files
- For Yes/No fields, infer from the diff when possible
- For required sections, always provide a substantive answer (not a placeholder)
- Draft a conventional commit-style title: `feat(scope): description` or `fix(scope): description`

### Step 3: Present Draft for Review

```
## PR Draft: <title>
Branch: <head> -> <base>
Labels: <suggested>

<full body>
```

Ask: "Review this draft: let me know what to change, or say 'submit' to open it." Iterate until approved.

### Step 4: Push and Create

If the branch is not yet pushed:
```bash
git push -u origin <branch>
```

Create the PR:
```bash
gh pr create --title "<title>" --base <base> --body "$(cat <<'PR_BODY_EOF'
<full body>
PR_BODY_EOF
)"
```

Add agreed labels:
```bash
gh pr edit <number> --add-label "<label1>,<label2>"
```

Return the PR URL.

---

## Update Mode: Edit an Existing PR

### Step 1: Identify and Verify

Auto-detect from current branch:
```bash
gh pr view --json number,title,body,labels,state,author,url,headRefName 2>/dev/null
```

Verify the current user is the PR author:
```bash
gh api user --jq '.login'
```

If not the author: stop and inform the user. Do not edit a PR you did not open.

### Step 2: Show Current State

```
## PR #<number>: <title>
State: <open/closed/merged>
Branch: <head> -> <base>
Labels: <labels>
Checks: <pass/fail/pending>
URL: <url>
```

### Step 3: Apply Updates

Supported operations:

| Operation | Command |
|-----------|---------|
| Edit title | `gh pr edit <n> --title "<title>"` |
| Add labels | `gh pr edit <n> --add-label "<label>"` |
| Remove labels | `gh pr edit <n> --remove-label "<label>"` |
| Add comment | `gh pr comment <n> --body "<text>"` |
| Edit a section | Parse body by `## ` headers, modify target section only, reconstruct full body |
| Sync after new commits | Re-analyze diff, propose stale section updates, confirm before applying |

For any body edit: always fetch the latest body before editing to avoid overwriting concurrent changes. Parse by `## ` headers, modify only the requested section, reconstruct the full body:

```bash
gh pr edit <number> --body "$(cat <<'PR_BODY_EOF'
<full updated body>
PR_BODY_EOF
)"
```

### Step 4: Confirm

```bash
gh pr view <number> --json number,title,labels,url
```

Return the PR URL.

---

## Anti-Patterns

Do not hardcode section names. Read the template file every time: it is the source of truth, not memory.

Do not replace the entire PR body to edit one section. Parse by headers, change the section, reconstruct. Everything else stays exactly as it was.

Do not edit a PR without verifying authorship. Editing someone else's PR body without their knowledge is a collaboration anti-pattern.

Do not use labels that do not exist in the repository. Run `gh label list` to verify.

Do not include sensitive data (tokens, keys, internal hostnames) in PR content.

## Mandatory Checklist

1. Verify mode (Open vs Update) was auto-detected from current branch state
2. Verify the PR template was read from .github/ before any section was drafted or edited
3. In Open mode: verify git context was gathered in parallel before drafting
4. In Open mode: verify the branch was pushed before gh pr create ran
5. In Update mode: verify authorship was confirmed before any edits were applied
6. In Update mode: verify only the requested sections were modified and the rest was preserved
7. Verify no sensitive data appears in the final PR body
8. Verify the PR URL was returned after creation or update
