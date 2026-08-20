{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./cooling.nix
    ./virtualization.nix
    ./garmin-mcp
  ];

  services.flatpak.enable = true;
  services.flatpak.packages = [ "org.freecad.FreeCAD" ];

  networking.hostName = "mtnptrsn";
  networking.extraHosts = ''
    127.0.0.1 local.finch3d.com
  '';

  # Reach the finch dev servers from other tailnet devices (web 3000, admin 5555,
  # local API 8000). Scoped to tailscale0 so nothing is exposed on the LAN.
  # The web range covers the ports vite picks when several worktrees run at once.
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [
      5555
      8000
    ];
    allowedTCPPortRanges = [
      {
        from = 3000;
        to = 3010;
      }
    ];
  };
  # herdr is a system package so it is on PATH for non-interactive SSH sessions,
  # which is how `herdr --remote` finds the server binary. rsync is here for the
  # same reason: the macbook's capture-sync agent invokes it over SSH.
  environment.systemPackages = [
    pkgs.cowsay
    pkgs.herdr
    pkgs.rsync
  ];

  # Always-on herdr server: never suspend, and keep user processes running
  # after the last session ends.
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
  users.users.mtnptrsn.linger = true;

  # Gaming
  programs.steam.enable = true;
  programs.gamemode.enable = true;
}
