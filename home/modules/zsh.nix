{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.zsh;
in
{
  options.modules.zsh.enable = lib.mkEnableOption "zsh";

  config = lib.mkIf cfg.enable {
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
        ghpr = "gh search prs --review-requested=mtnptrsn --state=open";
        claude = "npx @anthropic-ai/claude-code";
      };
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
