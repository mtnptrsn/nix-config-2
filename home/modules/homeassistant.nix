{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.homeassistant;

  # Temporary hardcoded values — safe since HA is on local network only, not exposed externally
  ha-url = "http://192.168.1.92:8123";
  ha-token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIzMjE0ZTJiYmVhNTk0ZWNmYTQ3MWQwZDRhY2RkYzkzOCIsImlhdCI6MTc3MTk2Nzk2NSwiZXhwIjoyMDg3MzI3OTY1fQ.LQmc4zbSZ8GBVtqwDlbZQNIJJoI4QLXIDV_7Yx29XfM";
  ha-entity = "light.all_lights";

  curl = "${pkgs.curl}/bin/curl";

  lights-full = pkgs.writeShellScriptBin "lights-full" ''
    ${curl} -s -X POST "${ha-url}/api/services/light/turn_on" \
      -H "Authorization: Bearer ${ha-token}" \
      -H "Content-Type: application/json" \
      -d '{"entity_id": "${ha-entity}", "brightness_pct": 100}'
  '';

  lights-dim = pkgs.writeShellScriptBin "lights-dim" ''
    ${curl} -s -X POST "${ha-url}/api/services/light/turn_on" \
      -H "Authorization: Bearer ${ha-token}" \
      -H "Content-Type: application/json" \
      -d '{"entity_id": "${ha-entity}", "brightness_pct": 20}'
  '';

  lights-off = pkgs.writeShellScriptBin "lights-off" ''
    ${curl} -s -X POST "${ha-url}/api/services/light/turn_off" \
      -H "Authorization: Bearer ${ha-token}" \
      -H "Content-Type: application/json" \
      -d '{"entity_id": "${ha-entity}"}'
  '';
in
{
  options.modules.homeassistant.enable = lib.mkEnableOption "homeassistant";

  config = lib.mkIf cfg.enable {
    home.packages = [
      lights-full
      lights-dim
      lights-off
      pkgs.curl
    ];

    xdg.desktopEntries = {
      lights-full = {
        name = "Lights: 100%";
        exec = "${lights-full}/bin/lights-full";
        terminal = false;
        type = "Application";
        noDisplay = false;
      };
      lights-dim = {
        name = "Lights: 20%";
        exec = "${lights-dim}/bin/lights-dim";
        terminal = false;
        type = "Application";
        noDisplay = false;
      };
      lights-off = {
        name = "Lights: Off";
        exec = "${lights-off}/bin/lights-off";
        terminal = false;
        type = "Application";
        noDisplay = false;
      };
    };
  };
}
