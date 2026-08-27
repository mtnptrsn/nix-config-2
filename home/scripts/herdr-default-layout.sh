#!/usr/bin/env bash
# herdr tab.created hook: split a new tab into a 2x2 grid of panes and, in a
# git-backed workspace, launch claude top-left, nvim bottom-left and lazygit
# bottom-right.
#
# New workspaces and worktree checkouts open a tab of their own, so this one
# event covers them too. It still only splits when the tab has its single root
# pane, so a tab restored with panes already in it is left alone.
set -euo pipefail

log() { printf 'default-layout: %s\n' "$*" >&2; }

event_json=${HERDR_PLUGIN_EVENT_JSON:-}
if [[ -z $event_json ]]; then
  log "no HERDR_PLUGIN_EVENT_JSON in environment"
  exit 0
fi

# The payload is the socket API event, either bare or wrapped in an envelope.
tab=$(jq -r '
  [.data.tab.tab_id?, .tab.tab_id?]
  | map(select(type == "string")) | first // empty
' <<<"$event_json")
if [[ -z $tab ]]; then
  log "no tab id in event: $event_json"
  exit 0
fi

workspace=${HERDR_WORKSPACE_ID:-${tab%%:*}}

mapfile -t panes < <(
  herdr pane list --workspace "$workspace" |
    jq -r --arg tab "$tab" '.result.panes[] | select(.tab_id == $tab) | .pane_id'
)
if [[ ${#panes[@]} -ne 1 ]]; then
  exit 0
fi

# Split down first, then split each row to the right, so the split tree matches
# a hand-built grid: one horizontal divider with a vertical divider per row.
top_left=${panes[0]}
bottom_left=$(herdr pane split "$top_left" --direction down --no-focus | jq -r '.result.pane.pane_id')
herdr pane split "$top_left" --direction right --no-focus >/dev/null
bottom_right=$(herdr pane split "$bottom_left" --direction right --no-focus | jq -r '.result.pane.pane_id')

# Git-backed workspaces get the working set launched for them; scratch
# workspaces keep four plain shells, since lazygit needs a repo to open.
worktree=$(
  herdr workspace get "$workspace" |
    jq -r '.result.workspace.worktree.checkout_path // empty'
)
if [[ -z $worktree ]]; then
  exit 0
fi

# `pane run` types the command at the pane's shell prompt, so herdr picks claude
# up through its normal agent detection. The top-right pane is left as a shell.
herdr pane run "$top_left" claude >/dev/null
herdr pane run "$bottom_left" nvim >/dev/null
herdr pane run "$bottom_right" lazygit >/dev/null
