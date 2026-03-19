{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.lazygit;
  catppuccin = pkgs.catppuccin.override { variant = "mocha"; };
in
{
  options.modules.lazygit.enable = lib.mkEnableOption "lazygit";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.delta ];

    programs.bat = {
      enable = true;
      config.theme = "catppuccin-mocha";
      themes.catppuccin-mocha.src = "${catppuccin}/bat";
    };

    programs.lazygit = {
      enable = true;
      settings.git.pagers = [
        {
          pager = "delta --dark --paging=never --syntax-theme 'Catppuccin Mocha'";
          colorArg = "always";
        }
      ];
      settings.gui.theme = {
        activeBorderColor = [
          "#a6e3a1"
          "bold"
        ];
        inactiveBorderColor = [ "#a6adc8" ];
        optionsTextColor = [ "#89b4fa" ];
        selectedLineBgColor = [ "#313244" ];
        cherryPickedCommitBgColor = [ "#45475a" ];
        cherryPickedCommitFgColor = [ "#a6e3a1" ];
        unstagedChangesColor = [ "#f38ba8" ];
        defaultFgColor = [ "#cdd6f4" ];
        searchingActiveBorderColor = [ "#f9e2af" ];
      };
    };
  };
}
