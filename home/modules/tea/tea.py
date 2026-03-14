import argparse
import os
import sys
from datetime import date
from pathlib import Path

NOTES_DIR = os.path.expanduser("@notesDir@")


def daily_filepath(context):
    today = date.today()
    year = today.strftime("%Y")
    month = today.strftime("%m")
    stem = today.strftime("%Y-%m-%d")
    if context:
        stem = f"{stem}-{context}"
    filename = f"{stem}.md"

    daily_dir = Path(NOTES_DIR) / "daily" / year / month
    daily_dir.mkdir(parents=True, exist_ok=True)

    return daily_dir / filename


def create_daily_note(filepath, context):
    today = date.today()
    title = today.strftime("%Y-%m-%d")
    frontmatter = f"---\ntitle: {title}\n"
    if context:
        frontmatter += f"context: {context}\n"
    frontmatter += "---\n"
    filepath.write_text(f"{frontmatter}\n## Tasks\n\n- [ ] \n")


def cmd_day(args):
    filepath = daily_filepath(args.context)

    if not filepath.exists():
        create_daily_note(filepath, args.context)

    os.execvp("nvim", ["nvim", str(filepath)])


def cmd_day_add(args):
    tasks = [t.strip() for t in args.task.split(",") if t.strip()]
    if not tasks:
        print("Error: no tasks provided", file=sys.stderr)
        sys.exit(1)

    filepath = daily_filepath(args.context)

    if not filepath.exists():
        create_daily_note(filepath, args.context)
        content = filepath.read_text()
        content = content.replace(
            "- [ ] \n", "".join(f"- [ ] {t}\n" for t in tasks)
        )
        filepath.write_text(content)
        for t in tasks:
            print(f"Added: {t}")
        return

    lines = filepath.read_text().splitlines(keepends=True)

    tasks_idx = None
    for i, line in enumerate(lines):
        if line.rstrip() == "## Tasks":
            tasks_idx = i
            break

    if tasks_idx is None:
        print("Error: ## Tasks section not found", file=sys.stderr)
        sys.exit(1)

    last_task_idx = None
    for i in range(tasks_idx + 1, len(lines)):
        stripped = lines[i].rstrip()
        if stripped == "- [ ]" or stripped == "- [x]":
            # Empty placeholder, skip
            continue
        elif stripped.startswith("- [ ] ") or stripped.startswith("- [x] "):
            last_task_idx = i
        elif stripped.startswith("## "):
            break

    new_lines = [f"- [ ] {t}\n" for t in tasks]

    if last_task_idx is not None:
        for j, nl in enumerate(new_lines):
            lines.insert(last_task_idx + 1 + j, nl)
    else:
        # Insert after the blank line following ## Tasks, or right after it
        insert_at = tasks_idx + 1
        if insert_at < len(lines) and lines[insert_at].strip() == "":
            insert_at += 1
        for j, nl in enumerate(new_lines):
            lines.insert(insert_at + j, nl)

    filepath.write_text("".join(lines))
    for t in tasks:
        print(f"Added: {t}")


def project_dir():
    return Path(NOTES_DIR) / "projects"


def project_filepath(name):
    pdir = project_dir()
    pdir.mkdir(parents=True, exist_ok=True)
    return pdir / f"{name}.md"


def create_project_note(filepath, name):
    filepath.write_text(
        f"---\ntitle: {name}\n---\n\n## Tasks\n\n- [ ] \n\n## Notes\n\n"
    )


def cmd_project(args):
    filepath = project_filepath(args.name)

    if not filepath.exists():
        create_project_note(filepath, args.name)

    os.execvp("nvim", ["nvim", str(filepath)])


def cmd_project_add(args):
    tasks = [t.strip() for t in args.task.split(",") if t.strip()]
    if not tasks:
        print("Error: no tasks provided", file=sys.stderr)
        sys.exit(1)

    filepath = project_filepath(args.name)

    if not filepath.exists():
        create_project_note(filepath, args.name)
        content = filepath.read_text()
        content = content.replace(
            "- [ ] \n", "".join(f"- [ ] {t}\n" for t in tasks)
        )
        filepath.write_text(content)
        for t in tasks:
            print(f"Added: {t}")
        return

    lines = filepath.read_text().splitlines(keepends=True)

    tasks_idx = None
    for i, line in enumerate(lines):
        if line.rstrip() == "## Tasks":
            tasks_idx = i
            break

    if tasks_idx is None:
        print("Error: ## Tasks section not found", file=sys.stderr)
        sys.exit(1)

    last_task_idx = None
    for i in range(tasks_idx + 1, len(lines)):
        stripped = lines[i].rstrip()
        if stripped == "- [ ]" or stripped == "- [x]":
            continue
        elif stripped.startswith("- [ ] ") or stripped.startswith("- [x] "):
            last_task_idx = i
        elif stripped.startswith("## "):
            break

    new_lines = [f"- [ ] {t}\n" for t in tasks]

    if last_task_idx is not None:
        for j, nl in enumerate(new_lines):
            lines.insert(last_task_idx + 1 + j, nl)
    else:
        insert_at = tasks_idx + 1
        if insert_at < len(lines) and lines[insert_at].strip() == "":
            insert_at += 1
        for j, nl in enumerate(new_lines):
            lines.insert(insert_at + j, nl)

    filepath.write_text("".join(lines))
    for t in tasks:
        print(f"Added: {t}")


def cmd_projects(_args):
    pdir = project_dir()
    if not pdir.exists():
        print("No projects yet.")
        return

    files = sorted(pdir.glob("*.md"))
    if not files:
        print("No projects yet.")
        return

    for f in files:
        print(f.stem)


def cmd_open(_args):
    Path(NOTES_DIR).mkdir(parents=True, exist_ok=True)
    os.execvp("nvim", ["nvim", NOTES_DIR])


def main():
    parser = argparse.ArgumentParser(
        prog="tea", description="Daily notes tool"
    )
    parser.add_argument(
        "-c", "--context", help="Notes context"
    )
    subparsers = parser.add_subparsers(dest="command")

    add_parser = subparsers.add_parser(
        "add", help="Add a task to today's daily note"
    )
    add_parser.add_argument(
        "-c", "--context", help="Notes context"
    )
    add_parser.add_argument("task", help="Task description")

    subparsers.add_parser("open", help="Open notes directory")

    subparsers.add_parser("projects", help="List all projects")
    subparsers.add_parser("project", help="Open or manage a project")

    args, remaining = parser.parse_known_args()

    if args.command == "add":
        cmd_day_add(args)
    elif args.command == "open":
        cmd_open(args)
    elif args.command == "projects":
        cmd_projects(args)
    elif args.command == "project":
        if not remaining:
            print("Usage: tea project <name> [add <task>]", file=sys.stderr)
            sys.exit(1)
        name = remaining[0]
        if len(remaining) >= 3 and remaining[1] == "add":
            task_str = " ".join(remaining[2:])
            args.name = name
            args.task = task_str
            cmd_project_add(args)
        elif len(remaining) == 1:
            args.name = name
            cmd_project(args)
        else:
            print("Usage: tea project <name> [add <task>]", file=sys.stderr)
            sys.exit(1)
    else:
        cmd_day(args)


if __name__ == "__main__":
    main()
