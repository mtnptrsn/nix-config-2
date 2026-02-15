_: {
  programs.git.settings.user.email = "mtnptrsn@gmail.com";

  home.shellAliases = {
    nixswitch = "sudo nixos-rebuild switch --flake ~/nixos-config#private";
    nixtest = "sudo nixos-rebuild test --flake ~/nixos-config#private";
  };
}
