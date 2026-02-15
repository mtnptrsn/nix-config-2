{ pkgs, ... }:

{
  imports = [
    ./nixvim.nix
    ./alacritty.nix
    ./zsh.nix
    ./tmux.nix
    ./gnome.nix
  ];

  home.stateVersion = "25.11";

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
  ];

  programs.firefox.enable = true;

  programs.mangohud.enable = true;

  programs.git = {
    enable = true;
    settings.user.name = "Mårten Pettersson";
    settings.user.email = "mtnptrsn@gmail.com";
    settings.init.defaultBranch = "main";
    settings.pull.rebase = true;
    settings.push.autoSetupRemote = true;
  };
}
