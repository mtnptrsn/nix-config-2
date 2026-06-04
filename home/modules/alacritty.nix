{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.alacritty;

  # Catppuccin Mocha (dark theme).
  darkTheme.colors = {
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

  # Catppuccin Latte (light counterpart to Mocha).
  lightTheme.colors = {
    primary = {
      background = "#eff1f5";
      foreground = "#4c4f69";
      dim_foreground = "#8c8fa1";
    };
    cursor = {
      text = "#eff1f5";
      cursor = "#dc8a78";
    };
    selection = {
      text = "CellForeground";
      background = "#acb0be";
    };
    search.matches = {
      foreground = "#eff1f5";
      background = "#6c6f85";
    };
    normal = {
      black = "#5c5f77";
      red = "#d20f39";
      green = "#40a02b";
      yellow = "#df8e1d";
      blue = "#1e66f5";
      magenta = "#ea76cb";
      cyan = "#179299";
      white = "#acb0be";
    };
    bright = {
      black = "#6c6f85";
      red = "#d20f39";
      green = "#40a02b";
      yellow = "#df8e1d";
      blue = "#1e66f5";
      magenta = "#ea76cb";
      cyan = "#179299";
      white = "#bcc0cc";
    };
  };

  themes = {
    dark = darkTheme;
    light = lightTheme;
  };
in
{
  options.modules.alacritty.enable = lib.mkEnableOption "alacritty";

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = themes.${config.modules.theme} // {
        font.normal.family = "JetBrainsMono Nerd Font";
        font.size = 13.5;
        keyboard.bindings = [
          {
            key = "V";
            mods = "Control";
            action = "Paste";
          }
        ];
      };
    };
  };
}
