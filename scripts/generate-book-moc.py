#!/usr/bin/env python3
"""
generate-book-moc.py -- Generate lightweight Obsidian MOC notes for books and papers.

For each PDF/EPUB source under --library-root:
  - Extracts table of contents (no AI, no tokens)
  - Writes a structured Obsidian note with frontmatter, Summary placeholder, TOC
  - Stores the library-relative path so Claude can locate the source on demand

Full book content is NOT stored in Obsidian. When a summary is needed, Claude reads
the source file and uses obsidian_patch to fill in the Summary section permanently.

Output goes to:
  <vault-root>/02. AI-Vault/Library/Books/   -- books
  <vault-root>/02. AI-Vault/Library/Papers/  -- papers (category name contains "paper")

Usage:
    python generate-book-moc.py --library-root /path/to/books --vault-root /path/to/vault
    python generate-book-moc.py --library-root ... --vault-root ... --dry-run
    python generate-book-moc.py --library-root ... --vault-root ... --category Cybersec
    python generate-book-moc.py --library-root ... --vault-root ... --file path/to/book.pdf
    python generate-book-moc.py --library-root ... --vault-root ... --output-root /path/to/md
"""

import argparse
import re
import subprocess
import sys
import zipfile
import xml.etree.ElementTree as ET
from datetime import date
from pathlib import Path

TODAY = date.today().isoformat()

# ---------------------------------------------------------------------------
# Filename parsing
# ---------------------------------------------------------------------------

def parse_filename(stem):
    """Extract (title, author) from a filename stem."""
    name = stem.replace("_", " ")
    parts = name.split(" - ", 1)
    if len(parts) == 2:
        return parts[0].strip(), parts[1].strip()
    return parts[0].strip(), ""

# ---------------------------------------------------------------------------
# Library-relative path
# ---------------------------------------------------------------------------

def library_relative_path(file_path, library_root):
    """Return path relative to library_root using forward slashes."""
    try:
        rel = file_path.relative_to(library_root)
        return str(rel).replace("\\", "/")
    except ValueError:
        return str(file_path).replace("\\", "/")

# ---------------------------------------------------------------------------
# TOC extraction -- PDF
# ---------------------------------------------------------------------------

def extract_pdf_toc(path):
    """Extract table of contents from a PDF using pymupdf."""
    import fitz
    entries = []
    try:
        doc = fitz.open(str(path))
        toc = doc.get_toc(simple=False)
        for item in toc:
            level = item[0]
            title = item[1].strip()
            page  = item[2]
            if title:
                entries.append({"level": level, "title": title, "page": page})
        doc.close()
    except Exception as exc:
        print(f"  TOC extraction failed for {path.name}: {exc}", file=sys.stderr)
    return entries


def extract_pdf_metadata(path):
    """Extract author/title metadata embedded in the PDF."""
    import fitz
    meta = {}
    try:
        doc = fitz.open(str(path))
        raw = doc.metadata or {}
        if raw.get("title"):
            meta["title"] = raw["title"].strip()
        if raw.get("author"):
            meta["author"] = raw["author"].strip()
        meta["pages"] = doc.page_count
        doc.close()
    except Exception:
        pass
    return meta

# ---------------------------------------------------------------------------
# TOC extraction -- EPUB
# ---------------------------------------------------------------------------

_NOISE_EXTENSIONS   = re.compile(r'\.(c|h|s|asm|py|sh|rb|rs|go|java|js|ts|cpp|cs|pl|txt)\s*$', re.IGNORECASE)
_NOISE_PREFIXES     = re.compile(r'^(from |added to |excerpt from |new |on |code from |man page)', re.IGNORECASE)
_NOISE_EXACT        = re.compile(r'^(colophon|index|about the author|about the cover|copyright|dedication|endorsements?)$', re.IGNORECASE)
_NOISE_PREPROCESSOR = re.compile(r'^(define|include|ifdef|ifndef|endif|if\s|else\s|error\s|pragma|undef)\b', re.IGNORECASE)


def _is_noise(title):
    t = re.sub(r'\{[^}]*\}', '', title).strip()
    if _NOISE_EXTENSIONS.search(t):
        return True
    if _NOISE_PREFIXES.match(t):
        return True
    if _NOISE_EXACT.match(t):
        return True
    if _NOISE_PREPROCESSOR.match(t):
        return True
    return False


def _clean_epub_toc(entries, max_depth=2, doc_title=""):
    cleaned = []
    seen_at_level = {}
    title_words = set(doc_title.lower().split()) if doc_title else set()

    for entry in entries:
        level = entry["level"]
        title = entry["title"]
        title_lower = title.lower()

        if level > max_depth:
            continue
        if _is_noise(title):
            continue
        if title_words and len(title_words) > 2:
            entry_words = set(title_lower.split())
            overlap = len(title_words & entry_words) / len(title_words)
            if overlap > 0.7:
                continue
        if seen_at_level.get(level) == title_lower:
            continue

        seen_at_level[level] = title_lower
        cleaned.append(entry)

    return cleaned


def extract_epub_toc(path):
    """Extract TOC from an EPUB file (reads toc.ncx or nav.xhtml)."""
    entries = []
    try:
        with zipfile.ZipFile(str(path), "r") as zf:
            names = zf.namelist()
            nav_file = next((n for n in names if n.endswith("nav.xhtml") or n.endswith("nav.html")), None)
            ncx_file = next((n for n in names if n.endswith("toc.ncx")), None)

            if nav_file:
                entries = _parse_epub3_nav(zf.read(nav_file))
            elif ncx_file:
                entries = _parse_epub2_ncx(zf.read(ncx_file))
    except Exception as exc:
        print(f"  EPUB TOC extraction failed for {path.name}: {exc}", file=sys.stderr)
    return entries


def _parse_epub3_nav(data):
    entries = []
    try:
        root = ET.fromstring(data)
        for nav in root.iter("{http://www.w3.org/1999/xhtml}nav"):
            epub_type = nav.get("{http://www.idpf.org/2007/ops}type", "")
            if "toc" not in epub_type:
                continue
            entries = _extract_nav_items(nav, level=1)
            break
        if not entries:
            for a in root.iter("{http://www.w3.org/1999/xhtml}a"):
                text = "".join(a.itertext()).strip()
                if text:
                    entries.append({"level": 1, "title": text, "page": None})
    except Exception:
        pass
    return entries


def _extract_nav_items(nav_elem, level):
    entries = []
    for ol in nav_elem.iter("{http://www.w3.org/1999/xhtml}ol"):
        for li in ol:
            a = li.find("{http://www.w3.org/1999/xhtml}a")
            if a is not None:
                text = "".join(a.itertext()).strip()
                if text:
                    entries.append({"level": level, "title": text, "page": None})
            nested_ol = li.find("{http://www.w3.org/1999/xhtml}ol")
            if nested_ol is not None:
                entries.extend(_extract_nav_items(nested_ol, level + 1))
        break
    return entries


def _parse_epub2_ncx(data):
    entries = []
    try:
        root = ET.fromstring(data)
        ns = "http://www.daisy.org/z3986/2005/ncx/"
        for nav_point in root.iter(f"{{{ns}}}navPoint"):
            label = nav_point.find(f"{{{ns}}}navLabel/{{{ns}}}text")
            if label is not None and label.text:
                entries.append({"level": 1, "title": label.text.strip(), "page": None})
    except Exception:
        pass
    return entries


def extract_epub_metadata(path):
    """Extract author/title from EPUB OPF metadata."""
    meta = {}
    try:
        with zipfile.ZipFile(str(path), "r") as zf:
            names = zf.namelist()
            opf_file = next((n for n in names if n.endswith(".opf")), None)
            if not opf_file:
                return meta
            data = zf.read(opf_file)
            root = ET.fromstring(data)
            ns_dc = "http://purl.org/dc/elements/1.1/"
            title_el  = root.find(f".//{{{ns_dc}}}title")
            author_el = root.find(f".//{{{ns_dc}}}creator")
            if title_el is not None and title_el.text:
                meta["title"] = title_el.text.strip()
            if author_el is not None and author_el.text:
                meta["author"] = author_el.text.strip()
    except Exception:
        pass
    return meta

# ---------------------------------------------------------------------------
# TOC extraction -- from converted Markdown (preferred when available)
# ---------------------------------------------------------------------------

def extract_md_toc(md_path, max_depth=3, doc_title=""):
    """Extract TOC from a converted Markdown file by reading heading lines."""
    _anchor    = re.compile(r'\[\]\{#[^}]*\}')
    _class     = re.compile(r'\{[^}]*\}')
    _bare_link = re.compile(r'\[([^\]]*)\](?!\()')

    title_words = set(doc_title.lower().split()) if doc_title else set()

    entries = []
    seen = set()
    try:
        text = md_path.read_text(encoding="utf-8", errors="ignore")
        for line in text.splitlines():
            m = re.match(r'^(#{1,6})\s+(.+)', line)
            if not m:
                continue
            level = len(m.group(1))
            title = _anchor.sub("", m.group(2))
            title = _class.sub("", title)
            title = _bare_link.sub(r"\1", title).strip()
            if not title:
                continue
            if level > max_depth:
                continue
            if _is_noise(title):
                continue
            if title_words and len(title_words) > 2:
                entry_words = set(title.lower().split())
                overlap = len(title_words & entry_words) / len(title_words)
                if overlap > 0.7:
                    continue
            key = (level, title.lower())
            if key in seen:
                continue
            seen.add(key)
            entries.append({"level": level, "title": title, "page": None})
    except Exception as exc:
        print(f"  MD TOC extraction failed for {md_path.name}: {exc}", file=sys.stderr)
    return entries

# ---------------------------------------------------------------------------
# Find converted MD on output-root (used for EPUB TOC preference)
# ---------------------------------------------------------------------------

def find_converted_md(src, output_root):
    """Return the converted .md path in output_root for this source, if it exists."""
    if not output_root:
        return None
    safe_stem = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", src.stem)
    for md in output_root.rglob(f"{safe_stem}.md"):
        return md
    return None

# ---------------------------------------------------------------------------
# Note rendering
# ---------------------------------------------------------------------------

def render_toc(entries):
    if not entries:
        return "_TOC not available in this file._\n"
    lines = []
    for entry in entries:
        indent = "  " * (entry["level"] - 1)
        title  = entry["title"]
        page   = entry.get("page")
        if page and page > 0:
            lines.append(f"{indent}- {title} (p.{page})")
        else:
            lines.append(f"{indent}- {title}")
    return "\n".join(lines) + "\n"


def _escape_yaml(value):
    return value.replace('"', '\\"')


def render_note(title, author, category, file_type, lib_path, pages, toc):
    tag = re.sub(r"[^a-z0-9-]", "", category.lower().replace(" ", "-"))
    lines = ["---", f'title: "{_escape_yaml(title)}"']
    if author:
        lines.append(f'author: "{_escape_yaml(author)}"')
    lines += [
        f'category: "{category}"',
        f'file_type: "{file_type}"',
        f'library_path: "{lib_path}"',
    ]
    if pages:
        lines.append(f'pages: {pages}')
    lines += [
        f'imported: "{TODAY}"',
        f"tags: [library, {tag}]",
        "---",
        "",
        f"# {title}",
        "",
    ]
    if author:
        lines.append(f"**Author:** {author}  ")
    lines += [
        f"**Type:** {file_type.upper()}  ",
        f"**Library path:** `{lib_path}`  ",
        "",
        "---",
        "",
        "## Summary",
        "",
        "<!-- Not yet generated. Ask Claude to summarize this book during a session. -->",
        "<!-- Claude will use obsidian_patch to fill this in permanently. -->",
        "",
        "---",
        "",
        "## Table of Contents",
        "",
        render_toc(toc),
    ]
    return "\n".join(lines)

# ---------------------------------------------------------------------------
# Output path
# ---------------------------------------------------------------------------

def output_path(src, category, books_out, papers_out):
    safe_stem = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", src.stem)
    cat_lower = category.lower()
    if "paper" in cat_lower:
        return papers_out / f"{safe_stem}.md"
    return books_out / f"{safe_stem}.md"

# ---------------------------------------------------------------------------
# Source discovery (mirrors convert-to-md.py)
# ---------------------------------------------------------------------------

def discover_sources(library_root, category_filter=None):
    sources = []

    if category_filter is None or category_filter == "General":
        try:
            epub_stems = {
                f.stem for f in library_root.iterdir()
                if f.is_file() and f.suffix.lower() == ".epub"
            }
            for f in sorted(library_root.iterdir()):
                if not f.is_file():
                    continue
                suffix = f.suffix.lower()
                if suffix not in (".pdf", ".epub"):
                    continue
                if suffix == ".pdf" and f.stem in epub_stems:
                    continue
                sources.append((f, "General"))
        except PermissionError as exc:
            print(f"WARNING: cannot read {library_root}: {exc}", file=sys.stderr)

    try:
        subdirs = sorted(d for d in library_root.iterdir() if d.is_dir())
    except PermissionError as exc:
        print(f"WARNING: cannot list {library_root}: {exc}", file=sys.stderr)
        return sources

    for subdir in subdirs:
        category = subdir.name
        if category_filter and category != category_filter:
            continue
        try:
            files = list(subdir.iterdir())
        except PermissionError:
            print(f"WARNING: cannot read {subdir}", file=sys.stderr)
            continue
        epub_stems = {
            f.stem for f in files
            if f.is_file() and f.suffix.lower() == ".epub"
        }
        for f in sorted(files):
            if not f.is_file():
                continue
            suffix = f.suffix.lower()
            if suffix not in (".pdf", ".epub"):
                continue
            if suffix == ".pdf" and f.stem in epub_stems:
                continue
            sources.append((f, category))

    return sources

# ---------------------------------------------------------------------------
# Process a single file
# ---------------------------------------------------------------------------

def process_file(src, category, library_root, books_out, papers_out, output_root=None):
    """Generate MOC note for one file. Returns True on success."""
    dst = output_path(src, category, books_out, papers_out)
    if dst.exists():
        return False

    suffix = src.suffix.lower()

    if suffix == ".pdf":
        meta = extract_pdf_metadata(src)
        toc  = extract_pdf_toc(src)
    else:
        meta = extract_epub_metadata(src)
        fn_title, _ = parse_filename(src.stem)
        doc_title = meta.get("title") or fn_title
        converted_md = find_converted_md(src, output_root)
        if converted_md:
            toc = extract_md_toc(converted_md, doc_title=doc_title)
        else:
            raw_toc = extract_epub_toc(src)
            toc = _clean_epub_toc(raw_toc, doc_title=doc_title)

    fn_title, fn_author = parse_filename(src.stem)
    title  = meta.get("title")  or fn_title
    author = meta.get("author") or fn_author
    pages  = meta.get("pages")

    lib_path = library_relative_path(src, library_root)

    note = render_note(title, author, category, suffix.lstrip("."), lib_path, pages, toc)

    try:
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(note, encoding="utf-8")
        return True
    except Exception as exc:
        print(f"  ERROR writing {dst.name}: {exc}", file=sys.stderr)
        return False

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def run(library_root, vault_root, output_root=None, dry_run=False, category_filter=None, single_file=None):
    try:
        import fitz  # noqa: F401
    except ImportError:
        print("Missing dependency: pip install pymupdf4llm")
        sys.exit(1)

    books_out  = vault_root / "02. AI-Vault" / "Library" / "Books"
    papers_out = vault_root / "02. AI-Vault" / "Library" / "Papers"

    print(f"Library root : {library_root}")
    print(f"Vault root   : {vault_root}")
    print(f"Books out    : {books_out}")
    print(f"Papers out   : {papers_out}")

    if single_file:
        category = "General"
        try:
            for subdir in library_root.iterdir():
                if subdir.is_dir() and single_file.parent.resolve() == subdir.resolve():
                    category = subdir.name
                    break
        except PermissionError:
            pass
        if dry_run:
            print(f"[CONVERT] {category}/{single_file.name}")
            return
        ok = process_file(single_file, category, library_root, books_out, papers_out, output_root)
        print("Done." if ok else "Skipped (already exists).")
        return

    sources = discover_sources(library_root, category_filter)

    if not sources:
        print("No PDF or EPUB files found under library root.")
        return

    if dry_run:
        for src, category in sources:
            dst = output_path(src, category, books_out, papers_out)
            status = "EXISTS  " if dst.exists() else "CONVERT "
            print(f"[{status}] {category}/{src.name}")
        print(f"\nTotal: {len(sources)} files")
        return

    try:
        from tqdm import tqdm
        wrap = lambda it, **kw: tqdm(it, **kw)
    except ImportError:
        def wrap(it, **kw):
            print(f"Processing {kw.get('total', '?')} files...")
            return it

    created = skipped = failed = 0

    for src, category in wrap(sources, desc="Generating MOCs", total=len(sources), unit="file"):
        dst = output_path(src, category, books_out, papers_out)
        if dst.exists():
            skipped += 1
            continue
        ok = process_file(src, category, library_root, books_out, papers_out, output_root)
        if ok:
            created += 1
        else:
            failed += 1

    print(f"\nDone.  Created: {created}  |  Skipped (exists): {skipped}  |  Failed: {failed}")

    if created > 0:
        moc_script = Path(__file__).parent / "generate-library-moc.py"
        if moc_script.exists():
            print("\nRegenerating Library MOC...")
            result = subprocess.run(
                [sys.executable, str(moc_script), "--vault-root", str(vault_root)],
            )
            if result.returncode != 0:
                print(
                    f"WARNING: Library MOC regeneration failed (exit {result.returncode}). "
                    "Run generate-library-moc.py --vault-root manually.",
                    file=sys.stderr,
                )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate lightweight Obsidian MOC notes for books and papers."
    )
    parser.add_argument(
        "--library-root", required=True, metavar="PATH",
        help="Root directory containing your book/paper subdirectories",
    )
    parser.add_argument(
        "--vault-root", required=True, metavar="PATH",
        help="Obsidian vault root directory (MOC notes go to 02. AI-Vault/Library/)",
    )
    parser.add_argument(
        "--output-root", metavar="PATH",
        help="Converted Markdown directory (from convert-to-md.py); used for EPUB TOC preference",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="List files without writing anything",
    )
    parser.add_argument(
        "--category", metavar="NAME",
        help="Process one category (subdir name), e.g. Cybersec",
    )
    parser.add_argument(
        "--file", metavar="PATH", type=Path,
        help="Process a single file",
    )
    args = parser.parse_args()

    library_root = Path(args.library_root).resolve()
    vault_root   = Path(args.vault_root).resolve()
    output_root  = Path(args.output_root).resolve() if args.output_root else None

    if not library_root.exists():
        print(f"ERROR: --library-root does not exist: {library_root}", file=sys.stderr)
        sys.exit(1)

    if not vault_root.exists():
        print(f"ERROR: --vault-root does not exist: {vault_root}", file=sys.stderr)
        sys.exit(1)

    run(
        library_root=library_root,
        vault_root=vault_root,
        output_root=output_root,
        dry_run=args.dry_run,
        category_filter=args.category,
        single_file=args.file,
    )
