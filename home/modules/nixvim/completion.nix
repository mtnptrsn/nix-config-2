{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      plugins.luasnip = {
        enable = true;
        fromVscode = [ { } ];
      };
      plugins.friendly-snippets.enable = true;
      plugins.blink-cmp = {
        enable = true;
        settings.sources.default = [
          "lsp"
          "path"
          "buffer"
          "snippets"
        ];
        settings.keymap."<Tab>" = [
          "select_and_accept"
          "snippet_forward"
          "fallback"
        ];
        settings.keymap."<CR>" = [
          "select_and_accept"
          "fallback"
        ];
        settings.keymap."<S-Tab>" = [
          "snippet_backward"
          "fallback"
        ];
        settings.snippets.preset = "luasnip";
      };
    };
  };
}
