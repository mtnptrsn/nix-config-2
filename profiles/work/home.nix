_: {
  modules = {
    nixvim.enable = true;
    alacritty.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    gnome.enable = true;
    git.enable = true;
  };

  programs.git.settings.user.email = "marten.pettersson@finch3d.com";

}
