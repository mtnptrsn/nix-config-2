{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.dictation;
  dictate = pkgs.writeShellScriptBin "dictate" ''
    set -euo pipefail

    PIDFILE=/tmp/dictation.pid
    WAVFILE=/tmp/dictation.wav
    MODEL="''${WHISPER_MODEL:-$HOME/.local/share/whisper/ggml-small.bin}"

    if [ ! -f "$MODEL" ]; then
      echo "Whisper model not found at $MODEL" >&2
      exit 1
    fi

    if [ -f "$PIDFILE" ]; then
      pid=$(cat "$PIDFILE")
      rm -f "$PIDFILE"
      ${pkgs.sox}/bin/play -qn synth 0.15 sine 440 pad 0 0.85 repeat - vol 0.1 2>/dev/null &
      LOADING_PID=$!
      sleep 1
      kill "$pid" 2>/dev/null || true
      sleep 0.2

      text=$(${pkgs.whisper-cpp}/bin/whisper-cli -m "$MODEL" -f "$WAVFILE" -np -nt 2>/dev/null | sed 's/^[[:space:]]*//' | tr -d '\n')

      kill $LOADING_PID 2>/dev/null || true
      ${pkgs.sox}/bin/play -qn synth 0.15 sine 880 vol 0.1 2>/dev/null &

      echo -n "$text" | ${pkgs.wl-clipboard}/bin/wl-copy
      sleep 0.1
      ${pkgs.ydotool}/bin/ydotool key 29:1 47:1 47:0 29:0
    else
      ${pkgs.sox}/bin/play -qn synth 0.1 sine 880 vol 0.1 2>/dev/null &
      ${pkgs.sox}/bin/rec -r 16000 -c 1 -b 16 "$WAVFILE" &
      echo $! >"$PIDFILE"
    fi
  '';
in
{
  options.modules.dictation.enable = lib.mkEnableOption "dictation";

  config = lib.mkIf cfg.enable {
    home.packages = [
      dictate
    ]
    ++ (with pkgs; [
      whisper-cpp
      sox
      ydotool
      wl-clipboard
    ]);

    dconf.settings = lib.mkIf config.modules.gnome.enable {
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dictation/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dictation" = {
        name = "Toggle dictation";
        command = "${dictate}/bin/dictate";
        binding = "<Control><Shift>d";
      };
    };

    home.activation.downloadWhisperModel = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      model_dir="$HOME/.local/share/whisper"
      model_file="$model_dir/ggml-small.bin"
      if [ ! -f "$model_file" ]; then
        echo "Downloading whisper small model..."
        mkdir -p "$model_dir"
        ${pkgs.whisper-cpp}/bin/whisper-cpp-download-ggml-model small "$model_dir"
      fi
    '';

    systemd.user.services.ydotoold = {
      Unit.Description = "ydotool daemon";
      Unit.After = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${pkgs.ydotool}/bin/ydotoold";
        Restart = "always";
        Environment = "XKB_DEFAULT_LAYOUT=se";
      };
    };
  };
}
