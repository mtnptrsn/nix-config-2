{ pkgs, ... }:

{
  # GNOME Desktop Environment
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "mtnptrsn";
  services.desktopManager.gnome.enable = true;

  # Printing
  services.printing.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
