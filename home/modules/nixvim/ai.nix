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
      ];
    };
  };
}
