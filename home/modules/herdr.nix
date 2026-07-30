{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.herdr;
in
{
  options.modules.herdr.enable = lib.mkEnableOption "herdr";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.herdr ];

    # Navigate mode (prefix+w): hjkl walks the workspace list and panes,
    # arrows move between panes.
    xdg.configFile."herdr/config.toml".text = ''
      [keys]
      navigate_workspace_up = "k"
      navigate_workspace_down = "j"
      navigate_pane_up = "up"
      navigate_pane_down = "down"
    '';
  };
}
