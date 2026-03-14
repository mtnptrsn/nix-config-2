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
