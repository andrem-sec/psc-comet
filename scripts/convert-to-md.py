#!/usr/bin/env python3
"""
convert-to-md.py -- Batch convert PDF/EPUB sources to Markdown.

Scans immediate subdirectories of --library-root as categories.
Files directly in --library-root go to the "General" category.
Writes converted Markdown to --output-root.

Dependencies:
    pip install pymupdf4llm tqdm watchdog
    pandoc: auto-installed on Windows/macOS; see prompt on Linux.

Usage:
    python convert-to-md.py --library-root /path/to/books --output-root /path/to/output
    python convert-to-md.py --library-root ... --output-root ... --dry-run
    python convert-to-md.py --library-root ... --output-root ... --category Cybersec
    python convert-to-md.py --library-root ... --output-root ... --watch
"""

import argparse
import platform
import re
import subprocess
import sys
import time
from datetime import date
from pathlib import Path

TODAY = date.today().isoformat()

# ---------------------------------------------------------------------------
# Pandoc detection
# ---------------------------------------------------------------------------

def _find_pandoc():
    import shutil
    found = shutil.which("pandoc")
    if found:
        return found
    candidates = [
        Path(r"C:\Program Files\Pandoc\pandoc.exe"),
        Path(r"C:\Program Files (x86)\Pandoc\pandoc.exe"),
        Path.home() / "AppData" / "Local" / "Pandoc" / "pandoc.exe",
    ]
    for c in candidates:
        if c.exists():
            return str(c)
    try:
        result = subprocess.run(["pandoc", "--version"], capture_output=True, timeout=5)
        if result.returncode == 0:
            return "pandoc"
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return None


PANDOC = _find_pandoc()

# ---------------------------------------------------------------------------
# Pandoc auto-install
# ---------------------------------------------------------------------------

def _install_pandoc():
    system = platform.system()
    if system == "Windows":
        print("Installing pandoc via winget...")
        result = subprocess.run(
            ["winget", "install", "JohnMacFarlane.Pandoc",
             "--accept-package-agreements", "--accept-source-agreements"],
        )
        return result.returncode == 0
    elif system == "Linux":
        print("pandoc not found. Install it with:")
        print("  sudo apt-get install -y pandoc")
        print("Then re-run this script.")
        return False
    elif system == "Darwin":
        print("Installing pandoc via brew...")
        result = subprocess.run(["brew", "install", "pandoc"])
        return result.returncode == 0
    return False

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------

def check_dependencies(watch_mode=False):
    global PANDOC
    missing = []
    try:
        import pymupdf4llm  # noqa: F401
    except ImportError:
        missing.append("pymupdf4llm    ->  pip install pymupdf4llm")

    if PANDOC is None:
        print("pandoc not found. Attempting auto-install...")
        installed = _install_pandoc()
        if installed:
            PANDOC = _find_pandoc()
        if PANDOC is None:
            missing.append("pandoc         ->  see install instructions above")

    if watch_mode:
        try:
            import watchdog  # noqa: F401
        except ImportError:
            missing.append("watchdog       ->  pip install watchdog")

    return missing

# ---------------------------------------------------------------------------
# Source discovery
# ---------------------------------------------------------------------------

def discover_sources(library_root, category_filter=None):
    """Scan library_root immediate subdirs as categories.
    Files directly in library_root go to the 'General' category.
    Returns list of (path, category_name) tuples, EPUB preferred over PDF.
    """
    sources = []

    # Files directly in library_root -> "General"
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

    # Immediate subdirs -> category name = subdir name
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
# Filename parsing
# ---------------------------------------------------------------------------

def parse_filename(stem):
    """Extract (title, author) from a filename stem.
    Pattern: Title_Words_-_Author_Name -> ("Title Words", "Author Name")
    """
    name = stem.replace("_", " ")
    parts = name.split(" - ", 1)
    if len(parts) == 2:
        return parts[0].strip(), parts[1].strip()
    return parts[0].strip(), ""

# ---------------------------------------------------------------------------
# Frontmatter
# ---------------------------------------------------------------------------

def build_frontmatter(title, author, category, source_file, file_type):
    tag = re.sub(r"[^a-z0-9-]", "", category.lower().replace(" ", "-"))
    lines = ["---", f'title: "{_escape_yaml(title)}"']
    if author:
        lines.append(f'author: "{_escape_yaml(author)}"')
    lines += [
        f'category: "{category}"',
        f'source_file: "{source_file.name}"',
        f'file_type: "{file_type}"',
        f'imported: "{TODAY}"',
        f"tags: [library, {tag}]",
        "---",
        "",
    ]
    return "\n".join(lines)


def _escape_yaml(value):
    return value.replace('"', '\\"')

# ---------------------------------------------------------------------------
# Output path
# ---------------------------------------------------------------------------

def output_path(src, category, md_root):
    safe_stem = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", src.stem)
    safe_cat = re.sub(r'[<>:"/\\|?*\x00-\x1f ]', "_", category)
    return md_root / safe_cat / f"{safe_stem}.md"

# ---------------------------------------------------------------------------
# Converters
# ---------------------------------------------------------------------------

def convert_pdf(src, dst, title, author, category):
    import pymupdf4llm
    try:
        md = pymupdf4llm.to_markdown(str(src))
        header = build_frontmatter(title, author, category, src, "pdf")
        dst.write_text(header + md, encoding="utf-8")
        return True
    except Exception as exc:
        print(f"  ERROR pdf  {src.name}: {exc}", file=sys.stderr)
        return False


def convert_epub(src, dst, title, author, category):
    try:
        result = subprocess.run(
            [PANDOC, str(src), "-t", "markdown-raw_html", "--wrap=none", "-o", str(dst)],
            capture_output=True, text=True, timeout=180,
        )
        if result.returncode != 0:
            print(f"  ERROR epub {src.name}: {result.stderr.strip()}", file=sys.stderr)
            return False
        body = dst.read_text(encoding="utf-8")
        header = build_frontmatter(title, author, category, src, "epub")
        dst.write_text(header + body, encoding="utf-8")
        return True
    except subprocess.TimeoutExpired:
        print(f"  TIMEOUT    {src.name}", file=sys.stderr)
        dst.unlink(missing_ok=True)
        return False
    except Exception as exc:
        print(f"  ERROR epub {src.name}: {exc}", file=sys.stderr)
        return False

# ---------------------------------------------------------------------------
# Batch run
# ---------------------------------------------------------------------------

def run_batch(library_root, output_root, dry_run=False, category_filter=None):
    missing = check_dependencies()
    if missing:
        print("Missing dependencies -- install these first:")
        for m in missing:
            print(f"  {m}")
        sys.exit(1)

    print(f"Library root : {library_root}")
    print(f"Output root  : {output_root}")

    try:
        from tqdm import tqdm as _tqdm
        def wrap(it, **kw):
            return _tqdm(it, **kw)
    except ImportError:
        def wrap(it, **kw):
            print(f"Processing {kw.get('total', '?')} files (install tqdm for a progress bar)")
            return it

    sources = discover_sources(library_root, category_filter)

    if not sources:
        print("No PDF or EPUB files found under library root.")
        return

    if dry_run:
        for src, category in sources:
            dst = output_path(src, category, output_root)
            epub_sibling = src.with_suffix(".epub")
            if src.suffix.lower() == ".pdf" and epub_sibling.exists():
                status = "SKIP/EPUB"
            elif dst.exists():
                status = "EXISTS  "
            else:
                status = "CONVERT "
            print(f"[{status}] {category}/{src.name}  ->  {dst}")
        print(f"\nTotal: {len(sources)} files")
        return

    converted = skipped = failed = 0

    for src, category in wrap(sources, desc="Converting", total=len(sources), unit="file"):
        dst = output_path(src, category, output_root)
        epub_sibling = src.with_suffix(".epub")

        if src.suffix.lower() == ".pdf" and epub_sibling.exists():
            skipped += 1
            continue
        if dst.exists():
            skipped += 1
            continue

        dst.parent.mkdir(parents=True, exist_ok=True)
        title, author = parse_filename(src.stem)

        if src.suffix.lower() == ".epub":
            ok = convert_epub(src, dst, title, author, category)
        else:
            ok = convert_pdf(src, dst, title, author, category)

        if ok:
            converted += 1
        else:
            failed += 1

    print(f"\nDone.  Converted: {converted}  |  Skipped (exists): {skipped}  |  Failed: {failed}")
    if failed:
        print("Re-run to retry failed files, or check stderr output above.")

# ---------------------------------------------------------------------------
# Watch mode
# ---------------------------------------------------------------------------

def run_watch(library_root, output_root):
    missing = check_dependencies(watch_mode=True)
    if missing:
        print("Missing dependencies -- install these first:")
        for m in missing:
            print(f"  {m}")
        sys.exit(1)

    print(f"Output root: {output_root}")

    from watchdog.events import FileSystemEventHandler
    from watchdog.observers import Observer

    class SourceHandler(FileSystemEventHandler):
        def __init__(self, category):
            self.category = category

        def on_created(self, event):
            if event.is_directory:
                return
            src = Path(event.src_path)
            if src.suffix.lower() not in (".pdf", ".epub"):
                return
            time.sleep(1)
            if not src.exists():
                return
            print(f"\n[watch] Detected: {src.name} ({self.category})")
            dst = output_path(src, self.category, output_root)
            epub_sibling = src.with_suffix(".epub")
            if src.suffix.lower() == ".pdf" and epub_sibling.exists():
                print("[watch] Skipped: EPUB sibling exists")
                return
            if dst.exists():
                print("[watch] Skipped: already converted")
                return
            dst.parent.mkdir(parents=True, exist_ok=True)
            title, author = parse_filename(src.stem)
            if src.suffix.lower() == ".epub":
                ok = convert_epub(src, dst, title, author, self.category)
            else:
                ok = convert_pdf(src, dst, title, author, self.category)
            if ok:
                print(f"[watch] Converted: {src.name}")
            else:
                print(f"[watch] Failed: {src.name}")

    observer = Observer()
    watched = []

    try:
        for subdir in sorted(library_root.iterdir()):
            if subdir.is_dir():
                observer.schedule(SourceHandler(subdir.name), str(subdir), recursive=False)
                watched.append(f"  {subdir.name}: {subdir}")
    except PermissionError as exc:
        print(f"ERROR: cannot watch {library_root}: {exc}", file=sys.stderr)
        sys.exit(1)

    observer.schedule(SourceHandler("General"), str(library_root), recursive=False)
    watched.append(f"  General (root): {library_root}")

    observer.start()
    print("Watching for new PDF/EPUB files:")
    for w in watched:
        print(w)
    print("\nDrop files into any watched folder to auto-convert.")
    print("Press Ctrl+C to stop.\n")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        print("\nStopped.")

    observer.join()

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Convert PDF/EPUB library to Markdown."
    )
    parser.add_argument(
        "--library-root", required=True, metavar="PATH",
        help="Root directory containing your book/paper subdirectories",
    )
    parser.add_argument(
        "--output-root", required=True, metavar="PATH",
        help="Directory to write converted Markdown files into",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="List files without converting anything",
    )
    parser.add_argument(
        "--category", metavar="NAME",
        help="Process only one category (subdir name), e.g. Cybersec",
    )
    parser.add_argument(
        "--watch", action="store_true",
        help="Watch source directories and auto-convert new files as they are added",
    )
    args = parser.parse_args()

    library_root = Path(args.library_root).resolve()
    output_root = Path(args.output_root).resolve()

    if not library_root.exists():
        print(f"ERROR: --library-root does not exist: {library_root}", file=sys.stderr)
        sys.exit(1)

    output_root.mkdir(parents=True, exist_ok=True)

    if args.watch:
        run_watch(library_root, output_root)
    else:
        run_batch(library_root, output_root, dry_run=args.dry_run, category_filter=args.category)
