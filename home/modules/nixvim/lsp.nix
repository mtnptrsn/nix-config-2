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
      };

      # Shows function parameter hints while typing arguments
      plugins.lsp-signature.enable = true;

      keymaps = [
        {
          key = "<leader>lr";
          action.__raw = "vim.lsp.buf.rename";
          mode = "n";
          options.desc = "Rename symbol";
        }
        {
          key = "<leader>lR";
          action.__raw = "vim.lsp.buf.references";
          mode = "n";
          options.desc = "Show references";
        }
        # Show definition in a floating preview without leaving current position
        {
          key = "gp";
          action.__raw = ''
            function()
                    local params = vim.lsp.util.make_position_params(0)
                    vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
                      if err or not result then return end
                      local def = vim.islist(result) and result[1] or result
                      vim.lsp.util.preview_location(def, {})
                    end)
                  end'';
          mode = "n";
          options.desc = "Peek definition";
        }
        {
          key = "gd";
          action.__raw = "vim.lsp.buf.definition";
          mode = "n";
          options.desc = "Go to definition";
        }
        {
          key = "gl";
          action.__raw = "function() vim.diagnostic.open_float() end";
          mode = "n";
          options.desc = "Line diagnostics";
        }
      ];
    };
  };
}
