{ pkgs, ... }:
{
  networking.hostName = "private";
  environment.systemPackages = [ pkgs.cowsay ];
}
