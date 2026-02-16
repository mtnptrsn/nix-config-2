{ pkgs, ... }:
{
  home.packages = with pkgs; [
    google-chrome
    discord
    _1password-gui
    spotify
    zoxide
    slack
    geekbench
    transmission_4-gtk
    rqbit
    vscode
    ripgrep
    fd
    statix
    nixfmt
    mission-center
    xclip
    gh
  ];
}
