{ pkgs, ... }:
{
  home.username = "mtnptrsn";
  home.homeDirectory = "/Users/mtnptrsn";

  home.packages = with pkgs; [
    awscli2
    ssm-session-manager-plugin
  ];

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
