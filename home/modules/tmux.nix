{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.tmux;
in
{
  options.modules.tmux.enable = lib.mkEnableOption "tmux";

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      prefix = "C-s";
      baseIndex = 1;
      extraConfig = ''
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R
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
  };
}
