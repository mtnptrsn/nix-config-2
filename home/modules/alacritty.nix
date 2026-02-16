{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.alacritty;
in
{
  options.modules.alacritty.enable = lib.mkEnableOption "alacritty";

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings.font.size = 13.5;
      settings.colors = {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
          dim_foreground = "#cdd6f4";
        };
        cursor = {
          text = "#1e1e2e";
          cursor = "#f5e0dc";
        };
        selection = {
          text = "CellForeground";
          background = "#585b70";
        };
        search.matches = {
          foreground = "#1e1e2e";
          background = "#a6adc8";
        };
        normal = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };
        bright = {
          black = "#585b70";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#a6adc8";
        };
      };
    };
  };
}
