{ pkgs, ... }:
let
  askpass = pkgs.writeShellScriptBin "askpass" ''
    osascript -e 'Tell application "System Events" to display dialog "Password for sudo:" with hidden answer default answer ""' -e 'text returned of result'
  '';
in
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  environment.systemPackages = [ askpass ];
  environment.variables.SUDO_ASKPASS = "${askpass}/bin/askpass";

  # Managed by the Determinate Nix installer
  nix.enable = false;

  system.primaryUser = "mtnptrsn";

  users.users.mtnptrsn = {
    home = "/Users/mtnptrsn";
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "mtnptrsn";
  };

  homebrew = {
    enable = true;
    casks = [
      "1password"
      "discord"
      "macwhisper"
      "slack"
      "spotify"
      "transmission"
    ];
    onActivation.autoUpdate = false;
  };

  system.stateVersion = 4;
}
