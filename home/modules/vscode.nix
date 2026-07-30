{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.vscode;

  colorTheme = if config.modules.theme == "light" then "Catppuccin Latte" else "Catppuccin Mocha";
in
{
  options.modules.vscode.enable = lib.mkEnableOption "vscode";

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide
          eamodio.gitlens
          esbenp.prettier-vscode
          dbaeumer.vscode-eslint
          catppuccin.catppuccin-vsc
        ];
        userSettings."workbench.colorTheme" = colorTheme;
      };
    };
  };
}
