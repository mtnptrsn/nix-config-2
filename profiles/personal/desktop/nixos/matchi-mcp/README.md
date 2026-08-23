# Matchi MCP

An MCP server for reading Matchi court bookings, running on loopback and
published over Tailscale Funnel behind a secret URL path.

Matchi has no personal API. `www.matchi.se` is a server-rendered Spring app
behind Keycloak SSO at `auth.matchi.com`, and its `/api` is the venue partner
API -- it needs a key and does not expose personal bookings. So the bookings
pages are parsed.

**Read-only.** Booking and cancelling both cost money or lose a court, so
neither is exposed. With the secret URL as the only credential, anyone holding
it can look at the calendar and nothing else.

## Files and state

| Path                                     | What                                                                        |
| ---------------------------------------- | --------------------------------------------------------------------------- |
| `/var/lib/matchi-mcp/funnel-path`        | The secret URL segment. Root-only, created by hand, never in git or the nix store. |
| `/var/lib/matchi-mcp/storage_state.json` | The Keycloak SSO cookies. The only credential the service holds.            |
| `/var/lib/matchi-mcp/adaptive/`          | Scrapling's element fingerprints, one file per page. The only writable path the service has. |

`client.py` holds the HTTP client and the parser; `server.py` the one tool;
`firefox_cookies.py` the cookie import; `scrapling.nix` packages Scrapling,
which nixpkgs does not carry. `test_client.py` covers the parser against
fixtures of the real markup, with no network and no account data.

## Tools

| Tool            | Args                          | What                                    |
| --------------- | ----------------------------- | --------------------------------------- |
| `list_bookings` | `limit=20`, `since=None`      | Court bookings and what each one cost.   |

That is the whole surface. It is read from Matchi's payment history, which is
the only page carrying an amount -- the bookings pages show a payment status and
never a price. Upcoming and past sessions come back together, so comparing
`date` against today is enough to tell them apart.

Fields: `reference`, `kind`, `date`, `start_time`, `end_time`, `venue`,
`amount`, `currency`, `payment_method`, `reserved_on`, `payment_text`.

Two need care:

- **`venue`** holds the facility and court together, exactly as Matchi writes
  it (`Malmö BadmintonCenter Bana 7 (SH)`). Nothing in the string marks where
  the venue ends, so splitting it would be guesswork.
- **`payment_text`** is Matchi's own wording for whether money has moved --
  `was withdrawn from your account 2026-08-23` versus `is reserved since
  2026-08-23`. It is passed through rather than parsed into a status, because
  the phrasing is language-dependent.

**When a booking was made** is only partly available. `reserved_on` carries it
while a payment is still reserved. Once settled, Matchi shows only the
withdrawal date -- normally the day *after* the session -- so `reserved_on` is
left null rather than filled with a date that is not the booking date. The
printable receipt is a compressed PDF and was not worth a PDF dependency.

## Parsing

Three things keep this from being brittle:

- **One fingerprint store per page.** Scrapling keys a saved element on the
  registered domain plus the selector string, *not* the full URL. The payments
  and past-bookings lists both live on `matchi.se` under near-identical
  list-group markup, so a shared store would let one page's fingerprint
  relocate the other's rows. Hence `adaptive/past.db`, `adaptive/payments.db`
  and so on.
- **Adaptive selectors.** Scrapling fingerprints the rows on a good run and
  relocates them if Matchi renames a class. Verified: renaming both
  `list-group-item` and `list-group alt` takes the plain selector to 0 rows and
  the adaptive one still recovers all 10.
- **Row validation.** A row counts only if it carries an amount, so a bad
  relocation is dropped instead of reported as a booking.

## Setup

All commands run from the repo root.

1. Create the state dir and generate the secret path segment:

   ```bash
   sudo install -d -m 700 /var/lib/matchi-mcp
   nix run nixpkgs#openssl -- rand -hex 24 | sudo tee /var/lib/matchi-mcp/funnel-path >/dev/null
   sudo chmod 600 /var/lib/matchi-mcp/funnel-path
   ```

   `mcp-funnel.service` fails loudly if this file is missing or empty.

2. Apply:

   ```bash
   sudo nixos-rebuild switch --flake .#personal-desktop
   ```

3. Log in at <https://www.matchi.se> in Firefox, then import the cookies:

   ```bash
   matchi-mcp-login
   ```

   It picks the Firefox profile holding a `KEYCLOAK_IDENTITY` cookie, prints
   when that session expires, restarts the service and checks `/readyz`.

## Connecting

```bash
echo "https://$(tailscale status --json | jq -r .Self.DNSName | sed 's/\.$//')/$(sudo cat /var/lib/matchi-mcp/funnel-path)/mcp"
claude mcp add --transport http matchi <url>
```

## Operations

```bash
systemctl status matchi-mcp mcp-funnel
journalctl -u matchi-mcp -f
curl -fsS http://127.0.0.1:8767/healthz   # is the process up
curl -sS  http://127.0.0.1:8767/readyz    # is the Matchi session still valid
```

`/readyz` returns 503 with the reason when the SSO session has died, which is
the quickest way to tell a dead session from a dead server. The fix is to log
in again in Firefox and re-run `matchi-mcp-login`.

To rotate the secret, overwrite `funnel-path` and
`sudo systemctl restart mcp-funnel`.

## When Matchi changes the page

The adaptive selectors handle renamed classes. A real redesign -- different
columns, a different date format -- needs new code. The signal is `list_bookings`
returning `[]` while the site shows payments. Capture the page and compare it
against the table above:

```bash
curl -s -b "$(...)" https://www.matchi.se/profile/payments > /tmp/page.html
```

Easier in practice: re-run the parsers over a saved page with
`parse_payments(open("page.html").read())` and see what drops out.
