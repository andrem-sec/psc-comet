---
name: github-issue
description: File a structured GitHub issue — reads the actual template at runtime, auto-gathers context, enforces one concept per issue
---

Invoke the github-issue protocol now. Use `gh` CLI throughout.

## Step 1 — Detect type and read template

Ask the user: "Is this a bug report or a feature request?" (one question, wait for answer).

Read the corresponding template from `.github/ISSUE_TEMPLATE/`. If no template directory exists, check for a single `.github/ISSUE_TEMPLATE.md`. Parse it to extract:
- Section headers and field names (never assume — the template is the source of truth)
- Dropdown options and required fields
- Labels defined in the template frontmatter

## Step 2 — Gather context silently

Before prompting the user further, run these in parallel without announcing them:

```bash
git log -5 --oneline
git status --short
git branch --show-current
```

Use the results to pre-fill context-dependent fields (affected files, recent changes, current branch).

## Step 3 — Draft the issue

Using the template structure and gathered context, draft a complete issue body with every section filled. Present the full draft:

```
## Issue Draft: <title>
**Type**: bug | feature
**Labels**: <from template>

<full body with all sections filled>
```

Ask: "Review this draft — let me know what to change, or say 'submit' to file it."

Iterate until the user approves.

## Step 4 — Scope check

Before submitting, verify: does this issue cover exactly one concept? If it covers multiple independent problems or features, offer to split it:

"This covers [X] and [Y] — should I file them as separate issues?"

Only proceed if the user confirms single scope or explicitly chooses to keep them together.

## Step 5 — Submit

```bash
gh issue create --title "<title>" --body "$(cat <<'ISSUE_EOF'
<full body>
ISSUE_EOF
)" --label "<labels>"
```

Return the issue URL.

## Rules

- Always read the template file — never hardcode section names or field structures
- Redact any sensitive data (tokens, keys, personal info) before filing
- Use actual command output for environment context, not guesses
- One concept per issue — enforce this before submitting
