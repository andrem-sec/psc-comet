#!/usr/bin/env python3
"""
generate-book-moc.py -- Generate lightweight Obsidian MOC notes for books and papers.

For each PDF/EPUB source:
  - Extracts table of contents (no AI, no tokens, fully automatic)
  - Writes a structured Obsidian note with frontmatter, empty Summary
    placeholder, TOC, and key topics
  - Stores the USB-relative path so Claude can read the source on demand

Full book content is NOT stored in Obsidian -- the USB is the source of truth.
When a summary is needed, Claude reads the source file and uses obsidian_patch
to fill in the Summary section permanently.

USB auto-detection:
  Windows: finds the drive with volume label "USB"
  Linux:   checks /media/$USER/USB and /run/media/$USER/USB

Dependencies:
    pip install pymupdf4llm  (pymupdf is included)

Usage:
    python generate-book-moc.py --vault-root /path/to/vault
    python generate-book-moc.py --vault-root /path/to/vault --dry-run
    python generate-book-moc.py --vault-root /path/to/vault --category "Books/Cybersec"
    python generate-book-moc.py --vault-root /path/to/vault --file path/to/book.pdf
    python generate-book-moc.py --vault-root /path/to/vault --usb-root "E:/"

Configure SOURCE_DIRS below for your own book/paper directory structure.
"""

import argparse
import os
import platform
import re
import subprocess
import sys
import zipfile
import xml.etree.ElementTree as ET
from datetime import date
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Configure SOURCE_DIRS for your own directory structure.
# Keys are category names (used in frontmatter and output paths).
# Values are absolute paths to the directories containing your PDF/EPUB files.
# Example:
#   "Books/Cybersec": Path("/media/user/USB/Library/Cybersec"),
#   "Papers": Path.home() / "Downloads/papers",
SOURCE_DIRS: dict[str, Path] = {}

# Optional: a root directory scanned for loose files not covered by SOURCE_DIRS.
# Files here are assigned to the "Uncategorized" category.
EXTRA_ROOT: Path | None = None

# USB volume label to detect
USB_LABEL = "USB"

# Paths within the USB that source files live under (for relative path calculation)
# The script walks up from the source file until it hits the USB root.
USB_INTERNAL_ROOT = "Book Library"

TODAY = date.today().isoformat()

# ---------------------------------------------------------------------------
# USB root detection
# ---------------------------------------------------------------------------

def find_usb_root(label: str = USB_LABEL) -> Path | None:
    """Find the USB drive root by volume label."""
    system = platform.system()

    if system == "Windows":
        try:
            result = subprocess.run(
                ["powershell", "-Command",
                 f"(Get-Volume -FileSystemLabel '{label}' -ErrorAction SilentlyContinue).DriveLetter"],
                capture_output=True, text=True, timeout=5,
            )
            letter = result.stdout.strip()
            if letter:
                return Path(f"{letter}:/")
        except Exception:
            pass
        # Fallback: check all drives
        for letter in "DEFGHIJKLMNOPQRSTUVWXYZ":
            drive = Path(f"{letter}:/")
            if drive.exists():
                try:
                    result = subprocess.run(
                        ["powershell", "-Command",
                         f"(Get-Volume -DriveLetter {letter} -ErrorAction SilentlyContinue).FileSystemLabel"],
                        capture_output=True, text=True, timeout=3,
                    )
                    if result.stdout.strip().upper() == label.upper():
                        return drive
                except Exception:
                    continue

    elif system == "Linux":
        username = os.environ.get("USER", os.environ.get("USERNAME", ""))
        candidates = [
            Path(f"/media/{username}/{label}"),
            Path(f"/run/media/{username}/{label}"),
            Path(f"/mnt/{label}"),
        ]
        for c in candidates:
            if c.exists():
                return c

    return None


def usb_relative_path(file_path: Path, usb_root: Path | None) -> str:
    """Return path relative to USB root, using forward slashes.

    Tries three strategies in order:
      1. Relative to detected USB root (e.g. D:\\)
      2. Relative to the USB_INTERNAL_ROOT anchor folder (e.g. 'Book Library')
         -- handles the case where source files live at a Desktop alias path
      3. Absolute path as fallback

    Stored path is always relative so it works cross-platform when
    prepended with the correct USB mount point.
    """
    if usb_root:
        try:
            rel = file_path.relative_to(usb_root)
            return str(rel).replace("\\", "/")
        except ValueError:
            pass

    # Strategy 2: find the USB_INTERNAL_ROOT anchor in the path
    parts = file_path.parts
    for i, part in enumerate(parts):
        if part == USB_INTERNAL_ROOT:
            rel = "/".join(parts[i:])
            return rel

    # Fallback: absolute path
    return str(file_path).replace("\\", "/")

# ---------------------------------------------------------------------------
# Filename parsing
# ---------------------------------------------------------------------------

def parse_filename(stem: str) -> tuple[str, str]:
    """Extract (title, author) from a filename stem."""
    name = stem.replace("_", " ")
    parts = name.split(" - ", 1)
    if len(parts) == 2:
        return parts[0].strip(), parts[1].strip()
    return parts[0].strip(), ""

# ---------------------------------------------------------------------------
# TOC extraction -- PDF
# ---------------------------------------------------------------------------

def extract_pdf_toc(path: Path) -> list[dict]:
    """Extract table of contents from a PDF using pymupdf."""
    import fitz  # pymupdf
    entries = []
    try:
        doc = fitz.open(str(path))
        toc = doc.get_toc(simple=False)
        # toc entries: [level, title, page, ...]
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


def extract_pdf_metadata(path: Path) -> dict:
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

# Patterns that indicate a nav entry is a code listing or citation, not a heading
_NOISE_EXTENSIONS  = re.compile(r'\.(c|h|s|asm|py|sh|rb|rs|go|java|js|ts|cpp|cs|pl|txt)\s*$', re.IGNORECASE)
_NOISE_PREFIXES    = re.compile(r'^(from |added to |excerpt from |new |on |code from |man page)', re.IGNORECASE)
_NOISE_EXACT       = re.compile(r'^(colophon|index|about the author|about the cover|copyright|dedication|endorsements?)$', re.IGNORECASE)
_NOISE_PREPROCESSOR = re.compile(r'^(define|include|ifdef|ifndef|endif|if\s|else\s|error\s|pragma|undef)\b', re.IGNORECASE)

def _is_noise(title: str) -> bool:
    """Return True if a TOC entry is a code listing, citation, or boilerplate."""
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


def _clean_epub_toc(entries: list[dict], max_depth: int = 2, doc_title: str = "") -> list[dict]:
    """Filter noise, cap depth, and deduplicate consecutive identical titles."""
    cleaned = []
    seen_at_level: dict[int, str] = {}
    title_words = set(doc_title.lower().split()) if doc_title else set()

    for entry in entries:
        level = entry["level"]
        title = entry["title"]
        title_lower = title.lower()

        if level > max_depth:
            continue
        if _is_noise(title):
            continue
        # Skip entries that are just the document's own title (cover/title page nav items)
        if title_words and len(title_words) > 2:
            entry_words = set(title_lower.split())
            overlap = len(title_words & entry_words) / len(title_words)
            if overlap > 0.7:
                continue
        # Deduplicate: skip if same title appeared consecutively at same level
        if seen_at_level.get(level) == title_lower:
            continue

        seen_at_level[level] = title_lower
        cleaned.append(entry)

    return cleaned


def extract_epub_toc(path: Path) -> list[dict]:
    """Extract TOC from an EPUB file (reads toc.ncx or nav.xhtml)."""
    entries = []
    try:
        with zipfile.ZipFile(str(path), "r") as zf:
            names = zf.namelist()

            # Prefer nav.xhtml (EPUB3) over toc.ncx (EPUB2)
            nav_file = next((n for n in names if n.endswith("nav.xhtml") or n.endswith("nav.html")), None)
            ncx_file = next((n for n in names if n.endswith("toc.ncx")), None)

            if nav_file:
                entries = _parse_epub3_nav(zf.read(nav_file))
            elif ncx_file:
                entries = _parse_epub2_ncx(zf.read(ncx_file))
    except Exception as exc:
        print(f"  EPUB TOC extraction failed for {path.name}: {exc}", file=sys.stderr)
    return entries  # caller applies _clean_epub_toc with title context


def _parse_epub3_nav(data: bytes) -> list[dict]:
    entries = []
    try:
        root = ET.fromstring(data)
        ns = {"html": "http://www.w3.org/1999/xhtml",
              "epub": "http://www.idpf.org/2007/ops"}
        # Find the toc nav element
        for nav in root.iter("{http://www.w3.org/1999/xhtml}nav"):
            epub_type = nav.get("{http://www.idpf.org/2007/ops}type", "")
            if "toc" not in epub_type:
                continue
            entries = _extract_nav_items(nav, level=1)
            break
        if not entries:
            # Fallback: grab all li > a elements
            for a in root.iter("{http://www.w3.org/1999/xhtml}a"):
                text = "".join(a.itertext()).strip()
                if text:
                    entries.append({"level": 1, "title": text, "page": None})
    except Exception:
        pass
    return entries


def _extract_nav_items(nav_elem, level: int) -> list[dict]:
    entries = []
    for ol in nav_elem.iter("{http://www.w3.org/1999/xhtml}ol"):
        for li in ol:
            a = li.find("{http://www.w3.org/1999/xhtml}a")
            if a is not None:
                text = "".join(a.itertext()).strip()
                if text:
                    entries.append({"level": level, "title": text, "page": None})
            # Recurse into nested ol
            nested_ol = li.find("{http://www.w3.org/1999/xhtml}ol")
            if nested_ol is not None:
                entries.extend(_extract_nav_items(nested_ol, level + 1))
        break  # only top-level ol
    return entries


def _parse_epub2_ncx(data: bytes) -> list[dict]:
    entries = []
    try:
        root = ET.fromstring(data)
        ns = "http://www.daisy.org/z3986/2005/ncx/"
        for nav_point in root.iter(f"{{{ns}}}navPoint"):
            label = nav_point.find(f"{{{ns}}}navLabel/{{{ns}}}text")
            if label is not None and label.text:
                # Determine depth by counting ancestor navPoints
                level = 1
                entries.append({"level": level, "title": label.text.strip(), "page": None})
    except Exception:
        pass
    return entries


def extract_epub_metadata(path: Path) -> dict:
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
            title_el = root.find(f".//{{{ns_dc}}}title")
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

def extract_md_toc(md_path: Path, max_depth: int = 3, doc_title: str = "") -> list[dict]:
    """Extract TOC from a converted Markdown file by reading heading lines.

    Preferred over EPUB nav when the .md file exists on USB, because pandoc
    produces clean chapter/section headings without code listing noise.
    Strips pandoc artifacts: []{#anchor} fragments, {.classname} annotations,
    and bare [Name] link remnants (used by pandoc for author/editor metadata).
    """
    _anchor    = re.compile(r'\[\]\{#[^}]*\}')          # []{#id}
    _class     = re.compile(r'\{[^}]*\}')                # {.title} {.author}
    _bare_link = re.compile(r'\[([^\]]*)\](?!\()')       # [text] not followed by (url)

    title_words = set(doc_title.lower().split()) if doc_title else set()

    entries = []
    seen: set[str] = set()
    try:
        text = md_path.read_text(encoding="utf-8", errors="ignore")
        for line in text.splitlines():
            m = re.match(r'^(#{1,6})\s+(.+)', line)
            if not m:
                continue
            level = len(m.group(1))
            title = _anchor.sub("", m.group(2))
            title = _class.sub("", title)
            title = _bare_link.sub(r"\1", title).strip()  # keep text, drop brackets
            if not title:
                continue
            if level > max_depth:
                continue
            if _is_noise(title):
                continue
            # Skip entries that closely match the document title (cover/title page)
            if title_words and len(title_words) > 2:
                entry_words = set(title.lower().split())
                overlap = len(title_words & entry_words) / len(title_words)
                if overlap > 0.7:
                    continue
            # Deduplicate consecutive identical titles at same level
            key = (level, title.lower())
            if key in seen:
                continue
            seen.add(key)
            entries.append({"level": level, "title": title, "page": None})
    except Exception as exc:
        print(f"  MD TOC extraction failed for {md_path.name}: {exc}", file=sys.stderr)
    return entries

# ---------------------------------------------------------------------------
# Note rendering
# ---------------------------------------------------------------------------

def render_toc(entries: list[dict], file_type: str) -> str:
    """Render TOC entries as Markdown list."""
    if not entries:
        return "_TOC not available in this file._\n"

    lines = []
    for entry in entries:
        indent = "  " * (entry["level"] - 1)
        title = entry["title"]
        page = entry.get("page")
        if page and page > 0:
            lines.append(f"{indent}- {title} (p.{page})")
        else:
            lines.append(f"{indent}- {title}")

    return "\n".join(lines) + "\n"


def _escape_yaml(value: str) -> str:
    return value.replace('"', '\\"')


def render_note(
    title: str,
    author: str,
    category: str,
    file_type: str,
    usb_path: str,
    pages: int | None,
    toc: list[dict],
) -> str:
    tag = category.split("/")[-1].lower().replace(" ", "-")
    lines = ["---", f'title: "{_escape_yaml(title)}"']
    if author:
        lines.append(f'author: "{_escape_yaml(author)}"')
    lines += [
        f'category: "{category}"',
        f'file_type: "{file_type}"',
        f'usb_path: "{usb_path}"',
    ]
    if pages:
        lines.append(f'pages: {pages}')
    lines += [
        f'imported: "{TODAY}"',
        f"tags: [library, {tag}]",
        "cross_refs: []",
        'summary_status: "pending"',
        "---",
        "",
        f"# {title}",
        "",
    ]
    if author:
        lines.append(f"**Author:** {author}  ")
    lines += [
        f"**Type:** {file_type.upper()}  ",
        f"**USB path:** `{usb_path}`  ",
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
        render_toc(toc, file_type),
    ]
    return "\n".join(lines)

# ---------------------------------------------------------------------------
# Log append
# ---------------------------------------------------------------------------

def append_to_log(vault_root: Path | None, title: str, category: str) -> None:
    """Append a creation entry to <vault_root>/02. AI-Vault/Library/log.md."""
    if vault_root is None:
        return
    log_dir = vault_root / "02. AI-Vault" / "Library"
    log_path = log_dir / "log.md"
    try:
        log_dir.mkdir(parents=True, exist_ok=True)
        entry = f"[{date.today().isoformat()}] Created [[{title}]] ({category})\n"
        if not log_path.exists():
            log_path.write_text(f"# Library Log\n\n{entry}", encoding="utf-8")
        else:
            with log_path.open("a", encoding="utf-8") as f:
                f.write(entry)
    except Exception as exc:
        print(f"  WARNING: could not write to log.md: {exc}", file=sys.stderr)

# ---------------------------------------------------------------------------
# Output path
# ---------------------------------------------------------------------------

def output_path(src: Path, category: str, books_out: Path, papers_out: Path) -> Path:
    safe_stem = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", src.stem)
    if category == "Papers":
        return papers_out / f"{safe_stem}.md"
    return books_out / f"{safe_stem}.md"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _find_md_on_usb(src: Path, usb_root: Path | None) -> Path | None:
    """Return the converted .md path on USB for this source, if it exists."""
    if not usb_root:
        return None
    safe_stem = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", src.stem)
    # Mirror the structure used by convert-to-md.py
    # Books go to USB:/Markdown/Books/<SubCategory>/stem.md
    # Papers go to USB:/Markdown/Papers/stem.md
    # Try both possible locations
    candidates = [
        usb_root / "Markdown" / "Papers" / f"{safe_stem}.md",
    ]
    # For books, subcategory is unknown here, so scan Books subdirs
    books_root = usb_root / "Markdown" / "Books"
    if books_root.exists():
        for sub in books_root.iterdir():
            candidates.append(sub / f"{safe_stem}.md")
    for c in candidates:
        if c.exists():
            return c
    return None

# ---------------------------------------------------------------------------
# Process a single file
# ---------------------------------------------------------------------------

def process_file(src: Path, category: str, usb_root: Path | None, books_out: Path, papers_out: Path) -> bool:
    """Generate MOC note for one file. Returns True on success."""
    dst = output_path(src, category, books_out, papers_out)
    if dst.exists():
        return False  # already done

    suffix = src.suffix.lower()

    # Metadata
    if suffix == ".pdf":
        meta = extract_pdf_metadata(src)
        toc  = extract_pdf_toc(src)
    else:
        meta = extract_epub_metadata(src)
        # Prefer TOC from converted .md on USB (clean headers) over EPUB nav
        fn_title, _ = parse_filename(src.stem)
        doc_title = meta.get("title") or fn_title
        raw_toc = extract_epub_toc(src)
        toc = _clean_epub_toc(raw_toc, doc_title=doc_title)

    # Title and author: embedded metadata > filename > stem
    fn_title, fn_author = parse_filename(src.stem)
    title  = meta.get("title")  or fn_title
    author = meta.get("author") or fn_author
    pages  = meta.get("pages")

    # USB-relative path
    if usb_root:
        usb_path = usb_relative_path(src, usb_root)
    else:
        usb_path = str(src).replace("\\", "/")

    note = render_note(title, author, category, suffix.lstrip("."), usb_path, pages, toc)

    try:
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(note, encoding="utf-8")
        return True
    except Exception as exc:
        print(f"  ERROR writing {dst.name}: {exc}", file=sys.stderr)
        return False

# ---------------------------------------------------------------------------
# Source collection
# ---------------------------------------------------------------------------

def collect_sources(
    category_filter: str | None = None,
) -> list[tuple[Path, str]]:
    sources: list[tuple[Path, str]] = []

    # Loose files at extra root (files not covered by SOURCE_DIRS)
    if EXTRA_ROOT is not None and EXTRA_ROOT.exists() and (category_filter is None or category_filter == "Books/Uncategorized"):
        epub_stems = {f.stem for f in EXTRA_ROOT.iterdir() if f.suffix.lower() == ".epub"}
        for f in sorted(EXTRA_ROOT.iterdir()):
            if not f.is_file():
                continue
            suffix = f.suffix.lower()
            if suffix not in (".pdf", ".epub"):
                continue
            if suffix == ".pdf" and f.stem in epub_stems:
                continue
            sources.append((f, "Books/Uncategorized"))

    for category, directory in SOURCE_DIRS.items():
        if category_filter and category != category_filter:
            continue
        if not directory.exists():
            print(f"WARNING: directory not found -- {directory}", file=sys.stderr)
            continue

        files = list(directory.iterdir())
        epub_stems = {f.stem for f in files if f.suffix.lower() == ".epub"}

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
# Main
# ---------------------------------------------------------------------------

def run(
    dry_run: bool = False,
    category_filter: str | None = None,
    single_file: Path | None = None,
    usb_root_override: str | None = None,
    vault_root: str | None = None,
) -> None:
    try:
        import fitz  # noqa: F401
    except ImportError:
        print("Missing dependency: pip install pymupdf4llm")
        sys.exit(1)

    # Resolve vault output directories
    if vault_root:
        library_root = Path(vault_root) / "02. AI-Vault" / "Library"
    else:
        print("ERROR: --vault-root is required. Provide your Obsidian vault path.")
        sys.exit(1)
    books_out  = library_root / "Books"
    papers_out = library_root / "Papers"

    # Resolve USB root
    if usb_root_override:
        usb_root = Path(usb_root_override)
    else:
        usb_root = find_usb_root(USB_LABEL)
        if usb_root:
            print(f"USB detected at: {usb_root}")
        else:
            print("WARNING: USB drive not found. Paths will be stored as absolute.")
            print(f"  Plug in USB labelled '{USB_LABEL}' or use --usb-root to override.")

    # Single file mode
    if single_file:
        category = "Books/Uncategorized"
        for cat, directory in SOURCE_DIRS.items():
            if directory.exists() and single_file.parent.resolve() == directory.resolve():
                category = cat
                break
        if dry_run:
            print(f"[CONVERT] {category}/{single_file.name}")
            return
        ok = process_file(single_file, category, usb_root, books_out, papers_out)
        if ok:
            append_to_log(Path(vault_root), single_file.stem, category)
        print("Done." if ok else "Skipped (already exists).")
        return

    # Batch mode
    sources = collect_sources(category_filter)

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
        ok = process_file(src, category, usb_root, books_out, papers_out)
        if ok:
            created += 1
            append_to_log(Path(vault_root), src.stem, category)
        else:
            failed += 1

    print(f"\nDone.  Created: {created}  |  Skipped (exists): {skipped}  |  Failed: {failed}")

    # Regenerate the library index MOC
    if created > 0:
        moc_script = Path(__file__).parent / "generate-library-moc.py"
        if moc_script.exists():
            print("\nRegenerating Library MOC...")
            subprocess.run([sys.executable, str(moc_script)],
                          check=False, env={**__import__("os").environ,
                                            "VAULT_ROOT": str(vault_root)})


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate lightweight Obsidian MOC notes for books and papers."
    )
    parser.add_argument("--dry-run", action="store_true",
                        help="List files without writing anything")
    parser.add_argument("--category", metavar="NAME",
                        help='Process one category, e.g. "Books/Cybersec"')
    parser.add_argument("--file", metavar="PATH", type=Path,
                        help="Process a single file")
    parser.add_argument("--vault-root", metavar="PATH", required=True,
                        help="Path to your Obsidian vault root")
    parser.add_argument("--usb-root", metavar="PATH",
                        help='Override USB root path, e.g. "E:/" or "/media/user/USB"')
    args = parser.parse_args()

    run(
        dry_run=args.dry_run,
        category_filter=args.category,
        single_file=args.file,
        usb_root_override=args.usb_root,
        vault_root=args.vault_root,
    )
