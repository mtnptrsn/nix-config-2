{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.homeassistant;

  curl = "${pkgs.curl}/bin/curl";

  ha = pkgs.writeShellScriptBin "ha" ''
    usage() {
      echo "Usage: ha <room> <percentage|off>"
      echo ""
      echo "Rooms: bathroom, bedroom, hallway, living, all"
      echo "Percentage: 0-100 or 'off'"
    }

    if [ "$#" -lt 1 ] || [ "$1" = "help" ]; then
      usage
      exit 0
    fi

    if [ "$#" -ne 2 ]; then
      usage
      exit 1
    fi

    room="$1"
    level="$2"

    case "$room" in
      bathroom) target='{"area_id": "bathroom"}' ;;
      bedroom)  target='{"area_id": "bedroom"}' ;;
      hallway)  target='{"area_id": "hallway"}' ;;
      living)   target='{"area_id": "living_room"}' ;;
      all)      target='{"entity_id": "light.all_lights"}' ;;
      *)
        echo "Unknown room: $room"
        usage
        exit 1
        ;;
    esac

    if [ "$level" = "0" ] || [ "$level" = "off" ]; then
      service="light/turn_off"
      data="$target"
    else
      service="light/turn_on"
      data=$(echo "$target" | ${pkgs.jq}/bin/jq -c ". + {brightness_pct: $level}")
    fi

    response=$(${curl} -s -w "\n%{http_code}" -X POST "${cfg.url}/api/services/$service" \
      -H "Authorization: Bearer ${cfg.token}" \
      -H "Content-Type: application/json" \
      -d "$data")
    http_code=$(echo "$response" | tail -n1)
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
      exit 0
    else
      body=$(echo "$response" | ${pkgs.coreutils}/bin/head -n -1)
      echo "Error ($http_code): $body" >&2
      exit 1
    fi
  '';
in
{
  options.modules.homeassistant = {
    enable = lib.mkEnableOption "homeassistant";
    url = lib.mkOption {
      type = lib.types.str;
      description = "Home Assistant base URL.";
    };
    token = lib.mkOption {
      type = lib.types.str;
      description = "Home Assistant long-lived access token.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      ha
      pkgs.curl
    ];

    programs.zsh.initContent = lib.mkIf config.modules.zsh.enable ''
      _ha() {
        local -a rooms levels
        rooms=(bathroom bedroom hallway living all help)
        levels=(0 20 50 100 off)
        if (( CURRENT == 2 )); then
          _describe 'room' rooms
        elif (( CURRENT == 3 )); then
          _describe 'level' levels
        fi
      }
      compdef _ha ha
    '';
  };
}
