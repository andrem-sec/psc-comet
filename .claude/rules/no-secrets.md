---
paths:
  - "**/*.env"
  - "**/*.env.local"
  - "**/*.env.production"
  - "**/credentials.json"
  - "**/secrets.json"
  - "**/config/secrets*"
---

# No Secrets Rule

When working with files matching these paths:

- Never write or suggest hardcoded credentials, tokens, passwords, or API keys
- Replace any discovered secrets with environment variable references immediately
- If a secret is found in version control history, flag it for rotation — do not just delete the file
- Acceptable pattern: `process.env.SECRET_KEY` / `os.environ["SECRET_KEY"]` / `os.Getenv("SECRET_KEY")`
- Unacceptable: any literal string that looks like a key, token, password, or private credential
