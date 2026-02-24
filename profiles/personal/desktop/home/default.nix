{ pkgs, ... }:
{
  modules = {
    # Development tools
    claude.enable = true;
    nixvim.enable = true;
    vscode.enable = true;
    codediff.enable = true;

    # Terminal and shell
    alacritty.enable = true;
    zsh.enable = true;
    tmux.enable = true;

    # Desktop environment
    gnome.enable = true;

    # Version control
    git.enable = true;

    # Applications
    firefox.enable = true;
    dictation.enable = true;
    homeassistant.enable = true;

    # Package management
    packages.enable = true;
    linux-packages.enable = true;
  };

  home.packages = with pkgs; [
    wowup-cf
  ];

  programs.git.settings.user.email = "mtnptrsn@gmail.com";
}
