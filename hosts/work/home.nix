_: {
  programs.git.settings.user.email = "marten.pettersson@finch3d.com";

  home.shellAliases = {
    nixswitch = "sudo nixos-rebuild switch --flake ~/nixos-config#work";
    nixtest = "sudo nixos-rebuild test --flake ~/nixos-config#work";
  };
}
