_: {
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users.mtnptrsn = {
    home = "/Users/mtnptrsn";
  };

  system.stateVersion = 4;
}
