{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      plugins.lint = {
        enable = true;
        # genAttrs assigns the same linter to all listed filetypes
        lintersByFt = {
          nix = [ "statix" ];
        };
        autoCmd.event = [
          "BufWritePost"
          "BufReadPost"
          "InsertLeave"
        ];
      };

      plugins.conform-nvim = {
        enable = true;
        settings = {
          # genAttrs assigns the same formatter to all listed filetypes
          formatters_by_ft =
            lib.genAttrs [
              "javascript"
              "javascriptreact"
              "typescript"
              "typescriptreact"
              "css"
              "html"
              "json"
              "yaml"
              "markdown"
            ] (_: [ "prettierd" ])
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
