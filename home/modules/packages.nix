{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages;
  cw = pkgs.writeShellScriptBin "cw" (builtins.readFile ../scripts/cw.sh);
in
{
  options.modules.packages.enable = lib.mkEnableOption "packages";

  config = lib.mkIf cfg.enable {
    home.packages = [
      cw
    ]
    ++ (with pkgs; [
      # development
      gh
      ripgrep
      fd
      statix
      nixfmt
      nodejs
      claude-code

      # utilities
      jq
      parallel
      zoxide
    ]);
  };
}
