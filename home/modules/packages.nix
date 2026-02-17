{ pkgs, ... }:
let
  gwco = pkgs.writeShellScriptBin "gwco" (builtins.readFile ../scripts/gwco.sh);
  cwstart = pkgs.writeShellScriptBin "cwstart" (builtins.readFile ../scripts/cwstart.sh);
  gwrm = pkgs.writeShellScriptBin "gwrm" (builtins.readFile ../scripts/gwrm.sh);
  help = pkgs.writeShellScriptBin "help" (builtins.readFile ../scripts/help.sh);
in
{
  home.packages = [
    gwco
    cwstart
    gwrm
    help
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
