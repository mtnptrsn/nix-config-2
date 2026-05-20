{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.lazygit;

  catppuccin-mocha-tmtheme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/bat/refs/heads/main/themes/Catppuccin%20Mocha.tmTheme";
    name = "catppuccin-mocha.tmTheme";
    hash = "sha256-OVVm8IzrMBuTa5HAd2kO+U9662UbEhVT8gHJnCvUqnc=";
  };

  deltaCmd = "${pkgs.delta}/bin/delta --dark --paging=never --syntax-theme='Catppuccin Mocha'";
in
{
  options.modules.lazygit.enable = lib.mkEnableOption "lazygit";

  config = lib.mkIf cfg.enable {
    programs.lazygit = {
      enable = true;
      settings = {
        git.pagers = [
          {
            command = "diff";
            arg = deltaCmd;
          }
          {
            command = "show";
            arg = deltaCmd;
          }
        ];
        gui.theme = {
          activeBorderColor = [ "#a6e3a1" "bold" ];
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

    xdg.configFile."bat/themes/Catppuccin Mocha.tmTheme".source = catppuccin-mocha-tmtheme;

    home.activation.batCacheBuild = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.bat}/bin/bat cache --build > /dev/null 2>&1 || true
    '';
  };
}
