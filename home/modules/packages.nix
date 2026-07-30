{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages;
  cw = pkgs.writeShellScriptBin "cw" (builtins.readFile ../scripts/cw.sh);
  linear-cli = pkgs.callPackage ../pkgs/linear-cli.nix { };
in
{
  options.modules.packages.enable = lib.mkEnableOption "packages";

  config = lib.mkIf cfg.enable {
    home.packages = [
      cw
      linear-cli
    ]
    ++ (with pkgs; [
      # development
      gh
      ripgrep
      rtk
      fd
      statix
      nixfmt
      prettierd
      nodejs
      pnpm
      just
      claude-code
      opencode

      # utilities
      imagemagick
      jq
      nmap
      parallel
      zoxide
      zip
      awscli2
    ]);
  };
}
