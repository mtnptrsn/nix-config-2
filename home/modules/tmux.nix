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
        # Vi keybindings in copy mode
        set-window-option -g mode-keys vi

        # Pane navigation (hjkl)
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Open new panes/windows in the current directory
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        # Pane resizing (HJKL)
        bind H resize-pane -L 15
        bind J resize-pane -D 15
        bind K resize-pane -U 15
        bind L resize-pane -R 15

        # 4-pane grid layout
        bind g split-window -h -c "#{pane_current_path}" \; split-window -v -c "#{pane_current_path}" \; select-pane -t 1 \; split-window -v -c "#{pane_current_path}" \; select-layout tiled

        # Pane borders
        set -g pane-border-lines heavy
        set -g pane-border-style "fg=colour8"
        set -g pane-active-border-style "fg=colour4"

        # Dim inactive panes
        set -g window-style "dim"
        set -g window-active-style "nodim"

        # Status bar
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
