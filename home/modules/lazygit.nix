{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.lazygit;
  isLight = config.modules.theme == "light";

  # bat ships Catppuccin Latte/Mocha as built-in themes; delta reuses bat's
  # theme registry, so the same name works for its --syntax-theme.
  catppuccinTheme = if isLight then "Catppuccin Latte" else "Catppuccin Mocha";

  # Catppuccin Mocha (dark) / Latte (light) GUI colors, mapped by palette role.
  guiTheme =
    if isLight then
      {
        activeBorderColor = [
          "#40a02b" # green
          "bold"
        ];
        inactiveBorderColor = [ "#6c6f85" ]; # subtext0
        optionsTextColor = [ "#1e66f5" ]; # blue
        selectedLineBgColor = [ "#ccd0da" ]; # surface0
        cherryPickedCommitBgColor = [ "#bcc0cc" ]; # surface1
        cherryPickedCommitFgColor = [ "#40a02b" ]; # green
        unstagedChangesColor = [ "#d20f39" ]; # red
        defaultFgColor = [ "#4c4f69" ]; # text
        searchingActiveBorderColor = [ "#df8e1d" ]; # yellow
      }
    else
      {
        activeBorderColor = [
          "#a6e3a1" # green
          "bold"
        ];
        inactiveBorderColor = [ "#a6adc8" ]; # subtext0
        optionsTextColor = [ "#89b4fa" ]; # blue
        selectedLineBgColor = [ "#313244" ]; # surface0
        cherryPickedCommitBgColor = [ "#45475a" ]; # surface1
        cherryPickedCommitFgColor = [ "#a6e3a1" ]; # green
        unstagedChangesColor = [ "#f38ba8" ]; # red
        defaultFgColor = [ "#cdd6f4" ]; # text
        searchingActiveBorderColor = [ "#f9e2af" ]; # yellow
      };
in
{
  options.modules.lazygit.enable = lib.mkEnableOption "lazygit";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.delta ];

    programs.bat = {
      enable = true;
      config.theme = catppuccinTheme;
    };

    programs.lazygit = {
      enable = true;
      settings.git.pagers = [
        {
          pager = "delta --${if isLight then "light" else "dark"} --paging=never --syntax-theme '${catppuccinTheme}'";
          colorArg = "always";
        }
      ];
      settings.gui.theme = guiTheme;
    };
  };
}
