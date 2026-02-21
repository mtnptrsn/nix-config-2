_: {
  home.username = "mtnptrsn";
  home.homeDirectory = "/Users/mtnptrsn";

  modules = {
    nixvim.enable = false;
    alacritty.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    git.enable = true;
    packages.enable = true;
  };

  programs.git.settings.user.email = "mtnptrsn@gmail.com";
}
