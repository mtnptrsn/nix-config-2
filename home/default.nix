{ ... }:
{
  imports = [
    ./modules/nixvim
    ./modules/alacritty.nix
    ./modules/zsh.nix
    ./modules/tmux.nix
    ./modules/gnome.nix
    ./modules/git.nix
    ./modules/packages.nix
    ./modules/linux-packages.nix
    ./modules/firefox.nix
    ./modules/dictation.nix
    ./modules/homeassistant.nix
    ./modules/vscode.nix
    ./modules/codediff.nix
    ./modules/claude
  ];

  home.stateVersion = "25.11";
}
