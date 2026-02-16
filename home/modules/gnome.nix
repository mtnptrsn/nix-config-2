{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.gnome;
in
{
  options.modules.gnome.enable = lib.mkEnableOption "gnome";

  config = lib.mkIf cfg.enable {
    services.devilspie2 = {
      enable = true;
      config = ''
        maximize()
      '';
    };

    dconf.settings = {
      "org/gnome/shell" = {
        enabled-extensions = [ "hidetopbar@mathieu.bidon.ca" ];
      };
      "org/gnome/shell/extensions/hidetopbar" = {
        enable-intellihide = false;
      };
      "org/gnome/desktop/peripherals/mouse" = {
        accel-profile = "flat"; # Disable GNOME acceleration; maccel handles it
      };
      "org/gnome/desktop/interface" = {
        enable-animations = false;
        color-scheme = "prefer-dark";
        gtk-theme = "Adwaita-dark";
      };
      "org/gnome/desktop/background" = {
        picture-uri = "file://${config.home.homeDirectory}/Pictures/wallpaper.jpg";
        picture-uri-dark = "file://${config.home.homeDirectory}/Pictures/wallpaper.jpg";
        picture-options = "zoom";
      };
    };
  };
}
