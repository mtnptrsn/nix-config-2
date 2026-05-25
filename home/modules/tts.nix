{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.tts;
  overlayPidfile = "/tmp/tts-overlay.pid";
  pidfile = "/tmp/tts.pid";

  en-core-web-sm = pkgs.python313Packages.buildPythonPackage {
    pname = "en_core_web_sm";
    version = "3.8.0";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl";
      hash = "sha256-GTJCnbcn1L/z3u1rNM/AXfF3lPSlLusmz4ko98Gg+4U=";
    };
    dependencies = [ pkgs.python313Packages.spacy ];
    doCheck = false;
  };

  pythonEnv = pkgs.python313.withPackages (ps: [
    ps.kokoro
    en-core-web-sm
  ]);

  kokoroScript = pkgs.writeText "kokoro-tts.py" ''
    import sys
    import numpy as np
    from kokoro import KPipeline

    text = sys.stdin.read().strip()
    if not text:
        sys.exit(0)

    pipeline = KPipeline(lang_code='a', device='cpu')
    for result in pipeline(text, voice='af_heart'):
        if result.audio is not None:
            audio = result.audio.numpy()
            audio_int16 = (audio * 32767).clip(-32768, 32767).astype(np.int16)
            sys.stdout.buffer.write(audio_int16.tobytes())
  '';

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

  tts-download-model = pkgs.writeShellScriptBin "tts-download-model" ''
    set -euo pipefail
    echo "Pre-warming Kokoro model cache (downloads ~80MB on first run)..."
    echo "Hello" | ${pythonEnv}/bin/python ${kokoroScript} > /dev/null
    echo "Done."
  '';

  speak = pkgs.writeShellScriptBin "speak" ''
    set -euo pipefail

    PIDFILE="${pidfile}"

    if [ -f "$PIDFILE" ]; then
      kill "$(cat "$PIDFILE")" 2>/dev/null || true
      rm -f "$PIDFILE"
      ${kill-overlay}
      exit 0
    fi

    text=$(${pkgs.wl-clipboard}/bin/wl-paste --primary --no-newline 2>/dev/null || true)
    [ -z "$text" ] && exit 0

    ${show-overlay "Reading..."}

    echo "$text" | ${pythonEnv}/bin/python ${kokoroScript} 2>/dev/null \
      | ${pkgs.sox}/bin/play -q -t raw -r 24000 -e signed-integer -b 16 -c 1 - 2>/dev/null &
    PLAY_PID=$!
    echo $PLAY_PID >"$PIDFILE"

    (
      while [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; do
        sleep 0.5
      done
      ${kill-overlay}
      rm -f "$PIDFILE"
    ) &
  '';
in
{
  options.modules.tts.enable = lib.mkEnableOption "tts";

  config = lib.mkIf cfg.enable {
    home.packages = [
      speak
      tts-download-model
    ]
    ++ (with pkgs; [
      sox
      wl-clipboard
      yad
    ]);

    dconf.settings = lib.mkIf config.modules.gnome.enable {
      "org/gnome/settings-daemon/plugins/media-keys" = {
        # Owns the full custom-keybindings list - includes dictation paths when that module is also enabled
        custom-keybindings =
          lib.optionals config.modules.dictation.enable [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dictation/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dictation-cancel/"
          ]
          ++ [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/tts/"
          ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/tts" = {
        name = "Speak selection";
        command = "${speak}/bin/speak";
        binding = "<Control><Shift>f";
      };
    };
  };
}
