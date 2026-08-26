{
  config,
  lib,
  ...
}:
let
  jsFileTypes = [
    "javascript"
    "javascriptreact"
    "typescript"
    "typescriptreact"
  ];
in
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      plugins.lint = {
        enable = true;
        # genAttrs assigns the same linter to all listed filetypes
        lintersByFt = {
          nix = [ "statix" ];
        }
        // lib.genAttrs jsFileTypes (_: [ "oxlint" ]);
        autoCmd.event = [
          "BufWritePost"
          "BufReadPost"
          "InsertLeave"
        ];
      };

      # nixvim types lint.linters.<name>.cmd as a plain string, so the dynamic
      # lookup has to be patched in after the plugin has been set up
      extraConfigLuaPost = ''
        require("lint").linters.oxlint.cmd = function()
          -- Only lint with the project's own oxlint, stay quiet elsewhere
          local root = vim.fs.root(0, { ".oxlintrc.json", ".oxlintrc.jsonc" })
          local bin = root and (root .. "/node_modules/.bin/oxlint")
          if bin and vim.uv.fs_stat(bin) then
            return bin
          end
          return "true"
        end
      '';

      userCommands.Format = {
        command.__raw = ''function() require("conform").format({ lsp_format = "fallback" }) end'';
        desc = "Format buffer";
      };

      plugins.conform-nvim = {
        enable = true;
        settings = {
          # Only run oxfmt in projects that configure it
          formatters.oxfmt.require_cwd = true;
          # genAttrs assigns the same formatter to all listed filetypes
          formatters_by_ft =
            lib.genAttrs [
              "css"
              "html"
              "json"
              "yaml"
              "markdown"
            ] (_: [ "prettierd" ])
            // lib.genAttrs jsFileTypes (_: {
              "__unkeyed-1" = "oxfmt";
              "__unkeyed-2" = "prettierd";
              stop_after_first = true;
            })
            // {
              nix = [ "nixfmt" ];
            };
          format_on_save = {
            timeout_ms = 500;
            # Use LSP formatting when no conform formatter is configured
            lsp_format = "fallback";
          };
        };
      };
    };
  };
}
