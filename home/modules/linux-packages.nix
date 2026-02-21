{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.linux-packages;
in
{
  options.modules.linux-packages.enable = lib.mkEnableOption "linux-packages";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # communication
      discord
      slack

      # media
      spotify
      transmission_4-gtk
      rqbit

      # game development
      godot_4

      # development
      vscode

      # launchers
      wofi

      # utilities
      _1password-gui
      xclip
      mission-center
      geekbench
    ];
  };
}
