# Fan PWM Mapping (nct6799)
#
# pwm1 — Top fan
# pwm2 — CPU fan
# pwm3 — All bottom fans
# pwm4 — Unused

{ pkgs, ... }:
{
  # Fan control — silent curve via nct6799 Super I/O auto-points
  boot.kernelModules = [ "nct6775" ];
  environment.systemPackages = [ pkgs.lm_sensors ];
  systemd.services.fan-curve = {
    description = "Set silent fan curve on nct6799";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Find the nct6799 hwmon device (hwmon number can change between boots)
      NCT=""
      for hwmon in /sys/class/hwmon/hwmon*; do
        if [ "$(cat "$hwmon/name" 2>/dev/null)" = "nct6799" ]; then
          NCT="$hwmon"
          break
        fi
      done
      if [ -z "$NCT" ]; then
        echo "nct6799 not found"
        exit 1
      fi

      # Enable Smart Fan IV (auto-point) mode for all controlled fans
      echo 5 > "$NCT/pwm1_enable"
      echo 5 > "$NCT/pwm2_enable"
      echo 5 > "$NCT/pwm3_enable"

      # CPU fan (PWM2) — responds to CPU temp (temp_sel=8)
      # Temps are in millidegrees, PWM 0-255
      echo 8 > "$NCT/pwm2_temp_sel"
      echo 50000 > "$NCT/pwm2_auto_point1_temp"
      echo 0     > "$NCT/pwm2_auto_point1_pwm"
      echo 60000 > "$NCT/pwm2_auto_point2_temp"
      echo 64    > "$NCT/pwm2_auto_point2_pwm"
      echo 75000 > "$NCT/pwm2_auto_point3_temp"
      echo 115   > "$NCT/pwm2_auto_point3_pwm"
      echo 85000 > "$NCT/pwm2_auto_point4_temp"
      echo 178   > "$NCT/pwm2_auto_point4_pwm"
      echo 95000 > "$NCT/pwm2_auto_point5_temp"
      echo 255   > "$NCT/pwm2_auto_point5_pwm"

      # Case fans: top + bottom (PWM1, PWM3) — respond to system temp (temp_sel=1)
      for pwm in 1 3; do
        echo 1     > "$NCT/pwm''${pwm}_temp_sel"
        echo 30000 > "$NCT/pwm''${pwm}_auto_point1_temp"
        echo 0     > "$NCT/pwm''${pwm}_auto_point1_pwm"
        echo 35000 > "$NCT/pwm''${pwm}_auto_point2_temp"
        echo 80    > "$NCT/pwm''${pwm}_auto_point2_pwm"
        echo 40000 > "$NCT/pwm''${pwm}_auto_point3_temp"
        echo 140   > "$NCT/pwm''${pwm}_auto_point3_pwm"
        echo 50000 > "$NCT/pwm''${pwm}_auto_point4_temp"
        echo 200   > "$NCT/pwm''${pwm}_auto_point4_pwm"
        echo 60000 > "$NCT/pwm''${pwm}_auto_point5_temp"
        echo 255   > "$NCT/pwm''${pwm}_auto_point5_pwm"
      done
    '';
  };
}
