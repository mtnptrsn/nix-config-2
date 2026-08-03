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
    ./tea.nix
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
        -- herdr panes are spawned by a server with no WAYLAND_DISPLAY/DISPLAY,
        -- so nvim finds no clipboard tool and yanks to "+ go nowhere. Use OSC 52
        -- instead, which lands the copy on whichever machine is attached.
        if vim.env.HERDR_ENV then
          local osc52 = require("vim.ui.clipboard.osc52")
          -- Paste reads the unnamed register: terminals answer OSC 52 reads
          -- rarely (and slowly), and unnamedplus keeps "" in sync with "+.
          local paste = function()
            return vim.split(vim.fn.getreg('"'), "\n")
          end
          vim.g.clipboard = {
            name = "OSC 52",
            copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
            paste = { ["+"] = paste, ["*"] = paste },
          }
        end

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
