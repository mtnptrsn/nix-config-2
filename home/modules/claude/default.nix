# Manages ~/.claude/ config for Claude Code.
#
# Writes ~/.claude/CLAUDE.md from ./claude-md.nix (base) plus any
# profile-specific claudeMd content concatenated after it.
{
  config,
  lib,
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
  };
}
