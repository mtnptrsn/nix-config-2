{ pkgs, ... }:
{
  modules = {
    nixvim.enable = true;
    alacritty.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    gnome.enable = true;
    git.enable = true;
    packages.enable = true;
    vscode.enable = true;
    linux-packages.enable = true;
    firefox.enable = true;
    dictation.enable = true;
  };

  home.packages = with pkgs; [
    wowup-cf
  ];

  programs.git.settings.user.email = "mtnptrsn@gmail.com";
}
