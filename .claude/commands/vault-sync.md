---
name: vault-sync
description: Sync Obsidian vault with GitHub remote and USB backup, enforce zone access rules
---

Invoke the vault-sync procedure now. This command has two phases -- run Phase 1 immediately, run Phase 2 after vault work is complete.

## Phase 1 -- Pull (run now, before vault work)

1. Run `bash scripts/vault-sync.sh pull` from the PSC project root. Report the full output.
   - If output contains "CONFLICT": surface the conflict details to the user. Stop. Do not proceed with vault work until the user resolves it manually.
   - If output contains "WARNING: Could not reach remote": note that sync is offline, continue with local state.
   - If USB not mounted: note it, continue.

2. Report sync summary: commits pulled, USB sync status.

3. Confirm active zone rules for this session:
   - `01. Personal/` -- you may read freely. Writing requires explicit user instruction in this session.
   - `02. AI-Vault/` -- read and write freely. This is your knowledge base.

## Phase 2 -- Push (run after vault work is complete)

4. Run `bash scripts/vault-sync.sh push` from the PSC project root. Report the full output.
   - If output contains "No changes to commit": report it and finish.
   - If output contains "ERROR": surface the exact error to the user. Do not retry beyond what the script already attempted.

5. Report push summary: files committed, push result, USB sync result.

## Zone enforcement

Before writing to any path under `01. Personal/`, stop and ask the user for explicit authorization. State the exact file you intend to write and why. Do not proceed until confirmed.

Writes to `02. AI-Vault/` never require confirmation.

## Vault path configuration

The vault root is read from `~/.claude/psc-vault-path` (seeded by `install.sh`).
USB backup path is read from `~/.claude/psc-usb-path` (optional, set manually).

To configure:
```bash
echo "/path/to/your/obsidian/vault" > ~/.claude/psc-vault-path
echo "/path/to/usb/vault"           > ~/.claude/psc-usb-path   # optional
```
