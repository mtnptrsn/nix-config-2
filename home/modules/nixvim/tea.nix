{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      keymaps = [
        {
          key = "<leader>td";
          action.__raw = ''
            function()
              local path = vim.fn.system("tea -p"):gsub("%s+$", "")
              if vim.v.shell_error == 0 and path ~= "" then
                vim.cmd("edit " .. vim.fn.fnameescape(path))
              else
                vim.notify("tea failed: " .. path, vim.log.levels.ERROR)
              end
            end'';
          mode = "n";
          options.desc = "Open daily note";
        }
        {
          key = "<leader>ta";
          action.__raw = ''
            function()
              vim.ui.input({ prompt = "Task: " }, function(input)
                if input == nil or input == "" then return end
                local buf_path = vim.api.nvim_buf_get_name(0)
                local buf_content = table.concat(
                  vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"
                ) .. "\n"
                local cmd = "tea add -b " .. vim.fn.shellescape(buf_path)
                  .. " " .. vim.fn.shellescape(input)
                local output = vim.fn.system(cmd, buf_content)
                if vim.v.shell_error ~= 0 then
                  vim.notify("tea add failed: " .. output, vim.log.levels.ERROR)
                  return
                end
                if output ~= "" then
                  local new_lines = vim.split(output:gsub("%s+$", ""), "\n", { plain = true })
                  vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
                else
                  vim.cmd("checktime")
                end
                vim.notify("Added: " .. input, vim.log.levels.INFO)
              end)
            end'';
          mode = "n";
          options.desc = "Add todo to daily note";
        }
        {
          key = "<leader>tt";
          action = ":.!tea toggle<CR>";
          mode = "n";
          options.desc = "Toggle markdown todo";
        }
        {
          key = "<leader>tt";
          action = ":!tea toggle<CR>";
          mode = "v";
          options.desc = "Toggle markdown todos";
        }
      ];
    };
  };
}
