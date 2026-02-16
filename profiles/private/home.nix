{ pkgs, ... }:
{
  modules = {
    nixvim.enable = true;
    alacritty.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    gnome.enable = true;
    git.enable = true;
    firefox.enable = true;
  };

  home.packages = with pkgs; [
    wowup-cf
  ];

  programs.git.settings.user.email = "mtnptrsn@gmail.com";

  programs.claude-code = {
    enable = true;
    memory.text = ''
      This is the `private` host. When running NixOS rebuild or evaluating flake outputs, use `private` as the host name (e.g. `nixos-rebuild switch --flake ~/nixos-config#private`).
    '';
  };

  home.shellAliases = {
    nixswitch = "sudo nixos-rebuild switch --flake ~/nixos-config#private";
    nixtest = "sudo nixos-rebuild test --flake ~/nixos-config#private";
  };
}
