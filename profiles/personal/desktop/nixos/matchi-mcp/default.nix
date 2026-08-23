# Matchi MCP server, exposed over Tailscale Funnel behind a secret URL path.
#
# Matchi has no personal API -- its /api is the venue partner API and needs a
# key -- so the bookings pages are parsed. Auth is the Keycloak SSO cookies
# lifted out of Firefox by `matchi-mcp-login`; hitting a protected page with
# them completes the redirect dance and lands logged in.
#
# Read-only on purpose. Booking and cancelling both cost money or lose a court,
# so with the secret URL as the only credential, anyone holding it can look at
# the calendar and nothing else.
#
#   claude mcp add --transport http matchi https://<host>/<secret>/mcp
{ pkgs, ... }:
let
  port = 8767;
  stateDir = "/var/lib/matchi-mcp";
  pathFile = "${stateDir}/funnel-path";
  # Scrapling's element fingerprints. Its own directory so the cookie next to it
  # can stay read-only to the service.
  adaptiveDir = "${stateDir}/adaptive";
  user = "matchi-mcp";

  # Only the modules the server imports, so editing the README does not rebuild
  # the service.
  src = pkgs.runCommand "matchi-mcp-src" { } ''
    install -Dm444 ${./client.py} $out/client.py
    install -Dm444 ${./server.py} $out/server.py
    install -Dm444 ${./keepalive.py} $out/keepalive.py
  '';

  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.fastmcp
    ps.httpx
    (ps.callPackage ./scrapling.nix { })
  ]);
  # The cookie import needs no parser or HTTP client, just the stdlib.
  loginEnv = pkgs.python3;

  # Runs as the desktop user, because that is who owns the Firefox profile, and
  # then hands the cookie to the service account.
  loginScript = pkgs.writeShellApplication {
    name = "matchi-mcp-login";
    runtimeInputs = [
      loginEnv
      pkgs.coreutils
    ];
    text = ''
      # The setuid wrapper, not a store path: nothing in the store is setuid.
      SUDO=/run/wrappers/bin/sudo

      # Written somewhere the desktop user can reach, then installed into the
      # root-only state dir. The cookie never sits in a world-readable path.
      tmp=$(mktemp -d)
      trap 'rm -rf "$tmp"' EXIT

      # KEYCLOAK_IDENTITY is the SSO session -- without it the matchi.se
      # cookies alone cannot re-establish a login.
      python ${./firefox_cookies.py} \
        --host-like '%matchi%' \
        --require KEYCLOAK_IDENTITY \
        "$tmp/storage_state.json"

      "$SUDO" install -o ${user} -g ${user} -m 600 \
        "$tmp/storage_state.json" ${stateDir}/storage_state.json

      "$SUDO" systemctl restart matchi-mcp.service
      echo "checking the session..."
      sleep 2
      ${pkgs.curl}/bin/curl -sS http://127.0.0.1:${toString port}/readyz; echo
    '';
  };

  hardening = {
    User = user;
    Group = user;
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateDevices = true;
    NoNewPrivileges = true;
    CapabilityBoundingSet = "";
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    SystemCallFilter = [
      "@system-service"
      "~@privileged"
      "~@resources"
    ];
    RestrictAddressFamilies = [
      "AF_INET"
      "AF_INET6"
      "AF_UNIX"
    ];
  };
in
{
  users.users.${user} = {
    isSystemUser = true;
    group = user;
    description = "Matchi MCP server";
  };
  users.groups.${user} = { };

  environment.systemPackages = [ loginScript ];

  # storage_state.json is deliberately absent: it is written by the login
  # script and should not be conjured empty. funnel-path is created by hand so
  # the secret never passes through the nix store, and its absence should fail
  # loudly.
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 ${user} ${user} -"
    "d ${adaptiveDir} 0700 ${user} ${user} -"
  ];

  systemd.services.matchi-mcp = {
    description = "Matchi MCP server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    environment = {
      PYTHONPATH = "${src}";
      PYTHONDONTWRITEBYTECODE = "1";
      MATCHI_MCP_STATE_DIR = stateDir;
      MATCHI_MCP_PORT = toString port;
    };

    serviceConfig = hardening // {
      Restart = "always";
      RestartSec = 10;
      ExecStart = "${pythonEnv}/bin/python ${src}/server.py";
      # The cookie stays read-only here; refreshing it is the keepalive unit's
      # job, so only scrapling's fingerprint store is writable, which is the
      # whole reason this service can write at all.
      ReadOnlyPaths = [ stateDir ];
      ReadWritePaths = [ adaptiveDir ];
      MemoryMax = "384M";
      TasksMax = 64;
      SyslogIdentifier = "matchi-mcp";
    };
  };

  # Keycloak re-issues the identity cookie on every SSO hop, so a session that
  # keeps being used may outlive the fortnight the browser's cookie was good
  # for. This is the only unit allowed to write the cookie, which is why the
  # server itself keeps the state dir read-only. See keepalive.py for what is
  # and is not known about whether this actually removes the manual login.
  systemd.services.matchi-mcp-keepalive = {
    description = "Refresh the Matchi SSO session cookie";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    environment = {
      PYTHONPATH = "${src}";
      PYTHONDONTWRITEBYTECODE = "1";
      MATCHI_MCP_STATE_DIR = stateDir;
    };

    serviceConfig = hardening // {
      Type = "oneshot";
      ExecStart = "${pythonEnv}/bin/python ${src}/keepalive.py";
      ReadWritePaths = [ stateDir ];
      SyslogIdentifier = "matchi-mcp-keepalive";
    };
  };

  # Daily, not weekly: if the fortnight is an idle timeout then daily keeps it
  # alive with a wide margin, and if it is not, a daily failure surfaces the
  # dead session within a day of it happening.
  systemd.timers.matchi-mcp-keepalive = {
    description = "Refresh the Matchi SSO session cookie daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  services.mcpFunnel.services.matchi = { inherit port pathFile; };
}
