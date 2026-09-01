{ pkgs, ... }:
let
  askpass = pkgs.writeShellScriptBin "askpass" ''
    osascript -e 'Tell application "System Events" to display dialog "Password for sudo:" with hidden answer default answer ""' -e 'text returned of result'
  '';
in
{
  # Nix
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # User
  system.primaryUser = "mtnptrsn";
  users.users.mtnptrsn = {
    home = "/Users/mtnptrsn";
  };

  # Sudo askpass (GUI password prompt)
  environment.systemPackages = [
    askpass
  ];
  environment.variables.SUDO_ASKPASS = "${askpass}/bin/askpass";

  # macOS terminals export the bare LC_CTYPE=UTF-8, which macOS accepts but
  # Linux does not recognise as a locale name. mosh reads the client's locale
  # vars straight out of the environment and hands them to mosh-server, which
  # refuses to start on anything but a real UTF-8 locale. Naming the locale in
  # full also stops the invalid value leaking into ssh sessions on the desktop.
  environment.variables.LC_CTYPE = "en_US.UTF-8";

  # Fonts
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  # Homebrew
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "mtnptrsn";
  };
  homebrew = {
    enable = true;
    casks = [
      "1password"
      # Temporarily disabled due to remote server issues
      "discord"
      "slack"
      "spotify"
      "dbeaver-community"
    ];
    onActivation.autoUpdate = true;
    onActivation.cleanup = "uninstall";
  };

  # Animations (all disabled)
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 0.0;
    launchanim = false;
    mineffect = "scale";
    expose-animation-duration = 0.0;
  };
  system.defaults.NSGlobalDomain = {
    NSAutomaticWindowAnimationsEnabled = false;
    NSWindowResizeTime = 0.001;
    NSScrollAnimationEnabled = false;
    NSUseAnimatedFocusRing = false;
  };
  # Kills the Mission Control / space-switch transition
  system.defaults.universalaccess.reduceMotion = true;
  system.defaults.CustomUserPreferences = {
    "com.apple.dock" = {
      workspaces-edge-delay = 0.0;
      workspaces-swoosh-animation-off = true;
      springboard-show-duration = 0.0;
      springboard-hide-duration = 0.0;
      springboard-page-duration = 0.0;
    };
    "com.apple.finder".DisableAllAnimations = true;
    NSGlobalDomain = {
      NSToolbarFullScreenAnimationDuration = 0.0;
      NSBrowserColumnAnimationSpeedMultiplier = 0.0;
      NSDocumentRevisionsWindowTransformAnimation = false;
      QLPanelAnimationDuration = 0.0;
      NSInitialToolTipDelay = 0;
    };
    "com.apple.Accessibility".ReduceMotionEnabled = 1;
  };

  # Input
  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;

  system.stateVersion = 4;
}
