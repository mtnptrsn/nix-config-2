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
        lintersByFt =
          lib.genAttrs [
            "typescript"
            "typescriptreact"
            "javascript"
            "javascriptreact"
          ] (_: [ "eslint_d" ])
          // {
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
            lsp_format = "fallback";
          };
        };
      };
    };
  };
}
