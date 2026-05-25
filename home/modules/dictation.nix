{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.dictation;
  overlayPidfile = "/tmp/dictation-overlay.pid";
  modelDir = "$HOME/.local/share/whisper";
  modelPath = "${modelDir}/ggml-large-v3.bin";
  modelUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin";

  kill-overlay = ''
    if [ -f "${overlayPidfile}" ]; then
      kill "$(cat "${overlayPidfile}")" 2>/dev/null || true
      rm -f "${overlayPidfile}"
    fi
  '';

  show-overlay = text: ''
    ${kill-overlay}
    GDK_BACKEND=x11 ${pkgs.yad}/bin/yad --text="${text}" --no-buttons --undecorated --skip-taskbar --on-top --sticky --fixed --geometry=-20-20 &
    echo $! >"${overlayPidfile}"
  '';

  dictate-download-model = pkgs.writeShellScriptBin "dictate-download-model" ''
    set -euo pipefail
    MODEL_DIR="${modelDir}"
    MODEL_PATH="${modelPath}"
    MODEL_URL="${modelUrl}"
    if [ -f "$MODEL_PATH" ]; then
      echo "Model already exists at $MODEL_PATH"
      exit 0
    fi
    mkdir -p "$MODEL_DIR"
    echo "Downloading whisper model to $MODEL_PATH..."
    ${pkgs.curl}/bin/curl -L -o "$MODEL_PATH" "$MODEL_URL"
    echo "Done."
  '';

  dictate = pkgs.writeShellScriptBin "dictate" ''
    set -euo pipefail

    PIDFILE=/tmp/dictation.pid
    WAVFILE=/tmp/dictation.wav
    MODEL_PATH="${modelPath}"

    if [ ! -f "$MODEL_PATH" ]; then
      mkdir -p "${modelDir}"
      ${pkgs.curl}/bin/curl -L -o "$MODEL_PATH" "${modelUrl}"
    fi

    if [ -f "$PIDFILE" ]; then
      pid=$(cat "$PIDFILE")
      rm -f "$PIDFILE"
      ${show-overlay "Dictation: Processing"}
      ${pkgs.sox}/bin/play -qn synth 0.15 sine 440 pad 0 0.85 repeat - vol 0.1 2>/dev/null &
      LOADING_PID=$!
      sleep 1
      kill "$pid" 2>/dev/null || true
      sleep 0.2

      text=$(${pkgs.whisper-cpp-vulkan}/bin/whisper-cli -m "$MODEL_PATH" -f "$WAVFILE" --language auto --no-timestamps -np 2>/dev/null)
      text="''${text#"''${text%%[![:space:]]*}"}"

      kill $LOADING_PID 2>/dev/null || true
      ${kill-overlay}
      ${pkgs.sox}/bin/play -qn synth 0.15 sine 880 vol 0.1 2>/dev/null &

      echo -n "$text" | ${pkgs.wl-clipboard}/bin/wl-copy
      sleep 0.1
      ${pkgs.ydotool}/bin/ydotool key 29:1 47:1 47:0 29:0
    else
      ${pkgs.sox}/bin/play -qn synth 0.1 sine 880 vol 0.1 2>/dev/null &
      ${pkgs.sox}/bin/rec -r 16000 -c 1 -b 16 "$WAVFILE" &
      echo $! >"$PIDFILE"
      ${show-overlay "Dictation: Recording"}
    fi
  '';

  dictate-cancel = pkgs.writeShellScriptBin "dictate-cancel" ''
    set -euo pipefail

    PIDFILE=/tmp/dictation.pid
    WAVFILE=/tmp/dictation.wav

    if [ -f "$PIDFILE" ]; then
      pid=$(cat "$PIDFILE")
      rm -f "$PIDFILE"
      kill "$pid" 2>/dev/null || true
      rm -f "$WAVFILE"
      ${kill-overlay}
      ${pkgs.sox}/bin/play -qn synth 0.3 sine 200 vol 0.1 2>/dev/null &
    fi

    if [ -f "/tmp/tts.pid" ]; then
      kill "$(cat "/tmp/tts.pid")" 2>/dev/null || true
      rm -f "/tmp/tts.pid"
    fi
    if [ -f "/tmp/tts-overlay.pid" ]; then
      kill "$(cat "/tmp/tts-overlay.pid")" 2>/dev/null || true
      rm -f "/tmp/tts-overlay.pid"
    fi
  '';
in
{
  options.modules.dictation.enable = lib.mkEnableOption "dictation";

  config = lib.mkIf cfg.enable {
    home.packages = [
      dictate
      dictate-cancel
      dictate-download-model
    ]
    ++ (with pkgs; [
      sox
      ydotool
      wl-clipboard
      yad
    ]);

    dconf.settings = lib.mkIf config.modules.gnome.enable {
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dictation" = {
        name = "Toggle dictation";
        command = "${dictate}/bin/dictate";
        binding = "<Control><Shift>d";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dictation-cancel" = {
        name = "Cancel dictation";
        command = "${dictate-cancel}/bin/dictate-cancel";
        binding = "<Control><Shift>x";
      };
    };

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
