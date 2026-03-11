{ pkgs, ... }:
{
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  users.users.mtnptrsn.extraGroups = [ "libvirtd" ];

  environment.systemPackages = with pkgs; [
    qemu
  ];
}
