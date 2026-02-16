{ pkgs, ... }:
{
  networking.hostName = "mtnptrsn";
  environment.systemPackages = [ pkgs.lolcat ];
}
