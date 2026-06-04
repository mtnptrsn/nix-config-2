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
      # "discord"
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
  };
  # Input
  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;

  system.stateVersion = 4;
}
