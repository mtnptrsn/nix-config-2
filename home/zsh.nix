_:
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
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

}
