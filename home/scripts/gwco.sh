set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: gwco <branch>" >&2
  exit 1
fi

branch="$1"

# Resolve paths: worktree goes next to the repo root
# e.g. if repo is at ~/Code/project/main, worktree is ~/Code/project/<branch>
repo_root="$(git rev-parse --show-toplevel)"
parent_dir="$(dirname "$repo_root")"
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
