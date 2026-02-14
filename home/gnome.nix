{ config, ... }:
{
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
}
