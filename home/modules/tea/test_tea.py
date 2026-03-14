import argparse
from datetime import date
from unittest.mock import patch

import pytest

import tea


@pytest.fixture()
def notes_dir(tmp_path, monkeypatch):
    monkeypatch.setattr(tea, "NOTES_DIR", str(tmp_path))
    return tmp_path


@pytest.fixture()
def mock_today(monkeypatch):
    fixed = date(2026, 3, 14)
    with patch.object(tea, "date", wraps=date) as mock_date:
        mock_date.today.return_value = fixed
        monkeypatch.setattr(tea, "date", mock_date)
        yield fixed


def make_args(**kwargs):
    defaults = {"context": None, "task": None}
    defaults.update(kwargs)
    return argparse.Namespace(**defaults)


class TestDailyFilepath:
    # Builds the correct path from today's date and creates parent directories.
    def test_no_context(self, notes_dir, mock_today):
        result = tea.daily_filepath(None)
        assert result == notes_dir / "daily" / "2026" / "03" / "2026-03-14.md"
        assert result.parent.is_dir()

    # Appends the context name to the filename stem.
    def test_with_context(self, notes_dir, mock_today):
        result = tea.daily_filepath("work")
        assert result == notes_dir / "daily" / "2026" / "03" / "2026-03-14-work.md"


class TestCreateDailyNote:
    # Writes frontmatter with title, a Tasks heading, and an empty checkbox.
    def test_no_context(self, notes_dir, mock_today):
        path = notes_dir / "note.md"
        tea.create_daily_note(path, None)
        content = path.read_text()
        assert content == (
            "---\n"
            "title: 2026-03-14\n"
            "---\n"
            "\n"
            "## Tasks\n"
            "\n"
            "- [ ] \n"
        )

    # Includes a context field in the frontmatter when a context is given.
    def test_with_context(self, notes_dir, mock_today):
        path = notes_dir / "note.md"
        tea.create_daily_note(path, "work")
        content = path.read_text()
        assert "context: work\n" in content


class TestDayAdd:
    # When no file exists yet, creates it and replaces the empty placeholder with the task.
    def test_new_file(self, notes_dir, mock_today):
        tea.cmd_day_add(make_args(context=None, task="buy milk"))
        path = notes_dir / "daily" / "2026" / "03" / "2026-03-14.md"
        content = path.read_text()
        assert "- [ ] buy milk\n" in content
        assert "- [ ] \n" not in content

    # Inserts the new task right after the last existing task.
    def test_existing_file_appends(self, notes_dir, mock_today):
        path = notes_dir / "daily" / "2026" / "03" / "2026-03-14.md"
        path.parent.mkdir(parents=True)
        path.write_text(
            "---\ntitle: 2026-03-14\n---\n\n## Tasks\n\n- [ ] existing task\n"
        )
        tea.cmd_day_add(make_args(context=None, task="new task"))
        lines = path.read_text().splitlines()
        existing_idx = lines.index("- [ ] existing task")
        new_idx = lines.index("- [ ] new task")
        assert new_idx == existing_idx + 1

    # Exits with code 1 if the file has no ## Tasks heading.
    def test_existing_file_no_tasks_header(self, notes_dir, mock_today):
        path = notes_dir / "daily" / "2026" / "03" / "2026-03-14.md"
        path.parent.mkdir(parents=True)
        path.write_text("---\ntitle: 2026-03-14\n---\n\nSome content\n")
        with pytest.raises(SystemExit, match="1"):
            tea.cmd_day_add(make_args(context=None, task="a task"))

    # Inserts after the blank line following ## Tasks when there are no tasks yet.
    def test_existing_file_empty_tasks_section(self, notes_dir, mock_today):
        path = notes_dir / "daily" / "2026" / "03" / "2026-03-14.md"
        path.parent.mkdir(parents=True)
        path.write_text("---\ntitle: 2026-03-14\n---\n\n## Tasks\n\n")
        tea.cmd_day_add(make_args(context=None, task="first task"))
        lines = path.read_text().splitlines()
        tasks_idx = lines.index("## Tasks")
        assert lines[tasks_idx + 2] == "- [ ] first task"

    # Treats "- [ ]" (no description) as a placeholder and inserts before it, not after.
    def test_skips_empty_placeholder(self, notes_dir, mock_today):
        path = notes_dir / "daily" / "2026" / "03" / "2026-03-14.md"
        path.parent.mkdir(parents=True)
        path.write_text(
            "---\ntitle: 2026-03-14\n---\n\n## Tasks\n\n- [ ] real task\n- [ ]\n"
        )
        tea.cmd_day_add(make_args(context=None, task="another task"))
        lines = path.read_text().splitlines()
        real_idx = lines.index("- [ ] real task")
        new_idx = lines.index("- [ ] another task")
        assert new_idx == real_idx + 1

    # Inserts after a completed (checked) task, since it counts as a real task.
    def test_after_checked_task(self, notes_dir, mock_today):
        path = notes_dir / "daily" / "2026" / "03" / "2026-03-14.md"
        path.parent.mkdir(parents=True)
        path.write_text(
            "---\ntitle: 2026-03-14\n---\n\n## Tasks\n\n- [x] done task\n"
        )
        tea.cmd_day_add(make_args(context=None, task="new task"))
        lines = path.read_text().splitlines()
        done_idx = lines.index("- [x] done task")
        new_idx = lines.index("- [ ] new task")
        assert new_idx == done_idx + 1
