_: {
  modules = {
    nixvim.enable = true;
    alacritty.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    gnome.enable = true;
    git.enable = true;
    pr-dashboard.enable = true;
  };

  programs.git.settings.user.email = "marten.pettersson@finch3d.com";

  home.shellAliases = {
    nixswitch = "sudo nixos-rebuild switch --flake ~/nixos-config#work";
    nixtest = "sudo nixos-rebuild test --flake ~/nixos-config#work";
  };
}
