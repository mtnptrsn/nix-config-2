_: {
  networking.hostName = "office-macbook";

  # VPN into the personal desktop (herdr server)
  services.tailscale.enable = true;

  # Nix installer uses GID 350, but nix-darwin defaults to 30000.
  # Set explicitly to match the actual system value.
  ids.gids.nixbld = 350;

  # Dark appearance for native macOS apps (Finder, Chrome, Slack, VS Code, ...)
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";

  # Archicad CEF remote debugging (http://localhost:9222)
  system.defaults.CustomUserPreferences."com.graphisoft.debug".DG = {
    CefUseFixedDebugPort = true;
    CefDebugPort = 9222;
  };

  homebrew.casks = [
    "google-chrome"
    "whatsapp"
  ];
}
