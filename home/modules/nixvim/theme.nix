{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.modules.nixvim.enable {
    programs.nixvim = {
      colorschemes.catppuccin = {
        enable = true;
        settings.flavour = "mocha";
      };
    };
  };
}
