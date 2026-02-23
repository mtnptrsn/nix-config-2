{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      # Show open buffers as tabs along the top of the editor
      plugins.bufferline = {
        enable = true;
        settings.options = {
          show_buffer_close_icons = false;
          show_close_icon = false;
          diagnostics = "nvim_lsp";
        };
      };

      # File explorer that lets you edit the filesystem like a normal buffer
      plugins.oil = {
        enable = true;
        settings.view_options.show_hidden = true;
      };
      # Structured list for navigating diagnostics, references, and search results
      plugins.trouble = {
        enable = true;
        settings.auto_close = true;
      };
      # Enhances vim.ui.select and vim.ui.input with prettier floating windows
      plugins.dressing.enable = true;
      plugins.nvim-autopairs.enable = true;
      plugins.web-devicons.enable = true;

      # Show available keybindings in a popup as you type leader sequences
      plugins.which-key = {
        enable = true;
        # Register leader key group labels in the which-key popup; __unkeyed-N is nixvim's positional arg convention
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
          {
            __unkeyed-1 = "<leader>9";
            group = "99";
          }
        ];
      };

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
          key = "<leader>uw";
          action = "<cmd>set wrap!<cr>";
          mode = "n";
          options.desc = "Toggle word wrap";
        }
        {
          key = "H";
          # In a codediff session, navigate between diff panes instead of cycling buffers
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
          # In a codediff session, navigate between diff panes instead of cycling buffers
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
    };
  };
}
