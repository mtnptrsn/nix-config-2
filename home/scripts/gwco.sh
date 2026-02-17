set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: gwco <branch>" >&2
  exit 1
fi

branch="$1"

# Truncate to max git branch name length (filesystem NAME_MAX)
MAX_LENGTH=255
if [ ${#branch} -gt $MAX_LENGTH ]; then
  branch="${branch:0:$MAX_LENGTH}"
  branch="${branch%-}"
  branch="${branch%.}"
fi

# Resolve paths: worktree goes next to the repo root
# e.g. if repo is at ~/Code/project/main, worktree is ~/Code/project/<branch>
# Also handles being run from the bare repo directory itself
if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  parent_dir="$(dirname "$repo_root")"
else
  parent_dir="$(dirname "$(git rev-parse --git-common-dir)")"
fi
worktree_path="$parent_dir/$branch"

# Fetch latest remote refs so the branch check is up to date
git fetch --prune

if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  # Branch exists on remote — check it out as a tracking worktree
  git worktree add "$worktree_path" "$branch"
else
  # Branch doesn't exist — create a new local branch in the worktree
  git worktree add -b "$branch" "$worktree_path"
fi

echo "Worktree created at $worktree_path"
