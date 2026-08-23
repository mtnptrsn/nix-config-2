{ ... }:

{
  imports = [
    ./boot.nix
    ./locale.nix
    ./desktop.nix
    ./audio.nix
    ./hardware.nix
    ./users.nix
    ./tailscale.nix
    ./mcp-funnel.nix
  ];

  # Networking
  networking.networkmanager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19"
  ];

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

  # Run dynamically linked executables
  programs.nix-ld.enable = true;

  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
  '';

  system.stateVersion = "25.11";
}
