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
    ./modules/linux-packages.nix
    ./modules/firefox.nix
    ./modules/dictation.nix
    ./modules/vscode.nix
  ];

  home.stateVersion = "25.11";
}
