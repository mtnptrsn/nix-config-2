{ ... }:

{
  imports = [
    ./boot.nix
    ./locale.nix
    ./desktop.nix
    ./audio.nix
    ./hardware.nix
    ./gaming.nix
    ./users.nix
  ];

  # Networking
  networking.networkmanager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "25.11";
}
