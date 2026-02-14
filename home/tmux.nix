{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    prefix = "C-s";
    baseIndex = 1;
    extraConfig = ''
      set -gF status-right "#{E:@catppuccin_status_date_time}"
    '';
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_date_time_text " %H:%M"
        '';
      }
    ];
  };
}
