{ ... }:
{
  imports = [
    ./modules/nixvim.nix
    ./modules/alacritty.nix
    ./modules/zsh.nix
    ./modules/tmux.nix
    ./modules/gnome.nix
    ./modules/git.nix
    ./modules/packages.nix
    ./modules/pr-dashboard.nix
  ];

  home.stateVersion = "25.11";
}
