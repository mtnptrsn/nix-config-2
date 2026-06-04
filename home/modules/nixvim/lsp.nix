{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      plugins.lsp = {
        enable = true;
        servers.nil_ls.enable = true;
        servers.ts_ls.enable = true;
        servers.eslint.enable = true;
      };

      # Shows function parameter hints while typing arguments
      plugins.lsp-signature.enable = true;

      keymaps = [
        # Rename all references to the symbol under cursor across the project
        {
          key = "<leader>lr";
          action.__raw = "vim.lsp.buf.rename";
          mode = "n";
          options.desc = "Rename symbol";
        }
        # List all locations where the symbol under cursor is referenced
        {
          key = "<leader>lR";
          action.__raw = "vim.lsp.buf.references";
          mode = "n";
          options.desc = "Show references";
        }
        # List all symbols in the current buffer via Telescope
        {
          key = "<leader>lS";
          action = "<cmd>Telescope lsp_document_symbols<cr>";
          mode = "n";
          options.desc = "Document symbols";
        }
        # Show hover info (type signature, docs) for the symbol under cursor
        {
          key = "gp";
          action.__raw = "vim.lsp.buf.hover";
          mode = "n";
          options.desc = "Hover";
        }
        {
          key = "gd";
          action.__raw = "vim.lsp.buf.definition";
          mode = "n";
          options.desc = "Go to definition";
        }
        {
          key = "gl";
          action.__raw = "function() vim.diagnostic.open_float({ border = 'single' }) end";
          mode = "n";
          options.desc = "Line diagnostics";
        }
      ];
    };
  };
}
