{ pkgs, ... }:

{
  # GPU and Vulkan support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Firmware and AMD microcode updates
  hardware.enableRedistributableFirmware = true;

  # macOS-like mouse acceleration
  hardware.maccel = {
    enable = true;
    enableCli = true;
    parameters = {
      sensMultiplier = 0.5;
      acceleration = 0.3;
      offset = 2.0;
      outputCap = 2.0;
    };
  };
  users.groups.maccel.members = [ "mtnptrsn" ];

  # CPU governor — performance mode for desktop
  powerManagement.cpuFreqGovernor = "performance";

  # Zram compressed swap
  zramSwap.enable = true;

  # SSD periodic TRIM
  services.fstrim.enable = true;
}
