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
    geekbench
    rqbit
    vscode
    ripgrep
    fd
    nil
    nodePackages.typescript-language-server
    nodePackages.typescript
  ];

  programs.firefox.enable = true;

  programs.mangohud.enable = true;

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
      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      nvim-lspconfig
      vim-fugitive
    ];
    extraLuaConfig = ''
      vim.g.mapleader = ' '

      -- Telescope setup with fzf
      require('telescope').setup {}
      require('telescope').load_extension('fzf')

      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files)
      vim.keymap.set('n', '<leader>fg', builtin.live_grep)
      vim.keymap.set('n', '<leader>fb', builtin.buffers)
      vim.keymap.set('n', '<leader>fh', builtin.help_tags)

      -- LSP setup
      local lspconfig = require('lspconfig')
      lspconfig.nil_ls.setup {}
      lspconfig.ts_ls.setup {}
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

  services.devilspie2 = {
    enable = true;
    config = ''
      maximize()
    '';
  };

  dconf.settings = {
    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";  # Disable GNOME acceleration; maccel handles it
    };
    "org/gnome/desktop/interface" = {
      enable-animations = false;
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
    };
  };
}
