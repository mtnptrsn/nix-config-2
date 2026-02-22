{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      # AI assistant plugin using Claude as the backend
      extraConfigLua = ''
        local _99 = require("99")
        _99.setup({
          provider = _99.Providers.ClaudeCodeProvider,
        })
      '';

      extraPlugins = [
        pkgs.vimPlugins.nui-nvim # Required dependency for the 99 plugin's UI
        (pkgs.vimUtils.buildVimPlugin {
          pname = "99";
          version = "2025-02-22";
          src = pkgs.fetchFromGitHub {
            owner = "ThePrimeagen";
            repo = "99";
            rev = "d97ef48f244d68e1a5060f1bbd6dee706f23ba55";
            hash = "sha256-8iYL7W0YwFTA3UXoAjbItkMm7piZzSOlrAIZIv02+bA=";
          };
        })
      ];

      keymaps = [
        {
          key = "<leader>9v";
          action.__raw = "require('99').visual";
          mode = "v";
          options.desc = "99: Submit selection";
        }
        {
          key = "<leader>9x";
          action.__raw = "require('99').stop_all_requests";
          mode = "n";
          options.desc = "99: Cancel request";
        }
        {
          key = "<leader>9s";
          action.__raw = "require('99').search";
          mode = "n";
          options.desc = "99: Search";
        }
        {
          key = "<leader>ch";
          action.__raw = ''
            function()
              local start_line = vim.fn.line("v")
              local end_line = vim.fn.line(".")
              if start_line > end_line then start_line, end_line = end_line, start_line end
              local path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
              local ref = path .. ":" .. start_line .. "-" .. end_line
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
              local pane = vim.fn.system("tmux split-window -h -l 80 -P 'claude; exec $SHELL'"):gsub("%s+", "")
              vim.fn.system("(sleep 2 && tmux send-keys -t '" .. pane .. "' 'Regarding " .. ref .. ": ') &")
            end'';
          mode = "v";
          options.desc = "Open Claude Code in tmux pane with selection context";
        }
      ];
    };
  };
}
