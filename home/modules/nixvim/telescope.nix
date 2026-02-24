{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      plugins.telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
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
