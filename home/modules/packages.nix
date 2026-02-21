{ pkgs, ... }:
let
  cw = pkgs.writeShellScriptBin "cw" (builtins.readFile ../scripts/cw.sh);
in
{
  home.packages = [
    cw
  ]
  ++ (with pkgs; [
    # communication
    discord
    slack

    # media
    spotify
    transmission_4-gtk
    rqbit

    # development
    vscode
    gh
    ripgrep
    fd
    statix
    nixfmt
    nodejs

    # launchers
    wofi

    # utilities
    parallel
    _1password-gui
    zoxide
    xclip
    mission-center
    geekbench
  ]);
}
