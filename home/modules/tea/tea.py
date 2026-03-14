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
    filepath = daily_filepath(args.context)

    if not filepath.exists():
        create_daily_note(filepath, args.context)
        content = filepath.read_text()
        content = content.replace("- [ ] \n", f"- [ ] {args.task}\n")
        filepath.write_text(content)
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

    new_line = f"- [ ] {args.task}\n"

    if last_task_idx is not None:
        lines.insert(last_task_idx + 1, new_line)
    else:
        # Insert after the blank line following ## Tasks, or right after it
        insert_at = tasks_idx + 1
        if insert_at < len(lines) and lines[insert_at].strip() == "":
            insert_at += 1
        lines.insert(insert_at, new_line)

    filepath.write_text("".join(lines))


def cmd_open(_args):
    Path(NOTES_DIR).mkdir(parents=True, exist_ok=True)
    os.execvp("nvim", ["nvim", NOTES_DIR])


def main():
    parser = argparse.ArgumentParser(
        prog="tea", description="Daily notes tool"
    )
    subparsers = parser.add_subparsers(dest="command")

    day_parser = subparsers.add_parser("day", help="Open today's daily note")
    day_parser.add_argument(
        "-c", "--context", help="Notes context"
    )
    day_subparsers = day_parser.add_subparsers(dest="action")
    day_add_parser = day_subparsers.add_parser(
        "add", help="Add a task to today's daily note"
    )
    day_add_parser.add_argument(
        "-c", "--context", help="Notes context"
    )
    day_add_parser.add_argument("task", help="Task description")

    subparsers.add_parser("open", help="Open notes directory")

    args = parser.parse_args()

    if args.command == "day":
        if args.action == "add":
            cmd_day_add(args)
        else:
            cmd_day(args)
    elif args.command == "open":
        cmd_open(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
