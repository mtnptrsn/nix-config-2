# Splitwise MCP server, exposed over Tailscale Funnel behind a secret URL path.
#
# Splitwise's documented API needs a paid Pro subscription. Its own web app
# does not: it calls the same /api/v3.0 endpoints with a session cookie, which
# `splitwise-mcp-login` captures once with a real browser. That cookie is the
# only credential the service holds.
#
# Publishing works exactly like garmin-mcp: the shared nixos/mcp-funnel.nix
# serves one high-entropy path and tailscaled 404s everything else, so anyone
# holding the URL gets the four tools in server.py and nothing more. There is
# deliberately no delete tool.
#
#   claude mcp add --transport http splitwise https://<host>/<secret>/mcp
{ pkgs, ... }:
let
  port = 8766;
  stateDir = "/var/lib/splitwise-mcp";
  pathFile = "${stateDir}/funnel-path";
  user = "splitwise-mcp";

  # Only the modules the server imports, so editing the README does not rebuild
  # the service.
  src = pkgs.runCommand "splitwise-mcp-src" { } ''
    install -Dm444 ${./client.py} $out/client.py
    install -Dm444 ${./server.py} $out/server.py
    install -Dm444 ${./refresh_cache.py} $out/refresh_cache.py
  '';

  # No browser anywhere: the cookie comes out of Firefox's own database, so
  # sqlite3 from the stdlib is the whole dependency.
  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.fastmcp
    ps.httpx
  ]);

  # Runs as the desktop user, because that is who owns the Firefox profile, and
  # then hands the cookie to the service account.
  loginScript = pkgs.writeShellApplication {
    name = "splitwise-mcp-login";
    runtimeInputs = [
      pythonEnv
      pkgs.coreutils
    ];
    text = ''
      # The setuid wrapper, not a store path: nothing in the store is setuid.
      SUDO=/run/wrappers/bin/sudo

      # Written somewhere the desktop user can reach, then installed into the
      # root-only state dir. The cookie never sits in a world-readable path.
      tmp=$(mktemp -d)
      trap 'rm -rf "$tmp"' EXIT

      python ${./import_cookies.py} "$tmp/storage_state.json"

      "$SUDO" install -o ${user} -g ${user} -m 600 \
        "$tmp/storage_state.json" ${stateDir}/storage_state.json

      echo "Refreshing the group cache..."
      "$SUDO" systemctl restart splitwise-mcp.service
      "$SUDO" systemctl start splitwise-mcp-refresh-cache.service
      "$SUDO" systemctl status --no-pager splitwise-mcp-refresh-cache.service || true
    '';
  };

  # Shared by the server and the cache refresher. ProtectSystem=strict makes
  # the whole filesystem read-only, which is why writers name ReadWritePaths.
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
    MemoryDenyWriteExecute = true;
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

  serviceEnv = {
    PYTHONPATH = "${src}";
    PYTHONDONTWRITEBYTECODE = "1";
    SPLITWISE_MCP_STATE_DIR = stateDir;
  };
in
{
  users.users.${user} = {
    isSystemUser = true;
    group = user;
    description = "Splitwise MCP server";
  };
  users.groups.${user} = { };

  environment.systemPackages = [ loginScript ];

  # storage_state.json and cache.json are deliberately absent: the first is
  # written by the login script, the second by the refresh unit, and neither
  # should be conjured empty. funnel-path is created by hand so the secret
  # never passes through the nix store, and its absence should fail loudly.
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 ${user} ${user} -"
  ];

  systemd.services.splitwise-mcp = {
    description = "Splitwise MCP server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    environment = serviceEnv;

    serviceConfig = hardening // {
      Restart = "always";
      RestartSec = 10;
      ExecStart = "${pythonEnv}/bin/python ${src}/server.py";
      # Read-only: the server never writes state, it only reads the cookie and
      # the cache. Writes -- the cache and the refreshed cookie both -- are the
      # refresh unit's job.
      ReadOnlyPaths = [ stateDir ];
      MemoryMax = "256M";
      TasksMax = 64;
      SyslogIdentifier = "splitwise-mcp";
      Environment = [ "SPLITWISE_MCP_PORT=${toString port}" ];
    };
  };

  # Resolving "Ebbe" to a user id from a cache is what lets one sentence turn
  # into one write. Weekly is enough -- group membership rarely changes, and
  # this also runs by hand (and after a login) when it does.
  #
  # It is also the session keepalive: its requests come back with a fresh
  # session cookie, and this is the one unit allowed to write the state dir, so
  # it saves the cookie too. That is why the timer matters even in a week when
  # no group changed.
  systemd.services.splitwise-mcp-refresh-cache = {
    description = "Refresh the Splitwise group and member cache and session cookie";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    environment = serviceEnv;

    serviceConfig = hardening // {
      Type = "oneshot";
      ExecStart = "${pythonEnv}/bin/python ${src}/refresh_cache.py";
      ReadWritePaths = [ stateDir ];
      SyslogIdentifier = "splitwise-mcp-refresh-cache";
    };
  };

  systemd.timers.splitwise-mcp-refresh-cache = {
    description = "Refresh the Splitwise cache and session cookie weekly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  services.mcpFunnel.services.splitwise = { inherit port pathFile; };

}
