{ pkgs, ... }:
let
  gwco = pkgs.writeShellScriptBin "gwco" (builtins.readFile ../scripts/gwco.sh);
  cwstart = pkgs.writeShellScriptBin "cwstart" (builtins.readFile ../scripts/cwstart.sh);
in
{
  home.packages = [
    gwco
    cwstart
  ]
  ++ (with pkgs; [
    # browsers
    google-chrome

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

    # launchers
    wofi

    # utilities
    _1password-gui
    zoxide
    xclip
    mission-center
    geekbench
  ]);
}
