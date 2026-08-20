{ pkgs, ... }:
{
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.docker.enable = true;
  users.users.mtnptrsn.extraGroups = [
    "libvirtd"
    "docker"
  ];

  environment.systemPackages = with pkgs; [
    qemu
  ];
}
