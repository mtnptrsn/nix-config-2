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
        {
          key = "<leader>q";
          action = "<cmd>confirm q<cr>";
          mode = "n";
          options.desc = "Quit window";
        }
        {
          key = "<leader>Q";
          action = "<cmd>confirm qall<cr>";
          mode = "n";
          options.desc = "Exit neovim";
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
      ];
    };
  };
}
