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

  # Zsh (user config in home/, system-level enable for /etc/shells)
  programs.zsh.enable = true;
}
