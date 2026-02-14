{ config, ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "z"
        "sudo"
        "history"
      ];
    };
    shellAliases = {
      ll = "ls -la";
      nixswitch = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/nixos-config#nixos";
      nixtest = "sudo nixos-rebuild test --flake ${config.home.homeDirectory}/nixos-config#nixos";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

}
