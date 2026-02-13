{ pkgs, ... }:

{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    google-chrome
    discord
    _1password-gui
    spotify
    zoxide
    alacritty
    wowup-cf
    slack
  ];

  programs.firefox.enable = true;

  programs.git = {
    enable = true;
    settings.user.name = "Mårten Pettersson";
    settings.user.email = "mtnptrsn@gmail.com";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      oil-nvim
      nvim-web-devicons
      nvim-treesitter.withAllGrammars
    ];
    initLua = ''
      require("oil").setup()
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

      vim.treesitter.start()
    '';
  };

  programs.tmux = {
    enable = true;
    shortcut = "s";
    baseIndex = 1;
    plugins = with pkgs.tmuxPlugins; [ dracula ];
    extraConfig = ''
      set -g @dracula-plugins "cpu-usage ram-usage time"
      set -g @dracula-refresh-rate 5
      set -g @dracula-show-left-icon session
      set -g @dracula-show-empty-plugins false
      set -g @dracula-show-powerline false
      set -g @dracula-military-time true
      set -g @dracula-day-month true
    '';
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "z" "sudo" "history" ];
    };
    shellAliases = {
      ll = "ls -la";
      nixswitch = "sudo nixos-rebuild switch --flake /home/mtnptrsn/nixos-config#nixos";
      nixtest = "sudo nixos-rebuild test --flake /home/mtnptrsn/nixos-config#nixos";
    };
  };

  dconf.settings = {
    "org/gnome/desktop/peripherals/mouse" = {
      speed = -0.4;
    };
    "org/gnome/desktop/interface" = {
      enable-animations = false;
    };
  };
}
