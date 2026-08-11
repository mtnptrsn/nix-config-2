{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.captureSync;
  localDir = "${config.home.homeDirectory}/Captures";
  logFile = "/tmp/capture-sync.log";

  # Launchd agents run with a minimal environment, so every binary is an
  # absolute path. WatchPaths fires on any change to the directory, including
  # the temp files macOS writes mid-capture, so the script has to be cheap and
  # safe to re-run.
  capture-sync = pkgs.writeShellScriptBin "capture-sync" ''
    set -euo pipefail

    LOCK=/tmp/capture-sync.lock
    mkdir "$LOCK" 2>/dev/null || exit 0
    trap 'rmdir "$LOCK"' EXIT

    # macOS writes a capture under a dot-prefixed temp name and renames it on
    # completion; wait for that rename before looking at the directory.
    sleep 1

    # Not --ignore-existing: a screen recording may still be growing when an
    # event fires, and a plain sync lets a later event correct a partial copy.
    ${pkgs.rsync}/bin/rsync -a --exclude='.*' -e /usr/bin/ssh \
      "${localDir}/" "${cfg.remoteHost}:${cfg.remoteDir}/"

    newest=$(/bin/ls -t "${localDir}" 2>/dev/null | grep -v '^\.' | head -n 1 || true)
    [ -n "$newest" ] || exit 0

    # Only hand over a path once the file has stopped changing.
    size_before=$(/usr/bin/stat -f %z "${localDir}/$newest")
    sleep 1
    size_after=$(/usr/bin/stat -f %z "${localDir}/$newest")
    [ "$size_before" = "$size_after" ] || exit 0

    printf '%s' "${cfg.remoteDir}/$newest" | /usr/bin/pbcopy
  '';
in
{
  options.modules.captureSync = {
    enable = lib.mkEnableOption "capture-sync";

    remoteHost = lib.mkOption {
      type = lib.types.str;
      default = "desktop";
      description = "SSH host to sync captures to.";
    };

    remoteDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/mtnptrsn/Captures";
      description = "Capture directory on the remote host.";
    };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.packages = [ capture-sync ];

    # Screenshots and screen recordings both follow this pref.
    targets.darwin.defaults."com.apple.screencapture".location = localDir;

    # The agent cannot watch a directory that does not exist yet.
    home.file."Captures/.keep".text = "";

    launchd.agents.capture-sync = {
      enable = true;
      config = {
        ProgramArguments = [ "${capture-sync}/bin/capture-sync" ];
        WatchPaths = [ localDir ];
        RunAtLoad = true;
        StandardOutPath = logFile;
        StandardErrorPath = logFile;
      };
    };
  };
}
