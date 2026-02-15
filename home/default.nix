{ ... }:

{
  imports = [
    ./nixvim.nix
    ./alacritty.nix
    ./zsh.nix
    ./tmux.nix
    ./gnome.nix
    ./packages.nix
    ./git.nix
  ];

  home.stateVersion = "25.11";

  programs.firefox.enable = true;

  programs.mangohud.enable = true;

  programs.claude-code = {
    enable = true;
    settings = {
      effortLevel = "medium";
      hooks = { };
    };
    skillsDir = ./claude/skills;
  };
}
