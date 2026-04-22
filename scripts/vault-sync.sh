#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/detect-platform.sh
source "$SCRIPT_DIR/detect-platform.sh"

# ── Path resolution ──────────────────────────────────────────────────────────
# Vault root is read from ~/.claude/psc-vault-path (set by install.sh).
# USB backup path is read from ~/.claude/psc-usb-path (optional).
# To configure: echo "/path/to/your/vault" > ~/.claude/psc-vault-path
#               echo "/path/to/usb/vault"  > ~/.claude/psc-usb-path

vault_root() {
    local cfg="${HOME}/.claude/psc-vault-path"
    if [ -f "$cfg" ]; then
        cat "$cfg"
    else
        echo ""
    fi
}

usb_path() {
    # Optional USB backup -- configure via ~/.claude/psc-usb-path
    local cfg="${HOME}/.claude/psc-usb-path"
    if [ -f "$cfg" ]; then
        local p; p=$(cat "$cfg")
        [ -d "$p" ] && echo "$p" || true
        return
    fi

    # Windows fallback: detect USB drive by volume label "USB"
    if [[ "$DETECTED_OS" == "windows" ]]; then
        local drive
        drive=$(cmd.exe /c "wmic logicaldisk where VolumeName='USB' get DeviceID 2>nul" 2>/dev/null \
                | grep -oE '[A-Z]:' | head -1 || true)
        if [ -n "$drive" ]; then
            local letter
            letter=$(echo "$drive" | tr '[:upper:]' '[:lower:]' | tr -d ':')
            local p="/${letter}/Obsidian"
            [ -d "$p" ] && echo "$p" || true
        fi
    fi
}

VAULT_ROOT="$(vault_root)"
USB_VAULT="$(usb_path || true)"

# ── Guards ───────────────────────────────────────────────────────────────────

if [ -z "$VAULT_ROOT" ]; then
    echo "ERROR: vault path not configured." >&2
    echo "  Run: echo '/path/to/your/obsidian/vault' > ~/.claude/psc-vault-path" >&2
    exit 1
fi

if [ ! -d "$VAULT_ROOT/.git" ]; then
    echo "ERROR: $VAULT_ROOT is not a git repository" >&2
    exit 1
fi

# ── Operations ───────────────────────────────────────────────────────────────

do_pull() {
    echo "Fetching from remote..."
    if ! git -C "$VAULT_ROOT" fetch origin 2>&1; then
        echo "WARNING: Could not reach remote. Working with local state only."
        return
    fi

    local behind
    behind=$(git -C "$VAULT_ROOT" log HEAD..origin/master --oneline 2>/dev/null | wc -l | tr -d ' ')

    if [ "$behind" -eq 0 ]; then
        echo "Already up to date."
        return
    fi

    echo "Applying $behind commit(s) from remote..."
    if ! git -C "$VAULT_ROOT" pull --rebase origin master 2>&1; then
        git -C "$VAULT_ROOT" rebase --abort 2>/dev/null || true
        echo "CONFLICT: rebase failed. Aborted. Resolve manually before proceeding." >&2
        exit 1
    fi
    echo "Pull complete. Applied $behind commit(s)."
}

do_push() {
    local changed
    changed=$(git -C "$VAULT_ROOT" status --porcelain)

    if [ -z "$changed" ]; then
        echo "No changes to commit."
        return
    fi

    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')

    git -C "$VAULT_ROOT" add -A
    git -C "$VAULT_ROOT" commit -m "vault backup: $ts"
    echo "Committed: vault backup $ts"

    echo "Pushing to remote..."
    if ! git -C "$VAULT_ROOT" push origin master 2>&1; then
        echo "Push rejected -- pulling and retrying..."
        if ! git -C "$VAULT_ROOT" pull --rebase origin master 2>&1; then
            git -C "$VAULT_ROOT" rebase --abort 2>/dev/null || true
            echo "ERROR: conflict during retry pull. Resolve manually." >&2
            exit 1
        fi
        if ! git -C "$VAULT_ROOT" push origin master 2>&1; then
            echo "ERROR: push failed after retry. Manual intervention required." >&2
            exit 1
        fi
    fi
    echo "Push complete."
}

do_usb_sync() {
    if [ -z "$USB_VAULT" ]; then
        echo "USB not mounted -- skipping."
        return
    fi
    echo "Syncing to USB ($USB_VAULT)..."
    rsync -a --delete "$VAULT_ROOT/" "$USB_VAULT/"
    echo "USB sync complete."
}

do_status() {
    echo "=== Vault status ==="
    echo "Root : $VAULT_ROOT"
    echo "USB  : ${USB_VAULT:-not mounted}"
    echo ""
    git -C "$VAULT_ROOT" fetch origin 2>/dev/null || true
    local ahead behind changed
    ahead=$(git -C "$VAULT_ROOT" log origin/master..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
    behind=$(git -C "$VAULT_ROOT" log HEAD..origin/master --oneline 2>/dev/null | wc -l | tr -d ' ')
    changed=$(git -C "$VAULT_ROOT" status --porcelain | wc -l | tr -d ' ')
    echo "Uncommitted changes : $changed file(s)"
    echo "Ahead of remote     : $ahead commit(s)"
    echo "Behind remote       : $behind commit(s)"
}

# ── Main ─────────────────────────────────────────────────────────────────────

MODE="${1:-pull}"

case "$MODE" in
    pull)   do_pull;   do_usb_sync ;;
    push)   do_push;   do_usb_sync ;;
    status) do_status ;;
    *)
        echo "Usage: vault-sync.sh [pull|push|status]" >&2
        exit 1
        ;;
esac
