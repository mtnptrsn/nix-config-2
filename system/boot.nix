{ pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Latest kernel for RDNA 4 (RX 9060 XT) support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Unlock all AMD GPU power management features
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
}
