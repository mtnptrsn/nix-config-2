{ pkgs, ... }:
{
  home.packages = with pkgs; [
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

    # utilities
    _1password-gui
    zoxide
    xclip
    mission-center
    geekbench
  ];
}
