_:

{
  programs.git = {
    enable = true;
    settings.user.name = "Mårten Pettersson";
    settings.init.defaultBranch = "main";
    settings.pull.rebase = true;
    settings.push.autoSetupRemote = true;
  };
}
