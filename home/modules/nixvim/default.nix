{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixvim;
in
{
  imports = [
    ./theme.nix
    ./treesitter.nix
    ./telescope.nix
    ./completion.nix
    ./lsp.nix
    ./format-lint.nix
    ./git.nix
    ./ui.nix
    ./general.nix
    ./ai.nix
  ];

  options.modules.nixvim.enable = lib.mkEnableOption "nixvim";

  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      globals.mapleader = " ";
      opts = {
        # Sync yank/paste with system clipboard
        clipboard = "unnamedplus";
        # Always show to prevent layout shift when diagnostics appear
        signcolumn = "yes";
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
        expandtab = true;
        foldmethod = "expr";
        foldexpr = "v:lua.vim.treesitter.foldexpr()";
        foldlevel = 99;
      };

      # Replace default diagnostic signs with nerd font icons
      extraConfigLua = ''
        vim.diagnostic.config({
          virtual_text = { spacing = 4, prefix = "●" },
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = "",
              [vim.diagnostic.severity.WARN] = "",
              [vim.diagnostic.severity.INFO] = "",
              [vim.diagnostic.severity.HINT] = "",
            },
          },
        })
      '';
    };
  };
}
