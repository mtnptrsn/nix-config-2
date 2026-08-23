# Publishes local MCP servers over Tailscale Funnel, each behind a secret URL
# path segment.
#
# There is no OAuth anywhere: the only gate is a high-entropy path read from a
# root-only file outside git and the nix store. tailscaled serves that prefix
# and 404s everything else, so scanners that find this hostname in Certificate
# Transparency logs never reach a server.
#
# One unit for all of them on purpose. `tailscale serve reset` clears the whole
# host's serve config, so a per-service unit would tear down its neighbours'
# paths every time it started. Resetting once and then republishing every path
# is what keeps a rotated secret from leaving the old path mounted alongside
# the new one.
{
  config,
  lib,
  ...
}:
let
  cfg = config.services.mcpFunnel;
  tailscale = "${config.services.tailscale.package}/bin/tailscale";

  entries = lib.attrValues (lib.mapAttrs (name: value: value // { inherit name; }) cfg.services);
in
{
  options.services.mcpFunnel.services = lib.mkOption {
    default = { };
    description = ''
      MCP servers to publish, keyed by name. Each is served at
      https://<host>/<contents of pathFile>/ and proxied to 127.0.0.1:<port>.
    '';
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            description = "Loopback port the server listens on.";
          };
          pathFile = lib.mkOption {
            type = lib.types.str;
            description = ''
              File holding the secret URL segment. Created by hand so the
              secret never passes through the nix store; the unit fails loudly
              if it is missing or empty.
            '';
          };
        };
      }
    );
  };

  # Requires the `funnel` nodeAttr in the tailnet policy file, HTTPS certs
  # enabled for the tailnet, and a one-time approval at the URL tailscale
  # prints to the journal on first run.
  config = lib.mkIf (cfg.services != { }) {
    systemd.services.mcp-funnel = {
      description = "Expose local MCP servers over Tailscale Funnel";
      wantedBy = [ "multi-user.target" ];
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 30;
      };

      # Every path file is checked before anything is published, so a missing
      # secret cannot leave the host with half its funnels up.
      script = ''
        ${lib.concatMapStringsSep "\n" (e: ''
          if [ ! -s ${e.pathFile} ]; then
            echo "${e.pathFile} is missing or empty -- generate it with:" >&2
            echo "  nix run nixpkgs#openssl -- rand -hex 24 | sudo tee ${e.pathFile} >/dev/null" >&2
            exit 1
          fi
        '') entries}

        ${tailscale} serve reset || true

        ${lib.concatMapStringsSep "\n" (e: ''
          echo "publishing ${e.name} on port ${toString e.port}"
          ${tailscale} funnel --bg --set-path="/$(cat ${e.pathFile})" http://127.0.0.1:${toString e.port}
        '') entries}
      '';

      preStop = "${tailscale} serve reset || true";
    };
  };
}
