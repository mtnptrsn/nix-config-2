import os
import sys
from datetime import date
from pathlib import Path

import typer

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


def add_tasks_to_file(filepath, task_str, create_fn):
    tasks = [t.strip() for t in task_str.split(",") if t.strip()]
    if not tasks:
        print("Error: no tasks provided", file=sys.stderr)
        sys.exit(1)

    if not filepath.exists():
        create_fn(filepath)
        content = filepath.read_text()
        content = content.replace("- [ ] \n", "".join(f"- [ ] {t}\n" for t in tasks))
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


def list_projects():
    pdir = project_dir()
    if not pdir.exists():
        print("No projects yet.")
        return []

    files = sorted(pdir.glob("*.md"))
    if not files:
        print("No projects yet.")
        return []

    for f in files:
        print(f.stem)
    return [f.stem for f in files]


app = typer.Typer(invoke_without_command=True)
project_app = typer.Typer(invoke_without_command=True)
app.add_typer(project_app, name="project")


@app.callback(invoke_without_command=True)
def default(
    ctx: typer.Context,
    context: str = typer.Option(None, "-c", "--context", help="Notes context"),
):
    ctx.ensure_object(dict)
    if ctx.obj.get("context") is None and context is not None:
        ctx.obj["context"] = context
    elif "context" not in ctx.obj:
        ctx.obj["context"] = context

    if ctx.invoked_subcommand is None:
        filepath = daily_filepath(ctx.obj["context"])
        if not filepath.exists():
            create_daily_note(filepath, ctx.obj["context"])
        os.execvp("nvim", ["nvim", str(filepath)])


@app.command()
def add(
    ctx: typer.Context,
    task: str = typer.Argument(help="Task description"),
    context: str = typer.Option(None, "-c", "--context", help="Notes context"),
):
    ctx.ensure_object(dict)
    c = context if context is not None else ctx.obj.get("context")
    filepath = daily_filepath(c)
    add_tasks_to_file(filepath, task, lambda fp: create_daily_note(fp, c))


@app.command("open")
def open_cmd():
    Path(NOTES_DIR).mkdir(parents=True, exist_ok=True)
    os.execvp("nvim", ["nvim", NOTES_DIR])


@app.command()
def projects():
    list_projects()


@project_app.callback(invoke_without_command=True)
def project_default(
    ctx: typer.Context,
    name: str = typer.Argument(help="Project name"),
):
    ctx.ensure_object(dict)
    ctx.obj["project_name"] = name

    if ctx.invoked_subcommand is None:
        filepath = project_filepath(name)
        if not filepath.exists():
            create_project_note(filepath, name)
        os.execvp("nvim", ["nvim", str(filepath)])


@project_app.command("add")
def project_add(
    ctx: typer.Context,
    task: str = typer.Argument(help="Task description"),
):
    ctx.ensure_object(dict)
    name = ctx.obj["project_name"]
    filepath = project_filepath(name)
    add_tasks_to_file(filepath, task, lambda fp: create_project_note(fp, name))


def main():
    app()


if __name__ == "__main__":
    main()
