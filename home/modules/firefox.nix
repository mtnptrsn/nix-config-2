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
      profiles.default = {
        settings = {
          "layout.css.prefers-color-scheme.content-override" = 0;
        };
      };
      policies.ExtensionSettings = {
        "@react-devtools" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/react-devtools/latest.xpi";
        };
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
        };
      };
    };
  };
}
