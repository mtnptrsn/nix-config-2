# Manages ~/.claude/ config and skills for Claude Code.
#
# Always writes ~/.claude/CLAUDE.md from ./claude-md.nix (base) plus any
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
    # Profile-specific skills. Each key becomes a skill directory
    # under ~/.claude/skills/<name>/SKILL.md.
    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = "Additional skills to install (name -> SKILL.md content)";
    };
    # Profile-specific content appended to ~/.claude/CLAUDE.md after the base.
    claudeMd = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Profile-specific content appended to ~/.claude/CLAUDE.md";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".claude/CLAUDE.md".text = baseMd + cfg.claudeMd;
    }
    //
      lib.mapAttrs'
        (
          # mapAttrs' transforms an attrset into a different attrset.
          # nameValuePair remaps each skill (e.g. "commit" -> content)
          # into a home.file entry (e.g. ".claude/skills/commit/SKILL.md" -> { text = content; }).
          name: content: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { text = content; }
        )
        (
          # Start with the built-in commit skill, then merge (//) profile-provided
          # skills on top - so profiles can override the commit skill if needed.
          {
            commit = import ./skills/commit.nix;
            review = import ./skills/review.nix;
            sync-skills = import ./skills/sync-skills.nix;
          }
          // cfg.skills
        );
  };
}
