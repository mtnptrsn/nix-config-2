{ pkgs, ... }:
{
  home.username = "mtnptrsn";
  home.homeDirectory = "/Users/mtnptrsn";

  home.packages = with pkgs; [
    # Reach the desktop's herdr server over a flaky link, such as inflight wifi:
    # `mosh desktop -- herdr`
    mosh
  ];

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

  # Attach to the personal desktop's herdr server with `herdr --remote desktop`.
  # mosh bootstraps over ssh too, so it resolves this host as well.
  programs.ssh = {
    enable = true;
    matchBlocks.desktop = {
      hostname = "mtnptrsn"; # MagicDNS name over Tailscale
      user = "mtnptrsn";
    };
  };

}
