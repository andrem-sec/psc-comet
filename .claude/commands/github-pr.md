---
name: github-pr
description: Open or update a GitHub PR — reads the actual template at runtime, auto-detects create vs update mode, reconstructs body section-by-section
---

Invoke the github-pr protocol now. Use `gh` CLI throughout.

## Mode detection

If there is already an open PR for the current branch and the user did not say "open a new PR", default to **Update** mode. Otherwise use **Open** mode.

Read `.github/pull_request_template.md` before doing anything else. Parse its `## ` section headers, fields, and required markers. This is the source of truth — never assume or hardcode section names.

---

## Open mode — create a new PR

### Step 1 — Gather context

Run in parallel:

```bash
git branch --show-current
git log origin/HEAD..HEAD --oneline   # commits not yet in base
git diff origin/HEAD...HEAD --stat     # files changed
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null  # check if pushed
```

Review changed files and commit messages to understand the nature of the change.

### Step 2 — Pre-fill the template

Draft a complete PR body using the parsed template structure and gathered context:
- Fill every section based on commits, diff, and changed files
- For Yes/No fields, infer from the diff
- For required sections, always provide a substantive answer
- Draft a conventional commit-style title (e.g., `feat(auth): add token refresh`, `fix(api): handle timeout gracefully`)

### Step 3 — Present draft for review

```
## PR Draft: <title>
Branch: <head> -> <base>
Labels: <suggested>

<full body>
```

Ask: "Review this draft — let me know what to change, or say 'submit' to open it." Iterate until approved.

### Step 4 — Push and create

1. If the branch is not yet pushed:
```bash
git push -u origin <branch>
```

2. Create the PR:
```bash
gh pr create --title "<title>" --base <base> --body "$(cat <<'PR_BODY_EOF'
<full body>
PR_BODY_EOF
)"
```

3. Add agreed labels:
```bash
gh pr edit <number> --add-label "<label1>,<label2>"
```

Return the PR URL.

---

## Update mode — edit an existing PR

### Step 1 — Identify the PR

Auto-detect from current branch:
```bash
gh pr view --json number,title,body,labels,state,author,url,headRefName 2>/dev/null
```

Verify the current user is the PR author before proceeding:
```bash
gh api user --jq '.login'
```

If not the author, stop and inform the user.

### Step 2 — Show current state

```
## PR #<number>: <title>
State: <open/closed/merged>
Branch: <head> -> <base>
Labels: <labels>
Checks: <pass/fail/pending>
URL: <url>
```

### Step 3 — Apply updates

Supported operations:

| Operation | Command |
|---|---|
| Edit title | `gh pr edit <n> --title "<title>"` |
| Add labels | `gh pr edit <n> --add-label "<label>"` |
| Remove labels | `gh pr edit <n> --remove-label "<label>"` |
| Add comment | `gh pr comment <n> --body "<text>"` |
| Edit a section | Parse body by `## ` headers, modify target section only, reconstruct full body, resubmit |
| Sync after new commits | Re-analyze diff, propose stale section updates, confirm before applying |

For any body edit: parse the current body into sections by `## ` headers, modify only the requested section, reconstruct the full body, and submit. Never clobber unrelated sections.

Always fetch the latest body before editing to avoid overwriting concurrent changes.

For body edits:
```bash
gh pr edit <number> --body "$(cat <<'PR_BODY_EOF'
<full updated body>
PR_BODY_EOF
)"
```

### Step 4 — Confirm

```bash
gh pr view <number> --json number,title,labels,url
```

Return the PR URL.

---

## Rules

- Always read `.github/pull_request_template.md` before filling or editing — never assume section names
- For updates, only modify the requested sections — preserve everything else exactly
- Always show current vs proposed before applying body edits
- Only use labels that exist in the repository (`gh label list` if unsure)
- Never include sensitive data in PR content
