{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./cooling.nix
  ];

  networking.hostName = "mtnptrsn";
  environment.systemPackages = [ pkgs.cowsay ];

  # Gaming
  programs.steam.enable = true;
  programs.gamemode.enable = true;
}
