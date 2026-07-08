{ pkgs, ... }:

let
  # Monitor config for the GDM greeter, mirroring the user's ~/.config/monitors.xml.
  # Kept declarative (rather than symlinked) because the user's home is 0700 and
  # the gdm user cannot traverse into it. Update this if display setup changes.
  gdmMonitorsXml = pkgs.writeText "monitors.xml" ''
    <monitors version="2">
      <configuration>
        <layoutmode>physical</layoutmode>
        <logicalmonitor>
          <x>0</x>
          <y>0</y>
          <scale>1</scale>
          <primary>yes</primary>
          <monitor>
            <monitorspec>
              <connector>DP-1</connector>
              <vendor>AUS</vendor>
              <product>PG279QE</product>
              <serial>#ASOtvTdc/lnd</serial>
            </monitorspec>
            <mode>
              <width>2560</width>
              <height>1440</height>
              <rate>143.998</rate>
            </mode>
          </monitor>
        </logicalmonitor>
      </configuration>
      <configuration>
        <layoutmode>physical</layoutmode>
        <logicalmonitor>
          <x>0</x>
          <y>0</y>
          <scale>1</scale>
          <primary>yes</primary>
          <monitor>
            <monitorspec>
              <connector>DP-1</connector>
              <vendor>AOC</vendor>
              <product>24G2W1G4</product>
              <serial>0x0000861d</serial>
            </monitorspec>
            <mode>
              <width>1920</width>
              <height>1080</height>
              <rate>144.001</rate>
            </mode>
          </monitor>
        </logicalmonitor>
      </configuration>
    </monitors>
  '';
in
{
  # GTK3 schemas needed by Qt apps using the GTK file dialog on GNOME
  environment.systemPackages = with pkgs; [ gtk3 ];

  # GNOME Desktop Environment
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "mtnptrsn";
  services.desktopManager.gnome.enable = true;

  # Give the GDM greeter the same monitor config as the user session so the
  # display comes up at 144Hz on boot. Without this GDM initializes at 60Hz
  # and, with autologin, the session doesn't reliably switch to 144Hz.
  systemd.tmpfiles.rules = [
    "L+ /run/gdm/.config/monitors.xml - - - - ${gdmMonitorsXml}"
  ];

  # Printing
  services.printing.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
