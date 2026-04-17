#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Accept paths as positional args or prompt interactively.
# Usage: run-library-pipeline.sh [library-root] [vault-root] [output-root]
#
# output-root is optional; defaults to <library-root>/../Markdown

LIBRARY_ROOT="${1:-}"
VAULT_ROOT="${2:-}"
OUTPUT_ROOT="${3:-}"

if [ -z "$LIBRARY_ROOT" ] || [ -z "$VAULT_ROOT" ]; then
    if [ ! -t 0 ]; then
        echo "Non-interactive shell detected. Pass paths as arguments:"
        echo "  $0 <library-root> <vault-root> [output-root]"
        exit 1
    fi
    if [ -z "$LIBRARY_ROOT" ]; then
        read -rp "Library root path (folder containing your books/papers): " LIBRARY_ROOT
    fi
    if [ -z "$VAULT_ROOT" ]; then
        read -rp "Obsidian vault root path: " VAULT_ROOT
    fi
fi

# Strip trailing slashes so dirname resolves to the parent, not the directory itself
LIBRARY_ROOT="${LIBRARY_ROOT%/}"
VAULT_ROOT="${VAULT_ROOT%/}"

if [ -z "$OUTPUT_ROOT" ]; then
    OUTPUT_ROOT="$(dirname "$LIBRARY_ROOT")/Markdown"
fi

if [ ! -d "$LIBRARY_ROOT" ]; then
    echo "ERROR: library root does not exist: $LIBRARY_ROOT" >&2
    exit 1
fi

if [ ! -d "$VAULT_ROOT" ]; then
    echo "ERROR: vault root does not exist: $VAULT_ROOT" >&2
    exit 1
fi

echo "=== Library Pipeline ==="
echo "Library root : $LIBRARY_ROOT"
echo "Vault root   : $VAULT_ROOT"
echo "Output root  : $OUTPUT_ROOT"
echo ""

echo "Step 1: Converting PDF/EPUB to Markdown..."
python "$SCRIPT_DIR/convert-to-md.py" \
    --library-root "$LIBRARY_ROOT" \
    --output-root "$OUTPUT_ROOT"

echo ""
echo "Step 2: Generating Obsidian MOC notes..."
python "$SCRIPT_DIR/generate-book-moc.py" \
    --library-root "$LIBRARY_ROOT" \
    --vault-root "$VAULT_ROOT" \
    --output-root "$OUTPUT_ROOT"

echo ""
echo "Done."
