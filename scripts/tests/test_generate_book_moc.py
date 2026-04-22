"""
Tests for generate-book-moc.py wiki-pattern additions (B-04).

Covers:
- render_note: cross_refs and summary_status frontmatter fields
- append_to_log: creates log.md, appends correctly, formats entries correctly
- parse_filename: existing function correctness
- _is_noise: existing function correctness
"""

import importlib.util
import sys
import tempfile
from datetime import date
from pathlib import Path

import pytest

# ---------------------------------------------------------------------------
# Load the script as a module (no __init__.py, uses dashes in name)
# ---------------------------------------------------------------------------

_SCRIPT = Path(__file__).parent.parent / "generate-book-moc.py"


def _load_moc():
    spec = importlib.util.spec_from_file_location("generate_book_moc", _SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


moc = _load_moc()

# ---------------------------------------------------------------------------
# render_note -- wiki frontmatter fields
# ---------------------------------------------------------------------------

class TestRenderNote:
    def _note(self, **kwargs):
        defaults = dict(
            title="Test Book",
            author="Test Author",
            category="Books/Cybersec",
            file_type="pdf",
            usb_path="Book Library/Cybersec/test.pdf",
            pages=300,
            toc=[],
        )
        defaults.update(kwargs)
        return moc.render_note(**defaults)

    def test_includes_cross_refs_field(self):
        note = self._note()
        assert "cross_refs:" in note

    def test_cross_refs_is_empty_list(self):
        note = self._note()
        assert "cross_refs: []" in note

    def test_includes_summary_status_field(self):
        note = self._note()
        assert "summary_status:" in note

    def test_summary_status_is_pending(self):
        note = self._note()
        assert 'summary_status: "pending"' in note

    def test_existing_title_field_intact(self):
        note = self._note(title="My Book")
        assert 'title: "My Book"' in note

    def test_existing_tags_field_intact(self):
        note = self._note(category="Books/Cybersec")
        assert "tags:" in note
        assert "library" in note

    def test_summary_placeholder_present(self):
        note = self._note()
        assert "## Summary" in note

# ---------------------------------------------------------------------------
# append_to_log
# ---------------------------------------------------------------------------

class TestAppendToLog:
    def test_creates_log_file_when_missing(self, tmp_path):
        vault_root = tmp_path
        moc.append_to_log(vault_root, "Test Book", "Books/Cybersec")
        log = vault_root / "02. AI-Vault" / "Library" / "log.md"
        assert log.exists()

    def test_log_entry_contains_title(self, tmp_path):
        moc.append_to_log(tmp_path, "Deep Learning", "Books/General Tech")
        log = tmp_path / "02. AI-Vault" / "Library" / "log.md"
        content = log.read_text(encoding="utf-8")
        assert "Deep Learning" in content

    def test_log_entry_contains_category(self, tmp_path):
        moc.append_to_log(tmp_path, "My Title", "Books/Cybersec")
        log = tmp_path / "02. AI-Vault" / "Library" / "log.md"
        content = log.read_text(encoding="utf-8")
        assert "Books/Cybersec" in content

    def test_log_entry_contains_today_date(self, tmp_path):
        moc.append_to_log(tmp_path, "Any Title", "Papers")
        log = tmp_path / "02. AI-Vault" / "Library" / "log.md"
        content = log.read_text(encoding="utf-8")
        assert date.today().isoformat() in content

    def test_appends_to_existing_log(self, tmp_path):
        log_dir = tmp_path / "02. AI-Vault" / "Library"
        log_dir.mkdir(parents=True)
        log = log_dir / "log.md"
        log.write_text("# Library Log\n\n[2026-01-01] Created [[Old Book]] (Books/History)\n", encoding="utf-8")
        moc.append_to_log(tmp_path, "New Book", "Books/Cybersec")
        content = log.read_text(encoding="utf-8")
        assert "Old Book" in content
        assert "New Book" in content

    def test_does_not_crash_when_vault_root_is_none(self):
        moc.append_to_log(None, "Any Title", "Any Category")

# ---------------------------------------------------------------------------
# parse_filename -- existing function
# ---------------------------------------------------------------------------

class TestParseFilename:
    def test_splits_title_and_author(self):
        title, author = moc.parse_filename("Clean Code - Robert Martin")
        assert title == "Clean Code"
        assert author == "Robert Martin"

    def test_returns_title_only_when_no_separator(self):
        title, author = moc.parse_filename("CleanCode")
        assert title == "CleanCode"
        assert author == ""

    def test_underscores_replaced_with_spaces(self):
        title, _ = moc.parse_filename("Clean_Code")
        assert title == "Clean Code"

# ---------------------------------------------------------------------------
# _is_noise -- existing function
# ---------------------------------------------------------------------------

class TestIsNoise:
    def test_code_file_extension_is_noise(self):
        assert moc._is_noise("example.py")

    def test_colophon_is_noise(self):
        assert moc._is_noise("colophon")

    def test_chapter_title_is_not_noise(self):
        assert not moc._is_noise("Introduction to Security")

    def test_from_prefix_is_noise(self):
        assert moc._is_noise("from the author")
