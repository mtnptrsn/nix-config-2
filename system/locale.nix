{ lib, ... }:

let
  sv = "sv_SE.UTF-8";
in
{
  # Timezone
  time.timeZone = "Europe/Stockholm";

  # Internationalisation
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = lib.genAttrs [
    "LC_ADDRESS"
    "LC_IDENTIFICATION"
    "LC_MEASUREMENT"
    "LC_MONETARY"
    "LC_NAME"
    "LC_NUMERIC"
    "LC_PAPER"
    "LC_TELEPHONE"
    "LC_TIME"
  ] (_: sv);

  # Keyboard layout
  services.xserver.xkb = {
    layout = "se";
    variant = "";
  };

  # Console keymap
  console.keyMap = "sv-latin1";
}
