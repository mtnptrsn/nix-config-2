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
      cv = "xclip -selection clipboard -o > /tmp/claude-response.md && nvim -R /tmp/claude-response.md && rm /tmp/claude-response.md";
      ghpr = "GH_PAGER='nvim -R' gh search prs --review-requested=mtnptrsn --state=open";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

}
