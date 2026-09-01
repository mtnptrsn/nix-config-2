{ pkgs, ... }:
{
  home.username = "mtnptrsn";
  home.homeDirectory = "/Users/mtnptrsn";

  home.packages = with pkgs; [
    awscli2
    ssm-session-manager-plugin

    # Reach the desktop's herdr server over a flaky link, such as inflight wifi:
    # `mosh desktop -- herdr`
    mosh
  ];

  modules = {
    # Development tools
    nixvim.enable = true;
    vscode.enable = true;

    # Terminal and shell
    theme = "dark";

    alacritty.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    herdr.enable = true;

    # Screenshots and recordings sync to the desktop's ~/Captures; the
    # desktop-side path lands in the mac clipboard, ready to paste into a
    # herdr pane.
    captureSync.enable = true;

    # Version control
    git.enable = true;
    lazygit.enable = true;

    # AI tools
    claude.enable = true;
    claude.claudeMd = import ./claude/claude-md.nix;

    # Notes
    tea.enable = true;
    tea.defaultContext = "work";

    # Applications
    firefox.enable = true;

    # Package management
    packages.enable = true;
  };

  # Attach to the personal desktop's herdr server with `herdr --remote desktop`
  programs.ssh = {
    enable = true;
    matchBlocks.desktop = {
      hostname = "mtnptrsn"; # MagicDNS name over Tailscale
      user = "mtnptrsn";
    };
  };

}
