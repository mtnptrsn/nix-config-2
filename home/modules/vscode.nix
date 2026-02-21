{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.vscode;
in
{
  options.modules.vscode.enable = lib.mkEnableOption "vscode";

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        eamodio.gitlens
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint
        anthropic.claude-code
      ];
    };
  };
}
