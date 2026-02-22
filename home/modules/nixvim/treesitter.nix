{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      plugins.treesitter = {
        enable = true;
        grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
        settings.highlight = {
          enable = true;
          # Fugitive needs legacy vim regex highlighting alongside treesitter
          additional_vim_regex_highlighting = [ "fugitive" ];
        };
      };
    };
  };
}
