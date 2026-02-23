{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.claude;
in
{
  options.modules.claude.enable = lib.mkEnableOption "claude";

  config = lib.mkIf cfg.enable {
    home.file.".claude/skills/commit/SKILL.md".source = ./skills/commit/SKILL.md;
    home.file.".claude/skills/create-pr/SKILL.md".source = ./skills/create-pr/SKILL.md;
  };
}
