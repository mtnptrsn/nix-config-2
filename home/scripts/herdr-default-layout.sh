#!/usr/bin/env bash
# herdr tab.created hook: split a new tab into a 2x2 grid of panes.
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
top=${panes[0]}
bottom=$(herdr pane split "$top" --direction down --no-focus | jq -r '.result.pane.pane_id')
herdr pane split "$top" --direction right --no-focus >/dev/null
herdr pane split "$bottom" --direction right --no-focus >/dev/null
