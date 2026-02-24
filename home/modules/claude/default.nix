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
      # Only create CLAUDE.md if the profile sets claudeMd content.
      lib.optionalAttrs (cfg.claudeMd != "") {
        ".claude/CLAUDE.md".text = cfg.claudeMd;
      }
      # Merge (//) with the skill files built below.
      // lib.mapAttrs' (
        # mapAttrs' transforms an attrset into a different attrset.
        # nameValuePair remaps each skill (e.g. "commit" -> content)
        # into a home.file entry (e.g. ".claude/skills/commit/SKILL.md" -> { text = content; }).
        name: content: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { text = content; }
      ) (
        # Start with the built-in commit skill, then merge (//) profile-provided
        # skills on top - so profiles can override the commit skill if needed.
        { commit = import ./skills/commit.nix; } // cfg.skills
      );
  };
}
