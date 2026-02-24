# Manages ~/.claude/ config and skills for Claude Code.
#
# The commit skill is always included. Profiles can add more skills
# and set claudeMd content - see profiles/office/macbook/home/ for
# an example.
{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.claude;
in
{
  options.modules.claude = {
    enable = lib.mkEnableOption "claude";
    # Profile-specific skills. Each key becomes a skill directory
    # under ~/.claude/skills/<name>/SKILL.md.
    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = "Additional skills to install (name -> SKILL.md content)";
    };
    # Written to ~/.claude/CLAUDE.md when non-empty.
    claudeMd = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Content for ~/.claude/CLAUDE.md";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file =
      lib.optionalAttrs (cfg.claudeMd != "") {
        ".claude/CLAUDE.md".text = cfg.claudeMd;
      }
      // lib.mapAttrs' (
        name: content: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { text = content; }
      ) ({ commit = import ./skills/commit.nix; } // cfg.skills);
  };
}
