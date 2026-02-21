{ pkgs, ... }:

{
  # User account
  users.users.mtnptrsn = {
    isNormalUser = true;
    description = "Mårten Pettersson";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
    ];
  };

  # Passwordless nixos-rebuild
  security.sudo.extraRules = [
    {
      users = [ "mtnptrsn" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Graphical sudo askpass (for non-terminal contexts like Claude Code)
  environment.variables.SUDO_ASKPASS = "${pkgs.ssh-askpass-fullscreen}/bin/ssh-askpass-fullscreen";
  security.sudo.extraConfig = ''
    Defaults env_keep += "SUDO_ASKPASS"
  '';

  # Zsh (user config in home/, system-level enable for /etc/shells)
  programs.zsh.enable = true;
}
