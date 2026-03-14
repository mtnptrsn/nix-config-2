{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.tea;
  teaScript = builtins.replaceStrings [ "@notesDir@" ] [ cfg.notesDir ] (builtins.readFile ./tea.py);
  tea = pkgs.writers.writePython3Bin "tea" { } teaScript;
in
{
  options.modules.tea = {
    enable = lib.mkEnableOption "tea";
    notesDir = lib.mkOption {
      type = lib.types.str;
      default = "~/Notes";
      description = "Directory where notes are stored";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ tea ];
  };
}
