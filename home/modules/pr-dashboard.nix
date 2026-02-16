{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.pr-dashboard;

  pr-dashboard = pkgs.writeShellScriptBin "pr-dashboard" ''
    set -euo pipefail

    GH="${pkgs.gh}/bin/gh"
    JQ="${pkgs.jq}/bin/jq"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    DATE="${pkgs.coreutils}/bin/date"
    SORT="${pkgs.coreutils}/bin/sort"
    MKTEMP="${pkgs.coreutils}/bin/mktemp"
    SLEEP="${pkgs.coreutils}/bin/sleep"

    STATE_FILE="$($MKTEMP)"
    trap 'rm -f "$STATE_FILE"' EXIT

    get_user_last_activity() {
      local owner_repo="$1"
      local pr_number="$2"
      local user
      user="$($GH api user --jq '.login')"

      local last_review
      last_review="$($GH api "repos/$owner_repo/pulls/$pr_number/reviews" \
        --jq "[.[] | select(.user.login == \"$user\")] | sort_by(.submitted_at) | last | .submitted_at // empty" 2>/dev/null || true)"

      local last_comment
      last_comment="$($GH api "repos/$owner_repo/issues/$pr_number/comments" \
        --jq "[.[] | select(.user.login == \"$user\")] | sort_by(.updated_at) | last | .updated_at // empty" 2>/dev/null || true)"

      if [[ -n "$last_review" && -n "$last_comment" ]]; then
        if [[ "$last_review" > "$last_comment" ]]; then
          echo "$last_review"
        else
          echo "$last_comment"
        fi
      elif [[ -n "$last_review" ]]; then
        echo "$last_review"
      elif [[ -n "$last_comment" ]]; then
        echo "$last_comment"
      fi
    }

    get_latest_push() {
      local owner_repo="$1"
      local pr_number="$2"

      $GH api "repos/$owner_repo/pulls/$pr_number/commits" \
        --jq '[.[].commit.committer.date] | sort | last // empty' 2>/dev/null || true
    }

    while true; do
      prs="$($GH pr list --search "review-requested:@me" \
        --json number,title,url,updatedAt,repository \
        --limit 100 2>/dev/null || echo "[]")"

      pr_count="$(echo "$prs" | $JQ 'length')"

      new_state=""
      output=""

      for i in $(seq 0 $((pr_count - 1))); do
        pr="$(echo "$prs" | $JQ -r ".[$i]")"
        number="$(echo "$pr" | $JQ -r '.number')"
        title="$(echo "$pr" | $JQ -r '.title')"
        url="$(echo "$pr" | $JQ -r '.url')"
        repo="$(echo "$pr" | $JQ -r '.repository.nameWithOwner // .repository.name // "unknown"')"

        owner_repo="$repo"
        updated_flag=""

        last_activity="$(get_user_last_activity "$owner_repo" "$number")"
        latest_push="$(get_latest_push "$owner_repo" "$number")"

        if [[ -n "$last_activity" && -n "$latest_push" && "$latest_push" > "$last_activity" ]]; then
          updated_flag=" [UPDATED]"
        fi

        state_entry="$repo#$number$updated_flag"
        new_state="$new_state$state_entry"$'\n'

        output="$output  $repo #$number: $title$updated_flag"$'\n'
        output="$output  $url"$'\n'
        output="$output"$'\n'
      done

      new_state="$(echo "$new_state" | $SORT)"

      # Clear screen and render
      clear
      echo "=== PR Review Dashboard ==="
      echo "Updated: $($DATE '+%Y-%m-%d %H:%M:%S')"
      echo "Open reviews: $pr_count"
      echo ""

      if [[ "$pr_count" -eq 0 ]]; then
        echo "  No PRs awaiting your review."
      else
        printf '%s' "$output"
      fi

      # Diff detection
      if [[ -f "$STATE_FILE" ]]; then
        old_state="$(cat "$STATE_FILE")"
        if [[ "$new_state" != "$old_state" ]]; then
          $NOTIFY -u normal "PR Dashboard" "Review queue has changed ($pr_count open)"
        fi
      fi

      echo "$new_state" > "$STATE_FILE"

      $SLEEP 60
    done
  '';
in
{
  options.modules.pr-dashboard.enable = lib.mkEnableOption "pr-dashboard";

  config = lib.mkIf cfg.enable {
    home.packages = [ pr-dashboard ];
  };
}
