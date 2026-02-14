{ pkgs, ... }:

{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    google-chrome
    discord
    _1password-gui
    spotify
    zoxide
    wowup-cf
    slack
    geekbench
    transmission_4-gtk
    rqbit
    gnomeExtensions.hide-top-bar
    vscode
    ripgrep
    fd
    statix
    eslint_d
    prettierd
  ];

  programs.alacritty = {
    enable = true;
    settings.colors = {
      primary = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        dim_foreground = "#cdd6f4";
      };
      cursor = {
        text = "#1e1e2e";
        cursor = "#f5e0dc";
      };
      selection = {
        text = "CellForeground";
        background = "#585b70";
      };
      search.matches = {
        foreground = "#1e1e2e";
        background = "#a6adc8";
      };
      normal = {
        black   = "#45475a";
        red     = "#f38ba8";
        green   = "#a6e3a1";
        yellow  = "#f9e2af";
        blue    = "#89b4fa";
        magenta = "#f5c2e7";
        cyan    = "#94e2d5";
        white   = "#bac2de";
      };
      bright = {
        black   = "#585b70";
        red     = "#f38ba8";
        green   = "#a6e3a1";
        yellow  = "#f9e2af";
        blue    = "#89b4fa";
        magenta = "#f5c2e7";
        cyan    = "#94e2d5";
        white   = "#a6adc8";
      };
    };
  };

  programs.firefox.enable = true;

  programs.mangohud.enable = true;

  programs.git = {
    enable = true;
    settings.user.name = "Mårten Pettersson";
    settings.user.email = "mtnptrsn@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
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

    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "mocha";
    };

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

    plugins.luasnip = {
      enable = true;
      fromVscode = [{ }];
    };
    plugins.friendly-snippets.enable = true;
    plugins.blink-cmp = {
      enable = true;
      settings.sources.default = [ "lsp" "path" "buffer" "snippets" ];
      settings.keymap."<Tab>" = [ "select_and_accept" "snippet_forward" "fallback" ];
      settings.keymap."<CR>" = [ "select_and_accept" "fallback" ];
      settings.keymap."<S-Tab>" = [ "snippet_backward" "fallback" ];
      settings.snippets.preset = "luasnip";
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

    plugins.conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft = {
          javascript = [ "prettierd" ];
          javascriptreact = [ "prettierd" ];
          typescript = [ "prettierd" ];
          typescriptreact = [ "prettierd" ];
          css = [ "prettierd" ];
          html = [ "prettierd" ];
          json = [ "prettierd" ];
          yaml = [ "prettierd" ];
          markdown = [ "prettierd" ];
        };
        format_on_save = {
          timeout_ms = 500;
          lsp_format = "fallback";
        };
      };
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
      { key = "<leader>q"; action = "<cmd>bd<cr>"; mode = "n"; options.desc = "Close buffer"; }
      { key = "<leader>c"; action = "<cmd>bd<cr>"; mode = "n"; options.desc = "Close buffer"; }
      { key = "<leader>gd"; action = "<cmd>CodeDiff<cr>"; mode = "n"; options.desc = "Toggle CodeDiff"; }
      { key = "<leader>lr"; action.__raw = "vim.lsp.buf.rename"; mode = "n"; options.desc = "Rename symbol"; }
      { key = "gp"; action.__raw = ''function()
        local params = vim.lsp.util.make_position_params(0)
        vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
          if err or not result then return end
          local def = vim.islist(result) and result[1] or result
          vim.lsp.util.preview_location(def, {})
        end)
      end''; mode = "n"; options.desc = "Peek definition"; }
      { key = "gl"; action.__raw = "function() vim.diagnostic.open_float() end"; mode = "n"; options.desc = "Line diagnostics"; }
      { key = "Q"; action = "<cmd>qa<cr>"; mode = "n"; options.desc = "Quit neovim"; }
      { key = "H"; action.__raw = ''function()
        local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
        if ok and lifecycle.get_session(vim.api.nvim_get_current_tabpage()) then
          vim.cmd("wincmd h")
        else
          vim.cmd("BufferLineCyclePrev")
        end
      end''; mode = "n"; options.desc = "Previous buffer / window left"; }
      { key = "L"; action.__raw = ''function()
        local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
        if ok and lifecycle.get_session(vim.api.nvim_get_current_tabpage()) then
          vim.cmd("wincmd l")
        else
          vim.cmd("BufferLineCycleNext")
        end
      end''; mode = "n"; options.desc = "Next buffer / window right"; }
    ];
    plugins.bufferline = {
      enable = true;
      settings.options = {
        show_buffer_close_icons = false;
        show_close_icon = false;
        diagnostics = "nvim_lsp";
      };
    };
    extraPlugins = [
      pkgs.vimPlugins.nui-nvim
      (pkgs.vimUtils.buildVimPlugin {
        name = "codediff-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "esmuellert";
          repo = "codediff.nvim";
          rev = "7e5cda21dab96901cbc4bf3b15828aa8c7b490a7";
          hash = "sha256-uFUsBHEb4ewyh8NNsTsszWMZKmB9dOUFdvRg9zwfsVo=";
        };
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs = [ pkgs.gcc.cc.lib ];
        postInstall = let
          libvscode-diff = pkgs.fetchurl {
            url = "https://github.com/esmuellert/vscode-diff.nvim/releases/download/v2.20.3/libvscode_diff_linux_x64_2.20.3.so";
            hash = "sha256-QaLhh2a3ljuDaOQ13n1Tk5YheggqGC4TGtTyk430QtY=";
          };
        in ''
          cp ${libvscode-diff} $out/libvscode_diff_2.20.3.so
        '';
        doCheck = false;
      })
    ];
    plugins.lsp-signature.enable = true;
    plugins.dressing.enable = true;
    plugins.nvim-autopairs.enable = true;
    plugins.fugitive.enable = true;
    plugins.web-devicons.enable = true;
  };

  programs.tmux = {
    enable = true;
    shortcut = "s";
    baseIndex = 1;
    plugins = with pkgs.tmuxPlugins; [ catppuccin ];
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
    "org/gnome/desktop/background" = {
      picture-uri = "file:///home/mtnptrsn/Pictures/wallpaper.jpg";
      picture-uri-dark = "file:///home/mtnptrsn/Pictures/wallpaper.jpg";
      picture-options = "zoom";
    };
  };
}
