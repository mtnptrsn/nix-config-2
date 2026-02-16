{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.git;
in
{
  options.modules.git.enable = lib.mkEnableOption "git";

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      settings.user.name = "Mårten Pettersson";
      settings.init.defaultBranch = "main";
      settings.pull.rebase = true;
      settings.push.autoSetupRemote = true;
    };
  };
}
