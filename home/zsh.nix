_: {
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
      v = "nvim";
      p = "pnpm";
      cv = "xclip -selection clipboard -o | nvim -R -";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

}
