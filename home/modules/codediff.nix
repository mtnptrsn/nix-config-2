{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.codediff;
in
{
  options.modules.codediff.enable = lib.mkEnableOption "codediff";

  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      keymaps = [
        {
          key = "<leader>gd";
          action = "<cmd>CodeDiff<cr>";
          mode = "n";
          options.desc = "Toggle CodeDiff";
        }
      ];
      extraPlugins = [
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
          postInstall =
            let
              libvscode-diff = pkgs.fetchurl {
                url = "https://github.com/esmuellert/vscode-diff.nvim/releases/download/v2.20.3/libvscode_diff_linux_x64_2.20.3.so";
                hash = "sha256-QaLhh2a3ljuDaOQ13n1Tk5YheggqGC4TGtTyk430QtY=";
              };
            in
            ''
              cp ${libvscode-diff} $out/libvscode_diff_2.20.3.so
              cp ${pkgs.gcc.cc.lib}/lib/libgomp.so.1 $out/libgomp.so.1
            '';
          doCheck = false;
        })
      ];
    };
  };
}
