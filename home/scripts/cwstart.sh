set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: cwstart <task description>" >&2
  exit 1
fi

# Join all arguments into a single description
description="$*"

# Convert to branch name: lowercase, spaces to dashes, strip non-alphanumeric/dash
branch="$(echo "$description" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"

# Create worktree via gwco
gwco "$branch"

# Compute worktree path the same way gwco does
if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  parent_dir="$(dirname "$repo_root")"
else
  parent_dir="$(dirname "$(git rev-parse --git-common-dir)")"
fi
worktree_path="$parent_dir/$branch"

cd "$worktree_path"
claude "$description"
