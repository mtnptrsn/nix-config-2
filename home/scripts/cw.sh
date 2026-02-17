set -euo pipefail

MAX_LENGTH=255

resolve_parent_dir() {
  if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    dirname "$repo_root"
  else
    dirname "$(git rev-parse --git-common-dir)"
  fi
}

truncate_branch() {
  local branch="$1"
  if [ ${#branch} -gt $MAX_LENGTH ]; then
    branch="${branch:0:$MAX_LENGTH}"
    branch="${branch%-}"
    branch="${branch%.}"
  fi
  echo "$branch"
}

cmd_create() {
  if [ $# -ne 1 ]; then
    echo "Usage: cw create <branch>" >&2
    exit 1
  fi

  local branch
  branch="$(truncate_branch "$1")"
  local parent_dir
  parent_dir="$(resolve_parent_dir)"
  local worktree_path="$parent_dir/$branch"

  git worktree add -b "$branch" "$worktree_path"

  echo "Worktree created at $worktree_path"
}

cmd_checkout() {
  if [ $# -ne 1 ]; then
    echo "Usage: cw checkout <branch>" >&2
    exit 1
  fi

  local branch="$1"
  local parent_dir
  parent_dir="$(resolve_parent_dir)"
  local worktree_path="$parent_dir/$branch"

  git fetch --prune
  git worktree add "$worktree_path" "$branch"

  echo "Worktree created at $worktree_path"
}

cmd_remove() {
  if [ $# -ne 1 ]; then
    echo "Usage: cw remove <branch>" >&2
    exit 1
  fi

  local branch="$1"
  local parent_dir
  parent_dir="$(resolve_parent_dir)"
  local worktree_path="$parent_dir/$branch"

  git worktree remove "$worktree_path"
  git branch -D "$branch"

  echo "Removed worktree and branch '$branch'"
}

cmd_claude_start() {
  if [ $# -eq 0 ]; then
    echo "Usage: cw claude start <task description>" >&2
    exit 1
  fi

  local description="$*"
  local branch
  branch="$(echo "$description" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"
  branch="$(truncate_branch "$branch")"

  cmd_create "$branch"

  local parent_dir
  parent_dir="$(resolve_parent_dir)"
  local worktree_path="$parent_dir/$branch"

  cd "$worktree_path"
  claude "$description"
}

cmd_help() {
  echo "Usage: cw <command> [args]"
  echo ""
  echo "Commands:"
  echo "  create <branch>               Create a worktree with a new branch"
  echo "  checkout <branch>             Create a worktree for an existing branch"
  echo "  remove <branch>               Remove a git worktree and its branch"
  echo "  claude start <description>    Create a worktree and start Claude with a task"
  echo "  help                          Show this help message"
}

command="${1:-help}"
shift || true

case "$command" in
  create) cmd_create "$@" ;;
  checkout) cmd_checkout "$@" ;;
  remove) cmd_remove "$@" ;;
  claude)
    subcommand="${1:-}"
    shift || true
    case "$subcommand" in
      start) cmd_claude_start "$@" ;;
      *)
        echo "Unknown claude subcommand: $subcommand" >&2
        cmd_help >&2
        exit 1
        ;;
    esac
    ;;
  help) cmd_help ;;
  *)
    echo "Unknown command: $command" >&2
    cmd_help >&2
    exit 1
    ;;
esac
