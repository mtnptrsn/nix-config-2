_: {
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Managed by the Determinate Nix installer
  nix.enable = false;

  users.users.mtnptrsn = {
    home = "/Users/mtnptrsn";
  };

  system.stateVersion = 4;
}
