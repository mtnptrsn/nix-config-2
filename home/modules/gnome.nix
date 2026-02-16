{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.gnome;
in
{
  options.modules.gnome.enable = lib.mkEnableOption "gnome";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      gnomeExtensions.maximized-by-default-actually-reborn
    ];

    dconf.settings = {
      "org/gnome/shell" = {
        enabled-extensions = [
          "gnome-shell-extension-maximized-by-default@stiggimy.github.com"
        ];
      };
      "org/gnome/desktop/peripherals/mouse" = {
        accel-profile = "flat"; # Disable GNOME acceleration; maccel handles it
      };
      "org/gnome/desktop/interface" = {
        enable-animations = false;
        color-scheme = "prefer-dark";
        gtk-theme = "Adwaita-dark";
      };
      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Control>q" ];
      };
      "org/gnome/desktop/background" = {
        picture-uri = "file://${config.home.homeDirectory}/Pictures/wallpaper.jpg";
        picture-uri-dark = "file://${config.home.homeDirectory}/Pictures/wallpaper.jpg";
        picture-options = "zoom";
      };
    };
  };
}
