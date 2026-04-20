---
name: library-pipeline
description: Convert PDF/EPUB library to Markdown and generate Obsidian MOC notes
version: 0.2.0
level: 2
triggers:
  - "library pipeline"
  - "convert books"
  - "convert pdfs"
  - "book moc"
  - "/library-pipeline"
context_files:
  - context/user.md
steps:
  - name: Gate Check
    description: Confirm user has a PDF/EPUB library and Obsidian vault is configured
  - name: Collect Paths
    description: Ask user for library-root and vault-root; derive output-root
  - name: Dependency Check
    description: Verify pymupdf4llm and pandoc; auto-install pandoc if missing
  - name: Run Pipeline
    description: Execute convert-to-md.py then generate-book-moc.py with collected paths
  - name: Verify MOC
    description: Confirm Library MOC.md was written to vault
---

# Library Pipeline Skill

Converts a local PDF/EPUB book and paper library to Markdown, then generates
lightweight MOC notes in Obsidian. Callable standalone or from `/obsidian-setup`
as an optional post-setup step.

## What the Pipeline Does

**Step 1 -- Conversion** (`scripts/convert-to-md.py`)
Scans immediate subdirectories of `--library-root` as categories. Files at the
root itself go to a "General" category. Converts to Markdown and writes to
`--output-root`. EPUB is preferred over PDF when both exist. Resumable: skips
files already converted.

**Step 2 -- MOC generation** (`scripts/generate-book-moc.py`)
For each source file: extracts TOC and embedded metadata (no AI, no tokens).
Writes a structured Obsidian note to `<vault-root>/02. AI-Vault/Library/Books/`
or `.../Papers/`. The note stores a library-relative path so Claude can read
the full content on demand. Full book content never goes into Obsidian.
Automatically calls `generate-library-moc.py` when new notes are created.

**Step 3 -- Library index** (`scripts/generate-library-moc.py`, called automatically)
Scans all MOC notes and regenerates `<vault-root>/02. AI-Vault/Library/Library MOC.md`
with counts, categories, and wiki-link entries. Only runs when at least one new
note was created. To force a refresh: run `python scripts/generate-library-moc.py --vault-root <path>`.

## Required Paths

| Argument | Description | Example |
|---|---|---|
| `--library-root` | Root of your book/paper directory | `/run/media/user/USB/Books` |
| `--vault-root` | Obsidian vault root | `/home/user/Documents/Obsidian` |
| `--output-root` | Where to write converted Markdown | Defaults to `<library-root>/../Markdown` |

No paths are hardcoded. Every run requires these arguments.

## Dependencies

| Dependency | Required For | Install |
|---|---|---|
| `pymupdf4llm` | PDF conversion and TOC extraction | `pip install pymupdf4llm` |
| `pandoc` | EPUB conversion | Auto-installed (see below) |
| `tqdm` | Progress bar (optional) | `pip install tqdm` |
| `watchdog` | Watch mode only | `pip install watchdog` |

### Pandoc Auto-Install

The script attempts to install pandoc automatically:
- **Windows:** `winget install JohnMacFarlane.Pandoc`
- **macOS:** `brew install pandoc`
- **Linux:** prints `sudo apt-get install -y pandoc` and exits -- run the command, then re-run the script

On Linux, pandoc installation requires elevated access. Claude will print the
command; do not assume sudo is available without a password.

## Execution Steps

**1. Gate Check**
Ask: "Do you have a PDF/EPUB book or paper library you want to index?"
If no, skip. If Obsidian vault is not set up, suggest running `/obsidian-setup` first.

**2. Collect Paths**
Ask the user:
- "What is the root path of your book/paper library?"
- "What is the root path of your Obsidian vault?"
- "Where should converted Markdown files be written? (press Enter to default to a Markdown folder next to your library)"

Validate both required paths exist before proceeding. If either does not exist, report the error and stop.

**3. Dependency Check**
```bash
python -c "import pymupdf4llm; print('pymupdf4llm OK')"
pandoc --version
```
If `pymupdf4llm` is missing: abort -- PDF conversion is impossible without it.
If `pandoc` is missing: the script will attempt auto-install. On Linux it will
print an install command and exit; run it, then re-run the pipeline.

**4. Run Pipeline**
```bash
python scripts/convert-to-md.py \
    --library-root "<library-root>" \
    --output-root "<output-root>"

python scripts/generate-book-moc.py \
    --library-root "<library-root>" \
    --vault-root "<vault-root>" \
    --output-root "<output-root>"
```
Report `convert-to-md.py` output as "Conversion:" and `generate-book-moc.py`
output as "MOC generation:" separately so partial failures are visible.

**5. Verify MOC**
Check `<vault-root>/02. AI-Vault/Library/Library MOC.md` was created or updated.
If Obsidian MCP is active, read it to confirm entry count matches expectations.

## Shell Wrappers

For direct use without Claude:
```bash
# Linux/macOS
bash scripts/run-library-pipeline.sh /path/to/library /path/to/vault

# Windows
scripts\run-library-pipeline.bat "C:\Books" "C:\Vault"
```
Wrappers prompt interactively if paths are not passed as arguments.
Output-root defaults to a `Markdown` folder next to library-root.

## Useful Flags

```bash
python scripts/convert-to-md.py --library-root ... --output-root ... --dry-run
python scripts/convert-to-md.py --library-root ... --output-root ... --category Cybersec
python scripts/convert-to-md.py --library-root ... --output-root ... --watch
python scripts/generate-book-moc.py --library-root ... --vault-root ... --file path/to/book.pdf
python scripts/generate-library-moc.py --vault-root /path/to/vault
```

## Degraded Mode

| Missing | Behavior |
|---|---|
| `pymupdf4llm` | Cannot convert PDFs or extract TOC. Script exits 1 immediately. |
| `pandoc` | Auto-install attempted. If it fails on Linux, script exits 1 with install command. |
| `tqdm` | No progress bar. Continues normally. |
| `watchdog` | Watch mode unavailable. Batch mode still works. |
| `--output-root` not provided | Shell wrappers default to `<library-root>/../Markdown`. Scripts require it explicitly. |
| Obsidian not running | MOC notes written directly to vault filesystem. MCP tools unavailable but not required. |
| Library root empty | Script reports "No PDF or EPUB files found" and exits cleanly. |

## Wiki Pattern (Karpathy-inspired)

Generated notes follow a consistent wiki schema defined in `scripts/wiki-schema.md`.

**Key additions to generated notes:**
- `cross_refs: []` -- empty on creation; filled by Claude when summarizing
- `summary_status: "pending"` -- updated to "done" after Claude fills in the Summary section
- `log.md` -- pipeline appends a creation entry to `<vault-root>/02. AI-Vault/Library/log.md` after each new note

**Update-vs-create rule:**
- Create when: note does not exist
- Update when: user requests re-index OR summary_status is "pending"
- Never overwrite a note with `summary_status: "done"` without explicit user instruction

**Cross-references:** Added by Claude via `obsidian_patch`, not by the pipeline. The pipeline
only creates the empty `cross_refs: []` slot.

See `scripts/wiki-schema.md` for the full field reference and update logic.

## Integration with obsidian-setup

When called from `/obsidian-setup`, ask the gate question inline:
"Do you have a PDF/EPUB library you want to import into Obsidian?"
If yes, run this skill in full starting from Step 2. If no, skip silently.

## Mandatory Checklist

1. Verify `--library-root` and `--vault-root` paths exist before running any script
2. Verify `pymupdf4llm` is installed before attempting PDF conversion
3. Verify `convert-to-md.py` output before running `generate-book-moc.py`
4. Verify at least one MOC note was written to `<vault-root>/02. AI-Vault/Library/`
5. Report conversion and MOC generation counts separately so partial failures are visible
6. Never overwrite a note with `summary_status: "done"` without explicit user instruction
