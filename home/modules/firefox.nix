{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.firefox;
in
{
  options.modules.firefox.enable = lib.mkEnableOption "firefox";

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      policies.ExtensionSettings = {
        "@react-devtools" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/react-devtools/latest.xpi";
        };
      };
    };
  };
}
