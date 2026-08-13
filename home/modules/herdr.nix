{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.herdr;

  worktreeInclude = pkgs.writeShellApplication {
    name = "herdr-worktree-include";
    runtimeInputs = with pkgs; [
      git
      jq
      gnutar
    ];
    text = builtins.readFile ../scripts/herdr-worktree-include.sh;
  };

  worktreeIncludePlugin = pkgs.writeTextDir "herdr-plugin.toml" ''
    id = "local.worktree-include"
    name = "Worktree include"
    version = "0.1.0"
    min_herdr_version = "0.7.0"
    description = "Copy files listed in .worktreeinclude into new worktrees"
    platforms = ["linux", "macos"]

    [[events]]
    on = "worktree.created"
    command = ["${worktreeInclude}/bin/herdr-worktree-include"]
  '';
in
{
  options.modules.herdr.enable = lib.mkEnableOption "herdr";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.herdr ];

    # Navigate mode (prefix+w): hjkl walks the workspace list and panes,
    # arrows move between panes.
    # Plugin registry. herdr owns this file when plugins are installed through
    # the CLI, so managing it here means plugins are declared in nix only.
    xdg.configFile."herdr/plugins.json".text = builtins.toJSON [
      {
        plugin_id = "local.worktree-include";
        name = "Worktree include";
        version = "0.1.0";
        min_herdr_version = "0.7.0";
        manifest_path = "${worktreeIncludePlugin}/herdr-plugin.toml";
        plugin_root = "${worktreeIncludePlugin}";
        enabled = true;
        events = [
          {
            on = "worktree.created";
            command = [ "${worktreeInclude}/bin/herdr-worktree-include" ];
          }
        ];
        source.kind = "local";
      }
    ];

    xdg.configFile."herdr/config.toml".text = ''
      [keys]
      prefix = "ctrl+s"
      navigate_workspace_up = "k"
      navigate_workspace_down = "j"
      navigate_pane_up = "up"
      navigate_pane_down = "down"
    '';
  };
}
