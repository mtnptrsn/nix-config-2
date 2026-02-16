{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.waybar;
in
{
  options.modules.waybar.enable = lib.mkEnableOption "waybar";

  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          modules-left = [ "hyprland/workspaces" ];
          modules-right = [ "clock" ];

          clock = {
            format = "{:%H:%M}";
            tooltip-format = "{:%Y-%m-%d}";
          };
        };
      };
      style = ''
        * {
          font-family: monospace;
          font-size: 14px;
        }

        window#waybar {
          background-color: rgba(30, 30, 30, 0.9);
          color: #ffffff;
        }

        #workspaces button {
          padding: 0 8px;
          color: #888888;
          background: transparent;
          border: none;
        }

        #workspaces button.active {
          color: #ffffff;
        }

        #clock {
          padding: 0 12px;
        }
      '';
    };
  };
}
