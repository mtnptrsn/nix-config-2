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
    gnomeExtensions.hide-top-bar
    vscode
    ripgrep
    fd
    statix
    eslint_d
  ];

  programs.firefox.enable = true;

  programs.mangohud.enable = true;

  programs.git = {
    enable = true;
    settings.user.name = "Mårten Pettersson";
    settings.user.email = "mtnptrsn@gmail.com";
  };

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    globals.mapleader = " ";
    opts = {
      signcolumn = "yes";
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
    };

    extraConfigLua = ''
      vim.diagnostic.config({
        virtual_text = { spacing = 4, prefix = "●" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
          },
        },
      })
    '';

    plugins.treesitter = {
      enable = true;
      grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
    };

    plugins.telescope = {
      enable = true;
      extensions.fzf-native.enable = true;
      keymaps = {
        "<leader>ff" = "find_files";
        "<leader>fw" = "live_grep";
        "<leader>fb" = "buffers";
      };
    };

    plugins.lsp = {
      enable = true;
      servers.nil_ls.enable = true;
      servers.ts_ls.enable = true;
    };

    plugins.lint = {
      enable = true;
      lintersByFt = {
        nix = [ "statix" ];
        typescript = [ "eslint_d" ];
        typescriptreact = [ "eslint_d" ];
        javascript = [ "eslint_d" ];
        javascriptreact = [ "eslint_d" ];
      };
      autoCmd.event = [ "BufWritePost" "BufReadPost" "InsertLeave" ];
    };

    plugins.trouble = {
      enable = true;
      settings.auto_close = true;
    };

    plugins.oil.enable = true;
    keymaps = [
      { key = "-"; action.__raw = "require('oil').open"; mode = "n"; options.desc = "Open parent directory"; }
      { key = "<leader>xx"; action = "<cmd>Trouble diagnostics toggle<cr>"; mode = "n"; options.desc = "Diagnostics"; }
      { key = "<leader>xd"; action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>"; mode = "n"; options.desc = "Buffer diagnostics"; }
      { key = "<leader>w"; action = "<cmd>w<cr>"; mode = "n"; options.desc = "Save buffer"; }
    ];
    plugins.fugitive.enable = true;
    plugins.web-devicons.enable = true;
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
    "org/gnome/shell" = {
      enabled-extensions = [ "hidetopbar@mathieu.bidon.ca" ];
    };
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
