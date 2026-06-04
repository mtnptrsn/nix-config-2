# Shared color theme selector used across terminal apps (alacritty, nixvim,
# claude). "dark" = Catppuccin Mocha, "light" = Catppuccin Latte.
{ lib, ... }:
{
  options.modules.theme = lib.mkOption {
    type = lib.types.enum [
      "dark"
      "light"
    ];
    default = "dark";
    description = "Shared color theme used across terminal apps.";
  };
}
