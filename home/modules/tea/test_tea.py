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
        filepath = tea.daily_filepath(None)
        tea.add_tasks_to_file(filepath, "buy milk", lambda fp: tea.create_daily_note(fp, None))
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
        tea.add_tasks_to_file(path, "new task", lambda fp: tea.create_daily_note(fp, None))
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
            tea.add_tasks_to_file(path, "a task", lambda fp: tea.create_daily_note(fp, None))

    # Inserts after the blank line following ## Tasks when there are no tasks yet.
    def test_existing_file_empty_tasks_section(self, notes_dir, mock_today):
        path = notes_dir / "daily" / "2026" / "03" / "2026-03-14.md"
        path.parent.mkdir(parents=True)
        path.write_text("---\ntitle: 2026-03-14\n---\n\n## Tasks\n\n")
        tea.add_tasks_to_file(path, "first task", lambda fp: tea.create_daily_note(fp, None))
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
        tea.add_tasks_to_file(path, "another task", lambda fp: tea.create_daily_note(fp, None))
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
        tea.add_tasks_to_file(path, "new task", lambda fp: tea.create_daily_note(fp, None))
        lines = path.read_text().splitlines()
        done_idx = lines.index("- [x] done task")
        new_idx = lines.index("- [ ] new task")
        assert new_idx == done_idx + 1

    # Comma-separated input creates multiple tasks in a new file.
    def test_comma_separated_new_file(self, notes_dir, mock_today):
        filepath = tea.daily_filepath(None)
        tea.add_tasks_to_file(filepath, "clean bathroom, clean bedroom", lambda fp: tea.create_daily_note(fp, None))
        path = notes_dir / "daily" / "2026" / "03" / "2026-03-14.md"
        content = path.read_text()
        assert "- [ ] clean bathroom\n" in content
        assert "- [ ] clean bedroom\n" in content
        assert "- [ ] \n" not in content

    # Comma-separated input creates multiple tasks in an existing file in order.
    def test_comma_separated_existing_file(self, notes_dir, mock_today):
        path = notes_dir / "daily" / "2026" / "03" / "2026-03-14.md"
        path.parent.mkdir(parents=True)
        path.write_text(
            "---\ntitle: 2026-03-14\n---\n\n## Tasks\n\n- [ ] existing task\n"
        )
        tea.add_tasks_to_file(path, "task a, task b", lambda fp: tea.create_daily_note(fp, None))
        lines = path.read_text().splitlines()
        existing_idx = lines.index("- [ ] existing task")
        a_idx = lines.index("- [ ] task a")
        b_idx = lines.index("- [ ] task b")
        assert a_idx == existing_idx + 1
        assert b_idx == existing_idx + 2

    # Whitespace around commas is trimmed.
    def test_comma_whitespace_trimmed(self, notes_dir, mock_today):
        filepath = tea.daily_filepath(None)
        tea.add_tasks_to_file(filepath, "  foo ,  bar  , baz  ", lambda fp: tea.create_daily_note(fp, None))
        path = notes_dir / "daily" / "2026" / "03" / "2026-03-14.md"
        content = path.read_text()
        assert "- [ ] foo\n" in content
        assert "- [ ] bar\n" in content
        assert "- [ ] baz\n" in content


class TestProjectFilepath:
    # Builds the correct path under projects directory.
    def test_basic(self, notes_dir):
        result = tea.project_filepath("api-migration")
        assert result == notes_dir / "projects" / "api-migration.md"
        assert result.parent.is_dir()


class TestCreateProjectNote:
    # Writes frontmatter, tasks, and notes sections.
    def test_basic(self, notes_dir):
        path = notes_dir / "project.md"
        tea.create_project_note(path, "home-server")
        content = path.read_text()
        assert content == (
            "---\ntitle: home-server\n---\n\n"
            "## Tasks\n\n- [ ] \n\n"
            "## Notes\n\n"
        )


class TestProjectAdd:
    # Creates a new project file and adds the task.
    def test_new_project(self, notes_dir):
        filepath = tea.project_filepath("myproj")
        tea.add_tasks_to_file(filepath, "first thing", lambda fp: tea.create_project_note(fp, "myproj"))
        path = notes_dir / "projects" / "myproj.md"
        content = path.read_text()
        assert "- [ ] first thing\n" in content
        assert "- [ ] \n" not in content

    # Appends to an existing project file.
    def test_existing_project(self, notes_dir):
        path = notes_dir / "projects" / "myproj.md"
        path.parent.mkdir(parents=True)
        path.write_text(
            "---\ntitle: myproj\n---\n\n## Tasks\n\n- [ ] existing\n\n## Notes\n\n"
        )
        tea.add_tasks_to_file(path, "new thing", lambda fp: tea.create_project_note(fp, "myproj"))
        lines = path.read_text().splitlines()
        existing_idx = lines.index("- [ ] existing")
        new_idx = lines.index("- [ ] new thing")
        assert new_idx == existing_idx + 1

    # Comma-separated tasks all get added.
    def test_comma_separated(self, notes_dir):
        filepath = tea.project_filepath("myproj")
        tea.add_tasks_to_file(filepath, "a, b, c", lambda fp: tea.create_project_note(fp, "myproj"))
        path = notes_dir / "projects" / "myproj.md"
        content = path.read_text()
        assert "- [ ] a\n" in content
        assert "- [ ] b\n" in content
        assert "- [ ] c\n" in content

    # Exits with code 1 if no ## Tasks section.
    def test_no_tasks_header(self, notes_dir):
        path = notes_dir / "projects" / "myproj.md"
        path.parent.mkdir(parents=True)
        path.write_text("---\ntitle: myproj\n---\n\nSome content\n")
        with pytest.raises(SystemExit, match="1"):
            tea.add_tasks_to_file(path, "a task", lambda fp: tea.create_project_note(fp, "myproj"))


class TestProjects:
    # Lists project names when projects exist.
    def test_lists_projects(self, notes_dir, capsys):
        pdir = notes_dir / "projects"
        pdir.mkdir(parents=True)
        (pdir / "alpha.md").write_text("test")
        (pdir / "beta.md").write_text("test")
        tea.list_projects()
        output = capsys.readouterr().out
        assert "alpha\n" in output
        assert "beta\n" in output

    # Prints message when no projects directory exists.
    def test_no_projects_dir(self, notes_dir, capsys):
        tea.list_projects()
        output = capsys.readouterr().out
        assert "No projects yet." in output

    # Prints message when projects directory is empty.
    def test_empty_projects_dir(self, notes_dir, capsys):
        (notes_dir / "projects").mkdir(parents=True)
        tea.list_projects()
        output = capsys.readouterr().out
        assert "No projects yet." in output
