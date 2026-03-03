_: {
  networking.hostName = "office-macbook";

  # Nix installer uses GID 350, but nix-darwin defaults to 30000.
  # Set explicitly to match the actual system value.
  ids.gids.nixbld = 350;

  homebrew.casks = [
    "google-chrome"
  ];
}
