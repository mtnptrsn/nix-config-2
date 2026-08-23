# Garmin MCP server, exposed over Tailscale Funnel behind a secret URL path.
#
# There is no OAuth: the only gate is a high-entropy path segment read from
# /var/lib/garmin-mcp/funnel-path (root-only, and deliberately outside git and
# the nix store). tailscaled serves that prefix and 404s everything else, so
# scanners that find this hostname in Certificate Transparency logs never reach
# the server. The tool set is also restricted to reads bar one.
#
# Clients need no credentials beyond the URL itself:
#
#   claude mcp add --transport http garmin https://<host>/<secret>/mcp
#
# The image is built out-of-band with `just garmin-image` -- nix does not build
# it, because upstream is a git-only Python package.
{ config, ... }:
let
  port = 8765;
  stateDir = "/var/lib/garmin-mcp";
  pathFile = "${stateDir}/funnel-path";
  image = "garmin-mcp:local";

  docker = "${config.virtualisation.docker.package}/bin/docker";

  # Near-read-only allowlist. Upstream registers 110+ tools by default,
  # including ones that upload workouts, edit activities, log weight and food,
  # and delete courses. With the secret URL as the only gate, anyone holding it
  # inherits whatever is listed here, so every addition widens the blast radius
  # of a leaked URL.
  #
  # set_activity_description is the single deliberate exception -- see the note
  # next to it below.
  #
  # Also excluded, though not strictly writes: request_reload (asks Garmin to
  # re-sync), set_fit_download_dir (mutates server state), and the download_*
  # tools (write to a filesystem the container mounts read-only).
  enabledTools = [
    # activity_management
    "get_activities"
    "get_activities_by_date"
    "get_activities_fordate"
    "get_activity"
    "get_activity_exercise_sets"
    "get_activity_gear"
    "get_activity_hr_in_timezones"
    "get_activity_power_in_timezones"
    "get_activity_split_summaries"
    "get_activity_splits"
    "get_activity_typed_splits"
    "get_activity_types"
    "get_activity_weather"
    "count_activities"
    # The one write tool. Sets the free-text notes field on an activity, so
    # sessions can be annotated from claude.ai. Worst case with a leaked URL is
    # overwritten or cleared notes (it replaces rather than appends); the
    # activity data itself, and every other write path, stays out of reach.
    "set_activity_description"
    # health_wellness
    "get_all_day_events"
    "get_all_day_stress"
    "get_blood_pressure"
    "get_body_battery"
    "get_body_battery_events"
    "get_body_composition"
    "get_daily_steps"
    "get_floors"
    "get_heart_rates"
    "get_heart_rates_summary"
    "get_hydration_data"
    "get_lifestyle_logging_data"
    "get_morning_training_readiness"
    "get_respiration_data"
    "get_respiration_summary"
    "get_rhr_day"
    "get_sleep_data"
    "get_sleep_summary"
    "get_spo2_data"
    "get_stats"
    "get_stats_and_body"
    "get_steps_data"
    "get_stress_data"
    "get_stress_summary"
    "get_training_readiness"
    "get_user_summary"
    "get_weekly_intensity_minutes"
    "get_weekly_steps"
    "get_weekly_stress"
    # user_profile
    "get_full_name"
    "get_unit_system"
    "get_user_profile"
    "get_userprofile_settings"
    # devices
    "get_device_alarms"
    "get_device_last_used"
    "get_device_settings"
    "get_device_solar_data"
    "get_devices"
    "get_primary_training_device"
    # gear_management
    "get_gear"
    # weight_management
    "get_daily_weigh_ins"
    "get_weigh_ins"
    # challenges
    "get_adhoc_challenges"
    "get_available_badge_challenges"
    "get_badge_challenges"
    "get_earned_badges"
    "get_goals"
    "get_inprogress_virtual_challenges"
    "get_non_completed_badge_challenges"
    "get_personal_record"
    "get_race_predictions"
    # training
    "get_cycling_ftp"
    "get_endurance_score"
    "get_fitnessage_data"
    "get_hill_score"
    "get_hrv_data"
    "get_hrv_trend"
    "get_lactate_threshold"
    "get_progress_summary_between_dates"
    "get_respiration_trend"
    "get_training_effect"
    "get_training_load_balance"
    "get_training_load_trend"
    "get_training_status"
    "get_vo2max_trend"
    # workouts
    "get_garmin_coach_workouts"
    "get_scheduled_workouts"
    "get_training_plan_workouts"
    "get_workout_by_id"
    "get_workouts"
    # womens_health
    "get_menstrual_calendar_data"
    "get_menstrual_data_for_date"
    "get_pregnancy_summary"
    # nutrition
    "get_custom_food_serving_units"
    "get_custom_foods"
    "get_nutrition_daily_food_log"
    "get_nutrition_daily_meals"
    "get_nutrition_daily_settings"
    "search_foods"
    # courses
    "get_courses"
    # activity_analysis
    "get_activity_fit_data"
    "get_power_duration_curve"
  ];
in
{
  # docker itself is enabled in ./virtualization.nix.

  # The token cache must be writable -- garth refreshes tokens in place.
  # funnel-path is deliberately absent: it is created by hand so the secret
  # never passes through the nix store, and its absence should fail loudly.
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 root root -"
    "d ${stateDir}/garminconnect 0700 root root -"
  ];

  systemd.services.garmin-mcp = {
    description = "Garmin Connect MCP server";
    wantedBy = [ "multi-user.target" ];
    after = [
      "docker.service"
      "network-online.target"
    ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Restart = "always";
      RestartSec = 10;
      # A leftover container from an unclean stop would take the name and the
      # port, so clear it before starting rather than after.
      ExecStartPre = "-${docker} rm -f garmin-mcp";
      ExecStop = "-${docker} rm -f garmin-mcp";
      ExecStart = builtins.concatStringsSep " " [
        "${docker} run --rm --name garmin-mcp"
        "-p 127.0.0.1:${toString port}:${toString port}"
        "-v ${stateDir}/garminconnect:/root/.garminconnect"
        "-e GARMIN_ENABLED_TOOLS=${builtins.concatStringsSep "," enabledTools}"
        "--read-only --tmpfs /tmp"
        "--cap-drop=ALL --security-opt no-new-privileges"
        "--memory=512m --pids-limit=256"
        image
      ];
    };
  };

  # Publishing is handled by the shared nixos/mcp-funnel.nix, which serves only
  # this secret prefix and 404s everything else on the hostname. One unit owns
  # every funnel because `tailscale serve reset` is host-wide.
  services.mcpFunnel.services.garmin = { inherit port pathFile; };
}
