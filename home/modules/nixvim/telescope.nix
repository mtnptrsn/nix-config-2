{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      # Telescope requires plenary at runtime, but it is not pulled in
      # automatically, so add it explicitly to the plugin pack.
      extraPlugins = [ pkgs.vimPlugins.plenary-nvim ];

      plugins.telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
        settings.defaults.file_ignore_patterns = [
          "^.git/"
        ];
        settings.pickers = {
          find_files = {
            hidden = true;
          };
          live_grep = {
            additional_args = [
              "--hidden"
            ];
          };
        };
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fw" = "live_grep";
          "<leader>fb" = "buffers";
        };
      };
    };
  };
}
