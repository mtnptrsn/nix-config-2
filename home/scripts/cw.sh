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

cmd_co() {
  if [ $# -ne 1 ]; then
    echo "Usage: cw co <branch>" >&2
    exit 1
  fi

  local branch
  branch="$(truncate_branch "$1")"
  local parent_dir
  parent_dir="$(resolve_parent_dir)"
  local worktree_path="$parent_dir/$branch"

  git fetch --prune

  if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git worktree add "$worktree_path" "$branch"
  else
    git worktree add -b "$branch" "$worktree_path"
  fi

  echo "Worktree created at $worktree_path"
}

cmd_rm() {
  if [ $# -ne 1 ]; then
    echo "Usage: cw rm <branch>" >&2
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

cmd_start() {
  if [ $# -eq 0 ]; then
    echo "Usage: cw start <task description>" >&2
    exit 1
  fi

  local description="$*"
  local branch
  branch="$(echo "$description" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"
  branch="$(truncate_branch "$branch")"

  cmd_co "$branch"

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
  echo "  co <branch>            Create a git worktree for a branch"
  echo "  rm <branch>            Remove a git worktree and its branch"
  echo "  start <description>    Create a worktree and start Claude with a task"
  echo "  help                   Show this help message"
}

command="${1:-help}"
shift || true

case "$command" in
  co)    cmd_co "$@" ;;
  rm)    cmd_rm "$@" ;;
  start) cmd_start "$@" ;;
  help)  cmd_help ;;
  *)
    echo "Unknown command: $command" >&2
    cmd_help >&2
    exit 1
    ;;
esac
