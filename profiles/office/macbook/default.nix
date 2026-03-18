_: {
  networking.hostName = "office-macbook";

  # Nix installer uses GID 350, but nix-darwin defaults to 30000.
  # Set explicitly to match the actual system value.
  ids.gids.nixbld = 350;

  # Archicad CEF remote debugging (http://localhost:9222)
  system.defaults.CustomUserPreferences."com.graphisoft.debug".DG = {
    CefUseFixedDebugPort = true;
    CefDebugPort = 9222;
  };

  homebrew.casks = [
    "google-chrome"
  ];
}
