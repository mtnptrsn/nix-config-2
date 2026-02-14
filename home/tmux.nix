{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    prefix = "C-s";
    baseIndex = 1;
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
        '';
      }
    ];
  };
}
