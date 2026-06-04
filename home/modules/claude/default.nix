# Manages ~/.claude/ config for Claude Code.
#
# Writes ~/.claude/CLAUDE.md from ./claude-md.nix (base) plus any
# profile-specific claudeMd content concatenated after it, and syncs the
# Claude Code UI theme to the shared modules.theme setting.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.claude;
  baseMd = import ./claude-md.nix;
in
{
  options.modules.claude = {
    enable = lib.mkEnableOption "claude";
    claudeMd = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Profile-specific content appended to ~/.claude/CLAUDE.md";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".claude/CLAUDE.md".text = baseMd + cfg.claudeMd;

    # settings.json is hand-edited (model, plugins), so only patch the theme
    # key in place rather than managing the whole file.
    home.activation.claudeTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings="$HOME/.claude/settings.json"
      if [ -e "$settings" ]; then
        run ${pkgs.jq}/bin/jq --arg t "${config.modules.theme}" '.theme = $t' "$settings" \
          > "$settings.tmp" && run mv "$settings.tmp" "$settings"
      else
        run ${pkgs.jq}/bin/jq -n --arg t "${config.modules.theme}" '{theme: $t}' > "$settings"
      fi
    '';
  };
}
