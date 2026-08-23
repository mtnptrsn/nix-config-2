# Garmin MCP

A Garmin Connect MCP server, running as a docker container on loopback and
published over Tailscale Funnel behind a secret URL path. `default.nix` holds
the service unit and the near-read-only tool allowlist; publishing is shared
with the other MCPs in `nixos/mcp-funnel.nix`. `Dockerfile` pins the upstream
commit.

## Files and state

| Path                                 | What                                                                                         |
| ------------------------------------ | -------------------------------------------------------------------------------------------- |
| `/var/lib/garmin-mcp/funnel-path`    | The secret URL segment. Root-only, created by hand, never in git or the nix store.           |
| `/var/lib/garmin-mcp/garminconnect/` | Garmin OAuth token cache, mounted into the container writable so garth can refresh in place. |
| `garmin-mcp:local`                   | The docker image, built out-of-band (nix does not build it).                                 |

## Setup

All commands run from the repo root.

1. Build the image (also after bumping the pinned commit in the `Dockerfile`):

   ```bash
   just garmin-image
   ```

2. Generate the secret path segment:

   ```bash
   sudo install -d -m 700 /var/lib/garmin-mcp
   nix run nixpkgs#openssl -- rand -hex 24 | sudo tee /var/lib/garmin-mcp/funnel-path >/dev/null
   sudo chmod 600 /var/lib/garmin-mcp/funnel-path
   ```

   `mcp-funnel.service` fails loudly if this file is missing or empty.

3. Log in to Garmin once to seed the token cache (prompts for email, password
   and MFA code):

   ```bash
   sudo docker run --rm -it \
     -v /var/lib/garmin-mcp/garminconnect:/root/.garminconnect \
     garmin-mcp:local garmin-mcp-auth
   ```

4. Apply and start:

   ```bash
   sudo nixos-rebuild switch --flake .#personal-desktop
   ```

   Funnel needs the `funnel` nodeAttr in the tailnet policy file and HTTPS
   certs enabled; the first run prints an approval URL to the journal.

## Connecting

Print the full URL:

```bash
echo "https://$(tailscale status --json | jq -r .Self.DNSName | sed 's/\.$//')/$(sudo cat /var/lib/garmin-mcp/funnel-path)/mcp"
```

Then add it:

```bash
claude mcp add --transport http garmin <url>
```

Works from Claude Code, Claude Desktop and as a claude.ai custom connector --
no OAuth anywhere, the secret path is the only credential.

## Operations

```bash
systemctl status garmin-mcp mcp-funnel
journalctl -u garmin-mcp -f
curl -fsS http://127.0.0.1:8765/healthz   # loopback health check
tailscale serve status                    # which path is published
```

To rotate the secret, overwrite `funnel-path` and
`sudo systemctl restart mcp-funnel` (the unit runs `serve reset` first,
so the old path is not left mounted alongside the new one).
