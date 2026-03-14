{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.tea;
  defaultContext = if cfg.defaultContext != null then cfg.defaultContext else "";
  teaScript =
    builtins.replaceStrings
      [
        "@notesDir@"
        "@defaultContext@"
      ]
      [
        cfg.notesDir
        defaultContext
      ]
      (builtins.readFile ./tea.py);
  tea = pkgs.writers.writePython3Bin "tea" { libraries = [ pkgs.python3Packages.typer ]; } teaScript;
in
{
  options.modules.tea = {
    enable = lib.mkEnableOption "tea";
    notesDir = lib.mkOption {
      type = lib.types.str;
      default = "~/Notes";
      description = "Directory where notes are stored";
    };
    defaultContext = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default context for daily notes";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ tea ];

    programs.zsh.initContent = lib.mkIf config.modules.zsh.enable ''
      _tea() {
        local -a commands
        commands=(add open project projects)

        if (( CURRENT == 2 )); then
          _describe 'command' commands
        elif [[ "$words[2]" == "project" ]]; then
          if (( CURRENT == 3 )); then
            local pdir="${cfg.notesDir}/projects"
            pdir="''${pdir/#\~/$HOME}"
            if [[ -d "$pdir" ]]; then
              local -a projects
              projects=(''${pdir}/*.md(N:t:r))
              _describe 'project' projects
            fi
          elif (( CURRENT == 4 )); then
            _describe 'subcommand' '(add)'
          fi
        fi
      }
      compdef _tea tea
    '';
  };
}
