{ pkgs, ... }:
{
  modules = {
    nixvim.enable = true;
    alacritty.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    gnome.enable = true;
    git.enable = true;
    firefox.enable = true;
    hyprland.enable = true;
    waybar.enable = true;
  };

  home.packages = with pkgs; [
    wowup-cf
  ];

  programs.git.settings.user.email = "mtnptrsn@gmail.com";

  # programs.claude-code = {
  #   enable = true;
  #   memory.text = builtins.readFile ./claude-memory.md;
  # };

}
