#!/usr/bin/env bash
# herdr worktree.created hook: copy the files listed in the repo's
# .worktreeinclude into a freshly created worktree.
#
# The file uses .gitignore syntax and is matched against everything untracked
# in the main checkout, so .env.local, certs and local settings follow along
# into the new worktree.
set -euo pipefail

log() { printf 'worktree-include: %s\n' "$*" >&2; }

event_json=${HERDR_PLUGIN_EVENT_JSON:-}
if [[ -z $event_json ]]; then
  log "no HERDR_PLUGIN_EVENT_JSON in environment"
  exit 0
fi

# The payload is the socket API event, either bare or wrapped in an envelope.
worktree=$(jq -r '
  [.worktree.path?, .data.worktree.path?,
   .workspace.worktree.checkout_path?, .data.workspace.worktree.checkout_path?]
  | map(select(type == "string")) | first // empty
' <<<"$event_json")
if [[ -z $worktree || ! -d $worktree ]]; then
  log "no worktree path in event: $event_json"
  exit 0
fi

# The main checkout is the parent of the shared git dir. Bare repos have no
# checkout to copy from, so there is nothing to do.
common_dir=$(git -C "$worktree" rev-parse --path-format=absolute --git-common-dir)
if [[ $(basename "$common_dir") != .git ]]; then
  log "shared git dir is bare, nothing to copy"
  exit 0
fi
main=$(dirname "$common_dir")

include=$main/.worktreeinclude
if [[ ! -f $include ]]; then
  exit 0
fi

# --others --ignored --exclude-from selects untracked files matching the
# include patterns only, so tracked files and node_modules are never listed.
mapfile -d '' -t files < <(
  git -C "$main" ls-files -z --others --ignored --exclude-from="$include"
)

if [[ ${#files[@]} -eq 0 ]]; then
  exit 0
fi

printf '%s\0' "${files[@]}" |
  tar -C "$main" --null --files-from=- -cf - |
  tar -C "$worktree" -xf -

log "copied ${#files[@]} file(s) from $main"
