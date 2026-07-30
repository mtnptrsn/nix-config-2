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
    herdr.enable = true;

    # AI tools
    claude.enable = true;
    claude.claudeMd = import ./claude/claude-md.nix;

    # Version control
    git.enable = true;
    lazygit.enable = true;

    # Applications
    firefox.enable = true;

    # Package management
    packages.enable = true;
  };

}
