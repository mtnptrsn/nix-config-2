"""Read Matchi payment history off the web app, with self-healing selectors.

Matchi has no personal API. www.matchi.se is a server-rendered Spring app
behind Keycloak SSO at auth.matchi.com, and its /api is the venue partner API,
which needs a key and does not expose personal data. So the page is parsed.

/profile/payments is the only page carrying an amount, which is the whole point
of this server: the bookings pages show a payment status and never a price. It
covers upcoming and past sessions alike, so the date is enough to tell them
apart.

Two things keep the parsing from being brittle. Scrapling's adaptive selectors
fingerprint the rows on a good run and relocate them if Matchi renames a class.
And a row counts only if it carries an amount, so a bad relocation is dropped
rather than reported as a payment.

Auth is the Keycloak cookies lifted out of Firefox: hitting a protected page
with them completes the SSO redirect dance and lands logged in.
"""

from __future__ import annotations

import json
import os
import re
from pathlib import Path

import httpx
from scrapling import Selector

BASE_URL = "https://www.matchi.se"
PAYMENTS_PATH = "/profile/payments"

STATE_DIR = Path(os.environ.get("MATCHI_MCP_STATE_DIR", "/var/lib/matchi-mcp"))
STORAGE_STATE = STATE_DIR / "storage_state.json"
# Scrapling's element fingerprints, in their own directory because this is the
# one piece of state that has to be writable.
#
# A directory of named stores rather than one file: scrapling keys a saved
# element on the registered domain plus the selector string, not the full URL,
# so any two pages on matchi.se queried with the same selector would overwrite
# each other. Naming the store per page keeps that impossible.
ADAPTIVE_DIR = STATE_DIR / "adaptive"

BROWSER_UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"
)

# Payment rows carry `row`; the bookings lists use `row row-full` on otherwise
# identical markup. The :not() is load-bearing -- a bare `.row` matches both,
# because a class selector only asks that the class be present.
PAYMENTS_SELECTOR = ".list-group.alt .list-group-item.row:not(.row-full)"

# "2026-08-27 21:00-22:00 ATL Victoriastadion B12". Venue and court stay joined:
# nothing in the string marks where the venue ends and the court begins, and
# "Malmö BadmintonCenter Bana 7 (SH)" shows why splitting on spaces would lie.
_PAYMENT_DESC = re.compile(
    r"(\d{4}-\d{2}-\d{2})\s+(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})\s+(.+)"
)
_AMOUNT = re.compile(r"(\d+(?:[.,]\d+)?)\s*([A-Z]{3})")
# "is reserved since 2026-08-23" -- the only place the booking date is visible.
# Settled rows carry only the withdrawal date, which is usually the day after
# the session, so no booking date is inferred for those.
_RESERVED_SINCE = re.compile(r"reserved\s+\w*\s*(\d{4}-\d{2}-\d{2})", re.I)


class MatchiError(Exception):
    """Anything the caller should see as a message rather than a traceback."""


class SessionExpired(MatchiError):
    def __init__(self) -> None:
        super().__init__(
            "Matchi session is no longer valid. Log in at https://www.matchi.se "
            "in Firefox, then run `matchi-mcp-login` to re-import the cookie."
        )


def load_cookies(path: Path = STORAGE_STATE) -> dict[str, str]:
    """Read the cookies firefox_cookies.py wrote.

    Both the matchi.se and auth.matchi.com cookies matter: the first is the app
    session, the second is what lets an expired one silently re-establish.
    """
    try:
        state = json.loads(path.read_text())
    except FileNotFoundError as exc:
        raise MatchiError(
            f"{path} does not exist -- run `matchi-mcp-login` first"
        ) from exc
    except json.JSONDecodeError as exc:
        raise MatchiError(f"{path} is not valid JSON: {exc}") from exc

    cookies = {c["name"]: c["value"] for c in state.get("cookies", [])}
    if not cookies:
        raise MatchiError(f"{path} holds no cookies -- log in again")
    return cookies


def _clean(text: str | None) -> str:
    """Collapse the whitespace Bootstrap templates leave behind."""
    return re.sub(r"\s+", " ", text or "").strip()


def _lines(element) -> list[str]:
    """An element's text as non-empty lines.

    The templates indent heavily, so a cell's text starts with a newline and
    naive splitting yields an empty first line. The description cell puts its
    kind first and the session detail second, so line order carries meaning.
    """
    return [_clean(line) for line in element.get_all_text().split("\n") if _clean(line)]


def _select_rows(
    html: str,
    url: str,
    selector: str,
    store: str,
    adaptive_dir: Path | None = None,
):
    """Run a selector, healing it if the markup moved.

    The plain selector goes first and saves its fingerprints when it matches.
    Adaptive relocation only runs when it finds nothing, so a page with no rows
    does not pay for a search it cannot satisfy.

    `store` names this page's own fingerprint file -- see ADAPTIVE_DIR.
    """
    storage_file = (adaptive_dir or ADAPTIVE_DIR) / f"{store}.db"
    storage_file.parent.mkdir(parents=True, exist_ok=True)
    page = Selector(
        html,
        adaptive=True,
        url=url,
        storage_args={"storage_file": str(storage_file)},
    )
    rows = page.css(selector, auto_save=True)
    if not rows:
        rows = page.css(selector, adaptive=True)
    return rows


def parse_payments(
    html: str,
    url: str = BASE_URL + PAYMENTS_PATH,
    adaptive_dir: Path | None = None,
) -> list[dict]:
    """Parse the payment history: Reference | Description | Payment | Receipt.

    `payment_text` is passed through verbatim on purpose. It is the authority on
    whether money has actually moved ("was withdrawn from your account" versus
    "is reserved since"), and those phrasings are language-dependent, so the
    wording is reported rather than parsed into a status of our own invention.
    """
    payments = []
    for row in _select_rows(html, url, PAYMENTS_SELECTOR, "payments", adaptive_dir):
        cells = [c for c in row.children if c.tag == "div"]
        if len(cells) < 3:
            continue

        pay_text = _clean(cells[2].get_all_text())
        amount = _AMOUNT.search(pay_text)
        if not amount:
            # No money in the row: a header, or a bad relocation.
            continue

        desc_lines = _lines(cells[1])
        kind = desc_lines[0] if desc_lines else None
        detail = _PAYMENT_DESC.search(" ".join(desc_lines[1:]))

        # The method is the first bold run; the rest of the cell is the status.
        method = _clean(cells[2].css("strong::text").get())
        status = _clean(pay_text.replace(amount.group(0), " "))
        if method:
            status = _clean(status.replace(method, " ", 1))
        reserved = _RESERVED_SINCE.search(pay_text)

        payments.append(
            {
                "reference": _clean(cells[0].get_all_text()) or None,
                "kind": kind,
                "date": detail.group(1) if detail else None,
                "start_time": detail.group(2) if detail else None,
                "end_time": detail.group(3) if detail else None,
                # Venue and court together -- see _PAYMENT_DESC.
                "venue": _clean(detail.group(4)) if detail else None,
                "amount": amount.group(1).replace(",", "."),
                "currency": amount.group(2),
                "payment_method": method or None,
                # Only present while a payment is still reserved; a settled row
                # shows the withdrawal date, which is not when it was booked.
                "reserved_on": reserved.group(1) if reserved else None,
                "payment_text": status or None,
            }
        )
    # Newest first, and rows with no session date (memberships and the like)
    # last rather than crashing the sort.
    return sorted(payments, key=lambda p: p["date"] or "", reverse=True)


class MatchiClient:
    def __init__(self, storage_state: Path = STORAGE_STATE, timeout: float = 30.0):
        # follow_redirects is essential rather than convenient: reaching a
        # protected page means bouncing through auth.matchi.com and back.
        self._http = httpx.Client(
            cookies=load_cookies(storage_state),
            timeout=timeout,
            follow_redirects=True,
            headers={
                "User-Agent": BROWSER_UA,
                "Accept": "text/html,application/xhtml+xml",
                "Accept-Language": "en",
            },
        )

    def close(self) -> None:
        self._http.close()

    def __enter__(self) -> MatchiClient:
        return self

    def __exit__(self, *_exc: object) -> None:
        self.close()

    def fetch(self, path: str) -> str:
        """GET a protected page, or say plainly that the session is gone.

        Landing anywhere other than www.matchi.se means the SSO dance ended at
        a login screen, which is the one failure worth distinguishing.
        """
        resp = self._http.get(BASE_URL + path)
        if resp.url.host != "www.matchi.se":
            raise SessionExpired()
        if resp.status_code >= 400:
            raise MatchiError(f"Matchi returned HTTP {resp.status_code} for {path}")
        return resp.text

    def payments(self) -> list[dict]:
        return parse_payments(self.fetch(PAYMENTS_PATH))
