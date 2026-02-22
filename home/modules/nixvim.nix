{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.nixvim;
in
{
  options.modules.nixvim.enable = lib.mkEnableOption "nixvim";

  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      globals.mapleader = " ";
      opts = {
        clipboard = "unnamedplus";
        signcolumn = "yes";
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
        expandtab = true;
      };

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

        vim.api.nvim_create_autocmd("BufWinEnter", {
          pattern = "*",
          callback = function()
            if vim.bo.filetype == "fugitive" then
              local buf = vim.api.nvim_get_current_buf()
              local win = vim.api.nvim_get_current_win()
              local tab = vim.api.nvim_win_get_tabpage(win)
              -- If opened in an existing tab (not already its own tab), move to a new tab
              if #vim.api.nvim_tabpage_list_wins(tab) > 1 then
                vim.cmd("wincmd T")
              end
            end
          end,
        })
      '';

      colorschemes.catppuccin = {
        enable = true;
        settings.flavour = "mocha";
      };

      plugins.treesitter = {
        enable = true;
        grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
        settings.highlight = {
          enable = true;
          additional_vim_regex_highlighting = [ "fugitive" ];
        };
      };

      plugins.telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fw" = "live_grep";
          "<leader>fb" = "buffers";
        };
      };

      plugins.luasnip = {
        enable = true;
        fromVscode = [ { } ];
      };
      plugins.friendly-snippets.enable = true;
      plugins.blink-cmp = {
        enable = true;
        settings.sources.default = [
          "lsp"
          "path"
          "buffer"
          "snippets"
        ];
        settings.keymap."<Tab>" = [
          "select_and_accept"
          "snippet_forward"
          "fallback"
        ];
        settings.keymap."<CR>" = [
          "select_and_accept"
          "fallback"
        ];
        settings.keymap."<S-Tab>" = [
          "snippet_backward"
          "fallback"
        ];
        settings.snippets.preset = "luasnip";
      };

      plugins.lsp = {
        enable = true;
        servers.nil_ls.enable = true;
        servers.ts_ls.enable = true;
      };

      plugins.lint = {
        enable = true;
        lintersByFt =
          lib.genAttrs [
            "typescript"
            "typescriptreact"
            "javascript"
            "javascriptreact"
          ] (_: [ "eslint_d" ])
          // {
            nix = [ "statix" ];
          };
        autoCmd.event = [
          "BufWritePost"
          "BufReadPost"
          "InsertLeave"
        ];
      };

      plugins.conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft =
            lib.genAttrs [
              "javascript"
              "javascriptreact"
              "typescript"
              "typescriptreact"
              "css"
              "html"
              "json"
              "yaml"
              "markdown"
            ] (_: [ "prettierd" ])
            // {
              nix = [ "nixfmt" ];
            };
          format_on_save = {
            timeout_ms = 500;
            lsp_format = "fallback";
          };
        };
      };

      plugins.trouble = {
        enable = true;
        settings.auto_close = true;
      };

      plugins.no-neck-pain = {
        enable = true;
        settings.autocmds = {
          enableOnVimEnter = true;
          enableOnTabEnter = true;
        };
      };
      plugins.oil.enable = true;
      keymaps = [
        {
          key = "-";
          action.__raw = "require('oil').open";
          mode = "n";
          options.desc = "Open parent directory";
        }
        {
          key = "<leader>xx";
          action = "<cmd>Trouble diagnostics toggle<cr>";
          mode = "n";
          options.desc = "Diagnostics";
        }
        {
          key = "<leader>xd";
          action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
          mode = "n";
          options.desc = "Buffer diagnostics";
        }
        {
          key = "<leader>w";
          action = "<cmd>w<cr>";
          mode = "n";
          options.desc = "Save buffer";
        }
        {
          key = "<leader>c";
          action = "<cmd>bd<cr>";
          mode = "n";
          options.desc = "Close buffer";
        }
      ]
      ++ [
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
        {
          key = "<leader>gf";
          action.__raw = ''
            function()
                    for _, tp in ipairs(vim.api.nvim_list_tabpages()) do
                      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tp)) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        if vim.bo[buf].filetype == "fugitive" then
                          vim.api.nvim_set_current_tabpage(tp)
                          vim.cmd("tabclose")
                          return
                        end
                      end
                    end
                    vim.cmd("tab Git")
                  end'';
          mode = "n";
          options.desc = "Toggle Fugitive tab";
        }
        {
          key = "<leader>un";
          action = "<cmd>NoNeckPain<cr>";
          mode = "n";
          options.desc = "Toggle No Neck Pain";
        }
        {
          key = "<leader>uw";
          action = "<cmd>set wrap!<cr>";
          mode = "n";
          options.desc = "Toggle word wrap";
        }
        {
          key = "<leader>yr";
          action.__raw = ''
            function()
              local path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
              vim.fn.setreg("+", path)
              vim.notify(path)
            end'';
          mode = "n";
          options.desc = "Yank relative path";
        }
        {
          key = "<leader>yr";
          action.__raw = ''
            function()
              local start_line = vim.fn.line("v")
              local end_line = vim.fn.line(".")
              if start_line > end_line then start_line, end_line = end_line, start_line end
              local path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
              local ref = path .. ":" .. start_line .. "-" .. end_line
              vim.fn.setreg("+", ref)
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
              vim.notify(ref)
            end'';
          mode = "v";
          options.desc = "Yank relative path with line range";
        }
        {
          key = "Q";
          action = "<cmd>qa<cr>";
          mode = "n";
          options.desc = "Quit neovim";
        }
        {
          key = "H";
          action.__raw = ''
            function()
                    local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
                    if ok and lifecycle.get_session(vim.api.nvim_get_current_tabpage()) then
                      vim.cmd("wincmd h")
                    else
                      vim.cmd("BufferLineCyclePrev")
                    end
                  end'';
          mode = "n";
          options.desc = "Previous buffer / window left";
        }
        {
          key = "L";
          action.__raw = ''
            function()
                    local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
                    if ok and lifecycle.get_session(vim.api.nvim_get_current_tabpage()) then
                      vim.cmd("wincmd l")
                    else
                      vim.cmd("BufferLineCycleNext")
                    end
                  end'';
          mode = "n";
          options.desc = "Next buffer / window right";
        }
      ];
      plugins.bufferline = {
        enable = true;
        settings.options = {
          show_buffer_close_icons = false;
          show_close_icon = false;
          diagnostics = "nvim_lsp";
        };
      };
      extraPlugins = [
        pkgs.vimPlugins.nui-nvim
      ];
      plugins.which-key = {
        enable = true;
        settings.spec = [
          {
            __unkeyed-1 = "<leader>f";
            group = "Find";
          }
          {
            __unkeyed-1 = "<leader>x";
            group = "Diagnostics";
          }
          {
            __unkeyed-1 = "<leader>g";
            group = "Git";
          }
          {
            __unkeyed-1 = "<leader>l";
            group = "LSP";
          }
          {
            __unkeyed-1 = "<leader>u";
            group = "UI";
          }
          {
            __unkeyed-1 = "<leader>y";
            group = "Yank";
          }
        ];
      };
      plugins.lsp-signature.enable = true;
      plugins.dressing.enable = true;
      plugins.nvim-autopairs.enable = true;
      plugins.fugitive.enable = true;
      plugins.web-devicons.enable = true;
    };
  };
}
