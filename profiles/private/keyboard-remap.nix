# Remap keyboard shortcuts to match macOS behavior, so muscle memory
# is consistent across Linux and Mac. Uses the Swedish macOS XKB variant
# for special characters and keyd to make Super act as Ctrl.
{ ... }:

{
  # Swedish macOS keyboard variant for consistent special characters (|, {, })
  services.xserver.xkb.variant = "mac";

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          leftmeta = "layer(meta_as_ctrl)";
        };
        meta_as_ctrl = {
          c = "C-c";
          v = "C-v";
          a = "C-a";
          x = "C-x";
          z = "C-z";
          f = "C-f";
          s = "C-s";
          t = "C-t";
          w = "C-w";
          n = "C-n";
          r = "C-r";
          l = "C-l";
        };
      };
      extraConfig = ''
        [alacritty]
        meta_as_ctrl.c = C-S-c
        meta_as_ctrl.v = C-S-v
      '';
    };
  };
}
