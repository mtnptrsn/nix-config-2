{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.hyprland;
in
{
  options.modules.hyprland.enable = lib.mkEnableOption "hyprland";

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        monitor = "DP-1, 2560x1440@144, 0x0, 1";

        input = {
          kb_layout = "se";
          sensitivity = 0;
          accel_profile = "flat";
        };

        animations.enabled = false;

        "$mod" = "SUPER";

        bind = [
          "$mod, Return, exec, alacritty"
          "$mod, Q, killactive"
          "$mod, M, exit"
          "$mod, V, togglefloating"
          "$mod, F, fullscreen"
          "$mod, R, exec, wofi --show drun"

          # Move focus
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"

          # Switch workspaces
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"

          # Move window to workspace
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
        ];

        windowrule = [
          "match:class ^(Alacritty)$, workspace 1 silent"
          "match:class ^(firefox)$, workspace 2 silent"
          "match:class ^(Spotify)$, workspace 3 silent"
          "match:class ^(1password)$, workspace 4 silent"
        ];

        exec-once = [
          "waybar"
          "alacritty -e tmux new-session -A -s main"
          "firefox"
          "spotify"
          "1password"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];
      };
    };
  };
}
