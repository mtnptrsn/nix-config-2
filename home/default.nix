{ ... }:
{
  imports = [
    ./modules/theme.nix
    ./modules/nixvim
    ./modules/alacritty.nix
    ./modules/zsh.nix
    ./modules/tmux.nix
    ./modules/gnome.nix
    ./modules/git.nix
    ./modules/lazygit.nix
    ./modules/packages.nix
    ./modules/linux-packages.nix
    ./modules/firefox.nix
    ./modules/dictation.nix
    ./modules/tts.nix
    ./modules/homeassistant.nix
    ./modules/vscode.nix
    ./modules/codediff.nix
    ./modules/claude
    ./modules/tea
  ];

  home.stateVersion = "25.11";
}
