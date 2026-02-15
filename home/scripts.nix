{ pkgs, lib, ... }:

let
  ffmpeg = lib.getExe pkgs.ffmpeg;
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "record-screen" ''
      set -euo pipefail

      VIDEOS_DIR="$HOME/Videos"
      mkdir -p "$VIDEOS_DIR"

      TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
      WEBM_PATH="$VIDEOS_DIR/recording_$TIMESTAMP.webm"
      MP4_PATH="$VIDEOS_DIR/recording_$TIMESTAMP.mp4"

      stop_recording() {
        echo ""
        echo "Stopping recording..."
        gdbus call --session \
          --dest org.gnome.Shell.Screencast \
          --object-path /org/gnome/Shell/Screencast \
          --method org.gnome.Shell.Screencast.StopScreencast \
          > /dev/null 2>&1 || true

        if [ -f "$WEBM_PATH" ]; then
          echo "Converting to MP4..."
          ${ffmpeg} -i "$WEBM_PATH" \
            -c:v libx264 -preset fast -crf 23 \
            -c:a aac -b:a 128k \
            -y -loglevel warning \
            "$MP4_PATH"
          rm "$WEBM_PATH"
          echo "Saved: $MP4_PATH"
        else
          echo "No recording file found."
        fi

        exit 0
      }

      trap stop_recording SIGINT SIGTERM

      echo "Starting screen recording..."
      echo "Press Ctrl+C to stop."
      echo ""

      RESULT=$(gdbus call --session \
        --dest org.gnome.Shell.Screencast \
        --object-path /org/gnome/Shell/Screencast \
        --method org.gnome.Shell.Screencast.Screencast \
        "$WEBM_PATH" \
        "{'framerate': <30>}")

      if [[ "$RESULT" == *"true"* ]]; then
        echo "Recording: $WEBM_PATH"
        while true; do sleep 1; done
      else
        echo "Failed to start recording."
        echo "Make sure GNOME Shell is running and the Screencast D-Bus service is available."
        exit 1
      fi
    '')
  ];
}
