{ lib, ... }:
{
  networking.hostName = "office-macbook";

  homebrew.casks = lib.mkForce [
    "1password"
    "slack"
    "spotify"
  ];
}
