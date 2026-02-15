{ pkgs, ... }:
{
  networking.hostName = "work";
  environment.systemPackages = [ pkgs.lolcat ];
}
