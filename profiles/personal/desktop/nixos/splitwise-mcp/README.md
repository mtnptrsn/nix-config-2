# Splitwise MCP

An MCP server for reading and adding Splitwise expenses, running on loopback and
published over Tailscale Funnel behind a secret URL path.

Splitwise's documented API needs a paid Pro subscription. Its own web app does
not: it calls the same `/api/v3.0` endpoints with a session cookie. So you log
in to Splitwise in Firefox as usual, `splitwise-mcp-login` lifts the cookie out
of that profile, and the server replays it over plain HTTP.

No browser automation: Cloudflare fingerprints a Playwright-driven browser and
blocks the login. Reading the cookie out of a browser that logged in by hand
gives a bot check nothing to notice.

Group names and members are cached on disk, so "badminton with Ebbe, 200 kr"
resolves `Ebbe` to a user id and becomes a single write.

## Files and state

| Path                                        | What                                                                        |
| ------------------------------------------- | --------------------------------------------------------------------------- |
| `/var/lib/splitwise-mcp/funnel-path`        | The secret URL segment. Root-only, created by hand, never in git or the nix store. |
| `/var/lib/splitwise-mcp/storage_state.json` | The Splitwise session cookie. The only credential the service holds.        |
| `/var/lib/splitwise-mcp/cache.json`         | Groups and members, written by `refresh_cache.py`.                          |

`client.py` holds the HTTP client and the pure helpers that decide where money
goes; `server.py` the four tools; `import_cookies.py` the Firefox cookie
import; `refresh_cache.py` the cache refresh. `test_client.py` covers name
resolution and share arithmetic without touching the network.

## Tools

| Tool                   | What                                                              |
| ---------------------- | ----------------------------------------------------------------- |
| `list_groups`          | Groups and member names, from the cache.                          |
| `list_members`         | One group's members with user ids, from the cache.                |
| `list_recent_expenses` | Recent expenses in a group, live. Use it to verify a write.       |
| `create_expense`       | The one write.                                                    |

There is deliberately no delete tool: the secret URL is the only credential, so
anyone holding it gets exactly this list.

Ambiguous names are refused rather than guessed. `Ebb` when a group holds both
Ebbe and Ebba raises an error listing both, because putting money on the wrong
person is worse than failing.

## Setup

All commands run from the repo root.

1. Create the state dir and generate the secret path segment:

   ```bash
   sudo install -d -m 700 /var/lib/splitwise-mcp
   nix run nixpkgs#openssl -- rand -hex 24 | sudo tee /var/lib/splitwise-mcp/funnel-path >/dev/null
   sudo chmod 600 /var/lib/splitwise-mcp/funnel-path
   ```

   `mcp-funnel.service` fails loudly if this file is missing or empty.

2. Apply:

   ```bash
   sudo nixos-rebuild switch --flake .#personal-desktop
   ```

   Funnel needs the `funnel` nodeAttr in the tailnet policy file and HTTPS certs
   enabled; the first run prints an approval URL to the journal.

3. Log in at <https://secure.splitwise.com> in Firefox, then import the
   cookie:

   ```bash
   splitwise-mcp-login
   ```

   It searches every Firefox profile under `~/.config/mozilla/firefox` and
   `~/.mozilla/firefox`, picks the one holding a `user_credentials` cookie,
   prints when that cookie expires, and then restarts the service and seeds the
   group cache. Re-run it whenever the session expires -- log in again in
   Firefox first.

## Connecting

Print the full URL:

```bash
echo "https://$(tailscale status --json | jq -r .Self.DNSName | sed 's/\.$//')/$(sudo cat /var/lib/splitwise-mcp/funnel-path)/mcp"
```

Then add it:

```bash
claude mcp add --transport http splitwise <url>
```

Works from Claude Code, Claude Desktop and as a claude.ai custom connector --
no OAuth anywhere, the secret path is the only credential.

## Operations

```bash
systemctl status splitwise-mcp mcp-funnel
journalctl -u splitwise-mcp -f
curl -fsS http://127.0.0.1:8766/healthz   # is the process up
curl -fsS http://127.0.0.1:8766/readyz    # is the Splitwise session still valid
tailscale serve status                    # which paths are published
```

`/readyz` returns 503 with the reason when the cookie has expired, which is the
quickest way to tell a dead session from a dead server.

Refresh the member cache after adding someone to a group:

```bash
sudo systemctl start splitwise-mcp-refresh-cache
```

A weekly timer does the same unattended.

To rotate the secret, overwrite `funnel-path` and
`sudo systemctl restart mcp-funnel` (the unit runs `serve reset` first, so the
old path is not left mounted alongside the new one, and republishes every MCP).

## The web API

Undocumented and unversioned in practice, so it can change without notice --
that is the tradeoff for not paying for Pro. Two things to know if it breaks:

- Non-GET requests need Rails' CSRF token, scraped from the `csrf-token` meta
  tag on `/dashboard` and cached per process.
- Cloudflare sits in front of it. Plain `httpx` requests carrying a real
  session cookie get through; a CDP-driven browser does not.
- Shares must add up to the cost exactly, which is why `split_equally` pushes
  the rounding remainder onto the first shares.

When something starts failing, capture the request the web app itself makes
(devtools, Network tab) and compare it against `build_expense_params`.
