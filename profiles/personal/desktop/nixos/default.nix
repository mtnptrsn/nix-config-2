{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./cooling.nix
    ./virtualization.nix
  ];

  services.flatpak.enable = true;
  services.flatpak.packages = [ "org.freecad.FreeCAD" ];

  networking.hostName = "mtnptrsn";
  networking.extraHosts = ''
    127.0.0.1 local.finch3d.com
  '';
  # herdr is a system package so it is on PATH for non-interactive SSH sessions,
  # which is how `herdr --remote` finds the server binary.
  environment.systemPackages = [
    pkgs.cowsay
    pkgs.herdr
  ];

  # Always-on herdr server: never suspend, and keep user processes running
  # after the last session ends.
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
  users.users.mtnptrsn.linger = true;

  # Gaming
  programs.steam.enable = true;
  programs.gamemode.enable = true;
}
