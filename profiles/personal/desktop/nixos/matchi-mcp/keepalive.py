"""Touch a protected page so the SSO session keeps being used, and save the
cookies Keycloak hands back.

The browser's KEYCLOAK_IDENTITY cookie is good for a fortnight from login, and
remember-me does not quietly re-authenticate: dropping the identity cookie
lands on the auth.matchi.com login screen even with KEYCLOAK_REMEMBER_ME still
present. What Keycloak does do is re-issue the identity cookie on each SSO hop,
so using the session and keeping the result is the only lever available without
storing a password.

Whether that extends the session indefinitely depends on whether Keycloak's
remember-me window is an idle timeout or a hard maximum, which is not visible
from out here. If it is idle, this unit running daily keeps the login alive for
good. If it is a maximum, the session still dies a fortnight after login -- and
then this unit fails, which is the point: the failure is what says to run
`matchi-mcp-login` again, rather than a tool call dying when it is next needed.
"""

from __future__ import annotations

import sys

from client import PAYMENTS_PATH, MatchiClient, MatchiError


def main() -> int:
    try:
        with MatchiClient() as client:
            # fetch() raises SessionExpired when the redirect dance ends at a
            # login screen, so reaching the next line means we are logged in.
            # The page is not parsed: this only needs to know the session works,
            # and parsing would drag in the adaptive store for no reason.
            page = client.fetch(PAYMENTS_PATH)
            client.save_session()
    except MatchiError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    print(f"session refreshed ({len(page)} bytes from {PAYMENTS_PATH})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
