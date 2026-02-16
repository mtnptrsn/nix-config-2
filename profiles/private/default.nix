{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  networking.hostName = "mtnptrsn";
  environment.systemPackages = [ pkgs.cowsay ];
}
