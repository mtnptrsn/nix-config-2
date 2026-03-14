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
                local output = vim.fn.system("tea add " .. vim.fn.shellescape(input))
                if vim.v.shell_error == 0 then
                  vim.notify(output:gsub("%s+$", ""), vim.log.levels.INFO)
                else
                  vim.notify("tea add failed: " .. output, vim.log.levels.ERROR)
                end
              end)
            end'';
          mode = "n";
          options.desc = "Add todo to daily note";
        }
        {
          key = "<leader>tt";
          action.__raw = ''
            function()
              local line = vim.api.nvim_get_current_line()
              if line:match("%- %[ %]") then
                vim.api.nvim_set_current_line((line:gsub("%- %[ %]", "- [x]", 1)))
              elseif line:match("%- %[x%]") then
                vim.api.nvim_set_current_line((line:gsub("%- %[x%]", "- [ ]", 1)))
              end
            end'';
          mode = "n";
          options.desc = "Toggle markdown todo";
        }
      ];
    };
  };
}
