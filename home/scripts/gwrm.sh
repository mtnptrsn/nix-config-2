set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: gwrm <branch>" >&2
  exit 1
fi

branch="$1"

# Resolve paths: worktree is next to the repo root
# e.g. if repo is at ~/Code/project/main, worktree is ~/Code/project/<branch>
# Also handles being run from the bare repo directory itself
if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  parent_dir="$(dirname "$repo_root")"
else
  parent_dir="$(dirname "$(git rev-parse --git-common-dir)")"
fi
worktree_path="$parent_dir/$branch"

git worktree remove "$worktree_path"
git branch -D "$branch"

echo "Removed worktree and branch '$branch'"
