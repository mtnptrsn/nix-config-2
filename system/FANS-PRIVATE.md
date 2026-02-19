# Fan PWM Mapping — `private` host (nct6799)

hwmon path: `/sys/class/hwmon/hwmon1/`

| PWM  | Physical Location |
|------|-------------------|
| pwm1 | Top fan           |
| pwm2 | CPU fan           |
| pwm3 | All bottom fans   |
| pwm4 | Unused            |

## Manual Control

Set to 100%:
```bash
sudo sh -c 'echo 1 > /sys/class/hwmon/hwmon1/pwmN_enable && echo 255 > /sys/class/hwmon/hwmon1/pwmN'
```

Restore to auto:
```bash
sudo sh -c 'echo 5 > /sys/class/hwmon/hwmon1/pwmN_enable'
```

Replace `N` with the PWM number (1-3).
