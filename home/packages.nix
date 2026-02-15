{ pkgs, ... }:

{
  home.packages = with pkgs; [
    google-chrome
    discord
    _1password-gui
    spotify
    zoxide
    wowup-cf
    slack
    geekbench
    transmission_4-gtk
    rqbit
    gnomeExtensions.hide-top-bar
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
