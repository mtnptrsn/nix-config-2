{ pkgs, ... }:

{
  home.packages = [ pkgs.discord ];

  xdg.configFile."discord/settings.json".text = builtins.toJSON {
    SKIP_HOST_UPDATE = true;
  };
}
