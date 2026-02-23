_: {
  home.username = "mtnptrsn";
  home.homeDirectory = "/Users/mtnptrsn";

  modules = {
    # Development tools
    nixvim.enable = true;
    vscode.enable = true;

    # Terminal and shell
    alacritty.enable = true;
    zsh.enable = true;
    tmux.enable = true;

    # Version control
    git.enable = true;

    # AI tools
    claude.enable = true;

    # Applications
    firefox.enable = true;

    # Package management
    packages.enable = true;
  };

  programs.git.settings.user.email = "marten.pettersson@finch3d.com";
}
