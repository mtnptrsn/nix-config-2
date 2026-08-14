{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.herdr;

  # A plugin is a script plus the manifest herdr reads it through. The manifest
  # lives in its own store dir because herdr expects a plugin root directory.
  mkEventPlugin =
    {
      id,
      name,
      description,
      events,
      script,
      runtimeInputs,
    }:
    let
      command = pkgs.writeShellApplication {
        inherit name runtimeInputs;
        text = builtins.readFile script;
      };
      hooks = map (event: ''

        [[events]]
        on = "${event}"
        command = ["${command}/bin/${name}"]
      '') events;
      root = pkgs.writeTextDir "herdr-plugin.toml" ''
        id = "${id}"
        name = "${name}"
        version = "0.1.0"
        min_herdr_version = "0.7.0"
        description = "${description}"
        platforms = ["linux", "macos"]
        ${lib.concatStrings hooks}'';
    in
    {
      plugin_id = id;
      inherit name;
      version = "0.1.0";
      min_herdr_version = "0.7.0";
      manifest_path = "${root}/herdr-plugin.toml";
      plugin_root = "${root}";
      enabled = true;
      events = map (event: {
        on = event;
        command = [ "${command}/bin/${name}" ];
      }) events;
      source.kind = "local";
    };

  plugins = [
    (mkEventPlugin {
      id = "local.worktree-include";
      name = "herdr-worktree-include";
      description = "Copy files listed in .worktreeinclude into new worktrees";
      events = [ "worktree.created" ];
      script = ../scripts/herdr-worktree-include.sh;
      runtimeInputs = with pkgs; [
        git
        jq
        gnutar
      ];
    })
    (mkEventPlugin {
      id = "local.default-layout";
      name = "herdr-default-layout";
      description = "Open every new tab as a 2x2 grid of panes";
      # New workspaces and worktree checkouts open a tab of their own, so
      # tab.created covers all three without firing twice for one tab.
      events = [ "tab.created" ];
      script = ../scripts/herdr-default-layout.sh;
      runtimeInputs = with pkgs; [
        herdr
        jq
      ];
    })
  ];
in
{
  options.modules.herdr.enable = lib.mkEnableOption "herdr";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.herdr ];

    # Plugin registry. herdr owns this file when plugins are installed through
    # the CLI, so managing it here means plugins are declared in nix only.
    xdg.configFile."herdr/plugins.json".text = builtins.toJSON plugins;

    # Navigate mode (prefix+w): hjkl walks the workspace list and panes,
    # arrows move between panes.
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
