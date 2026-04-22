#!/usr/bin/env python3
"""
generate-library-moc.py -- Generate and update the Library MOC in Obsidian.

Scans all Markdown files under:
  <vault-root>/02. AI-Vault/Library/Books/
  <vault-root>/02. AI-Vault/Library/Papers/

Writes: <vault-root>/02. AI-Vault/Library/Library MOC.md

Run after each batch conversion to keep the MOC current.

Usage:
    python generate-library-moc.py --vault-root /path/to/vault
"""

import argparse
import re
import sys
from datetime import date
from pathlib import Path

TODAY = date.today().isoformat()

# ---------------------------------------------------------------------------
# Frontmatter parsing
# ---------------------------------------------------------------------------

def parse_frontmatter(text):
    meta = {}
    if not text.startswith("---"):
        return meta
    end = text.find("---", 3)
    if end == -1:
        return meta
    block = text[3:end].strip()
    for line in block.splitlines():
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        meta[key.strip()] = value.strip().strip('"')
    return meta


def derive_title(meta, stem):
    if meta.get("title"):
        return meta["title"]
    name = stem.replace("_", " ")
    parts = name.split(" - ", 1)
    return parts[0].strip()


def derive_author(meta, stem):
    if meta.get("author"):
        return meta["author"]
    name = stem.replace("_", " ")
    parts = name.split(" - ", 1)
    if len(parts) == 2:
        return parts[1].strip()
    return ""


def derive_category(meta, directory):
    if meta.get("category"):
        return meta["category"]
    if "Papers" in directory.parts:
        return "Papers"
    return "Books"

# ---------------------------------------------------------------------------
# Collection
# ---------------------------------------------------------------------------

def collect_notes(library_root):
    """Return notes grouped by category."""
    groups = {}

    books_dir  = library_root / "Books"
    papers_dir = library_root / "Papers"

    dirs_to_scan = []
    if books_dir.exists():
        dirs_to_scan.append(books_dir)
    if papers_dir.exists():
        dirs_to_scan.append(papers_dir)

    if not dirs_to_scan:
        print(
            f"Library directories not found under {library_root}.\n"
            "Run generate-book-moc.py first.",
            file=sys.stderr,
        )
        sys.exit(1)

    for directory in dirs_to_scan:
        for md_file in sorted(directory.glob("*.md")):
            try:
                text = md_file.read_text(encoding="utf-8")
            except Exception:
                continue

            meta     = parse_frontmatter(text)
            title    = derive_title(meta, md_file.stem)
            author   = derive_author(meta, md_file.stem)
            category = derive_category(meta, directory)

            rel = md_file.relative_to(library_root.parent)

            note = {
                "title":     title,
                "author":    author,
                "file_type": meta.get("file_type", "").upper(),
                "imported":  meta.get("imported", meta.get("date", "")),
                "link":      str(rel).replace("\\", "/"),
            }
            groups.setdefault(category, []).append(note)

    return groups

# ---------------------------------------------------------------------------
# MOC rendering
# ---------------------------------------------------------------------------

def render_moc(groups, vault_root):
    total = sum(len(v) for v in groups.values())
    lines = [
        "---",
        'title: "Library MOC"',
        'tags: [moc, library]',
        f'updated: "{TODAY}"',
        "---",
        "",
        "# Library MOC",
        "",
        f"{total} sources across {len(groups)} categories. Last updated: {TODAY}",
        "",
        f"> Re-generate: `python scripts/generate-library-moc.py --vault-root {vault_root}`",
        "",
        "---",
        "",
        "## Contents",
        "",
    ]

    for category in sorted(groups):
        anchor = re.sub(r"[^a-z0-9-]", "", category.lower().replace("/", "-").replace(" ", "-"))
        count = len(groups[category])
        lines.append(f"- [{category}](#{anchor}) ({count})")
    lines.append("")
    lines.append("---")
    lines.append("")

    for category in sorted(groups):
        notes = sorted(groups[category], key=lambda n: n["title"].lower())
        lines.append(f"## {category}")
        lines.append("")
        lines.append(f"{len(notes)} sources")
        lines.append("")

        for note in notes:
            entry = f"- [[{note['link']}|{note['title']}]]"
            if note["author"]:
                entry += f" -- {note['author']}"
            if note["file_type"]:
                entry += f" `{note['file_type']}`"
            lines.append(entry)

        lines.append("")

    return "\n".join(lines)

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def run(vault_root):
    library_root = vault_root / "02. AI-Vault" / "Library"
    moc_path     = library_root / "Library MOC.md"

    print(f"Vault root   : {vault_root}")
    print(f"Library root : {library_root}")
    print("Scanning library...")

    groups = collect_notes(library_root)

    if not groups:
        print("No notes found.")
        sys.exit(0)

    total = sum(len(v) for v in groups.values())
    print(f"Found {total} notes across {len(groups)} categories.")

    moc = render_moc(groups, vault_root)
    moc_path.parent.mkdir(parents=True, exist_ok=True)
    moc_path.write_text(moc, encoding="utf-8")
    print(f"MOC written  : {moc_path}")

    for category in sorted(groups):
        print(f"  {category}: {len(groups[category])}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate the Library MOC in Obsidian."
    )
    parser.add_argument(
        "--vault-root", required=True, metavar="PATH",
        help="Obsidian vault root directory",
    )
    args = parser.parse_args()

    vault_root = Path(args.vault_root).resolve()

    if not vault_root.exists():
        print(f"ERROR: --vault-root does not exist: {vault_root}", file=sys.stderr)
        sys.exit(1)

    run(vault_root)
