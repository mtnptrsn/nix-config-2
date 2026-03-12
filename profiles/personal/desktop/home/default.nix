{ pkgs, ... }:
{
  modules = {
    # Development tools
    claude.enable = true;
    claude.claudeMd = import ./claude/claude-md.nix;
    nixvim.enable = true;
    vscode.enable = true;
    codediff.enable = true;

    # Terminal and shell
    alacritty.enable = true;
    zsh.enable = true;
    tmux.enable = true;

    # Desktop environment
    gnome.enable = true;

    # Version control
    git.enable = true;

    # Applications
    firefox.enable = true;
    dictation.enable = true;
    homeassistant = {
      enable = true;
      url = "http://192.168.1.92:8123";
      # Safe since HA is on local network only, not exposed externally
      token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIzMjE0ZTJiYmVhNTk0ZWNmYTQ3MWQwZDRhY2RkYzkzOCIsImlhdCI6MTc3MTk2Nzk2NSwiZXhwIjoyMDg3MzI3OTY1fQ.LQmc4zbSZ8GBVtqwDlbZQNIJJoI4QLXIDV_7Yx29XfM";
    };

    # Package management
    packages.enable = true;
    linux-packages.enable = true;
  };

  home.packages = with pkgs; [
    stremio
    wowup-cf
  ];

  xdg.desktopEntries.battle-net = {
    name = "Battle.net";
    exec = "steam steam://rungameid/0";
    icon = ./battle-net.png;
    comment = "Battle.net via Steam";
    categories = [ "Game" ];
    settings = {
      StartupWMClass = "steam_app_0";
    };
  };

}
