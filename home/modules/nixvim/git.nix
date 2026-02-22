{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      plugins.fugitive.enable = true;

      # Force fugitive to always open in its own tab
      extraConfigLua = ''
        vim.api.nvim_create_autocmd("BufWinEnter", {
          pattern = "*",
          callback = function()
            if vim.bo.filetype == "fugitive" then
              local buf = vim.api.nvim_get_current_buf()
              local win = vim.api.nvim_get_current_win()
              local tab = vim.api.nvim_win_get_tabpage(win)
              if #vim.api.nvim_tabpage_list_wins(tab) > 1 then
                vim.cmd("wincmd T")
              end
            end
          end,
        })
      '';

      keymaps = [
        {
          key = "<leader>gf";
          # Search all tabs for an existing fugitive window; close it if found, open new if not
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
        # Open selected lines in browser on the remote git host (GitHub/GitLab)
        {
          key = "<leader>go";
          action.__raw = ''
            function()
              local start_line = vim.fn.line("v")
              local end_line = vim.fn.line(".")
              if start_line > end_line then start_line, end_line = end_line, start_line end
              local remote = vim.fn.system("git -C " .. vim.fn.shellescape(vim.fn.fnamemodify(vim.fn.expand("%"), ":p:h")) .. " remote get-url origin"):gsub("%s+$", "")
              local base = remote:gsub("^git@([^:]+):", "https://%1/"):gsub("%.git$", "")
              local branch = vim.fn.system("git -C " .. vim.fn.shellescape(vim.fn.fnamemodify(vim.fn.expand("%"), ":p:h")) .. " rev-parse HEAD"):gsub("%s+$", "")
              local root = vim.fn.system("git -C " .. vim.fn.shellescape(vim.fn.fnamemodify(vim.fn.expand("%"), ":p:h")) .. " rev-parse --show-toplevel"):gsub("%s+$", "")
              local filepath = vim.fn.fnamemodify(vim.fn.expand("%"), ":p"):sub(#root + 2)
              local url = base .. "/blob/" .. branch .. "/" .. filepath .. "#L" .. start_line .. "-L" .. end_line
              vim.ui.open(url)
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
              vim.notify(url)
            end'';
          mode = "v";
          options.desc = "Open lines on remote";
        }
      ];
    };
  };
}
