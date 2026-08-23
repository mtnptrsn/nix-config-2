"""Splitwise client that talks to the web app's own JSON API.

The official developer API needs Splitwise Pro. The web app at
secure.splitwise.com does not -- it calls the same /api/v3.0 endpoints with
nothing but a session cookie, which login.py captures once with a real browser.
That cookie is the only credential; everything here is plain HTTP.

Split into pure helpers (name resolution, share arithmetic, payload building)
and a thin HTTP layer, so the interesting parts are testable without a session.
"""

from __future__ import annotations

import datetime as dt
import json
import os
import re
from decimal import ROUND_DOWN, Decimal, InvalidOperation
from pathlib import Path
from typing import Any

import httpx

BASE_URL = "https://secure.splitwise.com"
API_URL = f"{BASE_URL}/api/v3.0"
# The single-page app, and the only page that carries a CSRF token. Everything
# else (/dashboard, /account) is a 404 -- the app routes on the fragment.
APP_URL = f"{BASE_URL}/"

STATE_DIR = Path(os.environ.get("SPLITWISE_MCP_STATE_DIR", "/var/lib/splitwise-mcp"))
STORAGE_STATE = STATE_DIR / "storage_state.json"
CACHE_FILE = STATE_DIR / "cache.json"

# Splitwise serves the SPA to browsers and JSON to XHR. Looking like the web
# app's own fetch() is what keeps these endpoints returning JSON.
BROWSER_UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"
)

_CSRF_RE = re.compile(
    r'<meta[^>]+name=["\']csrf-token["\'][^>]+content=["\']([^"\']+)["\']',
    re.IGNORECASE,
)

SELF_ALIASES = {"me", "i", "myself", "mig", "jag"}


class SplitwiseError(Exception):
    """Anything the caller should see as a message rather than a traceback."""


class SessionExpired(SplitwiseError):
    def __init__(self) -> None:
        super().__init__(
            "Splitwise session is no longer valid. Re-run `splitwise-mcp-login` "
            "on the desktop to refresh the cookie."
        )


# --- pure helpers -----------------------------------------------------------


def money(value: Any) -> Decimal:
    """Parse an amount into exactly two decimal places.

    Accepts "200", "200,50" (Swedish comma) and 200.5 alike.
    """
    if isinstance(value, str):
        # Swedish input: nbsp/thin-space thousands separators, decimal comma.
        for junk in (" ", " ", " "):
            value = value.replace(junk, "")
        value = value.strip().replace(",", ".")
    try:
        amount = Decimal(str(value))
    except InvalidOperation as exc:
        raise SplitwiseError(f"{value!r} is not an amount") from exc
    if amount <= 0:
        raise SplitwiseError(f"amount must be positive, got {amount}")
    return amount.quantize(Decimal("0.01"))


def split_equally(total: Decimal, count: int) -> list[Decimal]:
    """Split total into count shares that sum back to total exactly.

    Splitwise rejects an expense whose shares do not add up to the cost, so the
    rounding remainder has to land somewhere. It goes to the first shares,
    which is what the web UI does too.
    """
    if count < 1:
        raise SplitwiseError("cannot split between nobody")
    base = (total / count).quantize(Decimal("0.01"), rounding=ROUND_DOWN)
    shares = [base] * count
    remainder = total - base * count
    cents = int((remainder * 100).to_integral_value())
    for i in range(cents):
        shares[i % count] += Decimal("0.01")
    return shares


def _candidate_names(member: dict) -> list[str]:
    parts = [member.get("first_name"), member.get("name"), member.get("email")]
    return [p.casefold() for p in parts if p]


def _label(member: dict) -> str:
    return member.get("name") or member.get("first_name") or str(member.get("id"))


def resolve_member(group: dict, query: str, current_user_id: int | None = None) -> dict:
    """Find one group member by name, first name or email.

    Deliberately refuses to guess: an ambiguous or unknown name raises with the
    candidates listed. Putting money on the wrong person is worse than failing.
    """
    members = group.get("members", [])
    needle = (query or "").strip().casefold()
    if not needle:
        raise SplitwiseError("no name given")

    if needle in SELF_ALIASES:
        for m in members:
            if m.get("id") == current_user_id:
                return m
        raise SplitwiseError(
            f"you are not a member of {group.get('name')!r}, so 'me' cannot be resolved"
        )

    if needle.isdigit():
        for m in members:
            if str(m.get("id")) == needle:
                return m

    exact = [m for m in members if needle in _candidate_names(m)]
    if len(exact) == 1:
        return exact[0]
    if len(exact) > 1:
        raise SplitwiseError(
            f"{query!r} matches several members of {group.get('name')!r}: "
            + ", ".join(sorted(_label(m) for m in exact))
        )

    partial = [m for m in members if any(needle in n for n in _candidate_names(m))]
    if len(partial) == 1:
        return partial[0]
    if len(partial) > 1:
        raise SplitwiseError(
            f"{query!r} matches several members of {group.get('name')!r}: "
            + ", ".join(sorted(_label(m) for m in partial))
        )

    raise SplitwiseError(
        f"no member of {group.get('name')!r} matches {query!r}. Members are: "
        + ", ".join(_label(m) for m in members)
    )


def resolve_group(cache: dict, query: str) -> dict:
    """Find one group by id or name, refusing to guess between several."""
    groups = cache.get("groups", [])
    if not groups:
        raise SplitwiseError(
            "the group cache is empty -- run `systemctl start splitwise-mcp-refresh-cache`"
        )
    needle = (query or "").strip().casefold()
    if not needle:
        raise SplitwiseError("no group given")

    if needle.isdigit():
        for g in groups:
            if str(g.get("id")) == needle:
                return g

    exact = [g for g in groups if (g.get("name") or "").casefold() == needle]
    if len(exact) == 1:
        return exact[0]

    partial = [g for g in groups if needle in (g.get("name") or "").casefold()]
    if len(partial) == 1:
        return partial[0]
    if len(partial) > 1:
        raise SplitwiseError(
            f"{query!r} matches several groups: "
            + ", ".join(sorted(str(g.get("name")) for g in partial))
        )

    raise SplitwiseError(
        f"no group matches {query!r}. Groups are: "
        + ", ".join(str(g.get("name")) for g in groups)
    )


def build_expense_params(
    *,
    group_id: int,
    description: str,
    cost: Decimal,
    currency: str,
    date: str,
    payer_id: int,
    owed: list[tuple[int, Decimal]],
) -> dict[str, str]:
    """Flatten an expense into the users__N__* form params the API expects.

    The payer is guaranteed a row even when they owe nothing, since paid_share
    has to sum to the cost.
    """
    owed_total = sum((share for _, share in owed), Decimal("0"))
    if owed_total != cost:
        raise SplitwiseError(
            f"shares add up to {owed_total} but the expense is {cost} -- they must match"
        )

    rows: list[tuple[int, Decimal, Decimal]] = []
    seen: set[int] = set()
    for user_id, share in owed:
        if user_id in seen:
            raise SplitwiseError(f"user {user_id} appears twice in the split")
        seen.add(user_id)
        rows.append((user_id, cost if user_id == payer_id else Decimal("0.00"), share))
    if payer_id not in seen:
        rows.insert(0, (payer_id, cost, Decimal("0.00")))

    params: dict[str, str] = {
        "cost": f"{cost:.2f}",
        "description": description,
        "group_id": str(group_id),
        "currency_code": currency.upper(),
        "date": date,
        # 18 is "General" -- no category guessing, the description carries the meaning.
        "category_id": "18",
    }
    for i, (user_id, paid, share) in enumerate(rows):
        params[f"users__{i}__user_id"] = str(user_id)
        params[f"users__{i}__paid_share"] = f"{paid:.2f}"
        params[f"users__{i}__owed_share"] = f"{share:.2f}"
    return params


def normalise_date(value: str | None) -> str:
    """Accept YYYY-MM-DD (or nothing, meaning now) and return ISO 8601 UTC."""
    now = dt.datetime.now(dt.timezone.utc)
    if not value:
        return now.replace(microsecond=0).isoformat().replace("+00:00", "Z")
    try:
        day = dt.date.fromisoformat(value.strip())
    except ValueError as exc:
        raise SplitwiseError(f"date must be YYYY-MM-DD, got {value!r}") from exc
    # Midday so a timezone shift on Splitwise's side cannot move it a day.
    stamp = dt.datetime.combine(day, dt.time(12, 0), tzinfo=dt.timezone.utc)
    return stamp.isoformat().replace("+00:00", "Z")


def summarise_expense(expense: dict) -> str:
    """One line a human can check a write against."""
    cost = expense.get("cost")
    currency = expense.get("currency_code", "")
    desc = expense.get("description", "?")
    shares = ", ".join(
        f"{u.get('user', {}).get('first_name', '?')} owes {u.get('owed_share')}"
        for u in expense.get("users", [])
        if Decimal(str(u.get("owed_share") or "0")) > 0
    )
    return f"#{expense.get('id')} {desc} - {cost} {currency} ({shares})"


# --- HTTP layer -------------------------------------------------------------


def load_cookies(path: Path = STORAGE_STATE) -> dict[str, str]:
    """Read the Playwright storage state login.py wrote."""
    try:
        state = json.loads(path.read_text())
    except FileNotFoundError as exc:
        raise SplitwiseError(
            f"{path} does not exist -- run `splitwise-mcp-login` on the desktop first"
        ) from exc
    except json.JSONDecodeError as exc:
        raise SplitwiseError(f"{path} is not valid JSON: {exc}") from exc

    cookies = {
        c["name"]: c["value"]
        for c in state.get("cookies", [])
        if "splitwise.com" in (c.get("domain") or "")
    }
    if not cookies:
        raise SplitwiseError(f"{path} holds no splitwise.com cookies -- log in again")
    return cookies


class SplitwiseClient:
    def __init__(self, storage_state: Path = STORAGE_STATE, timeout: float = 20.0):
        self._http = httpx.Client(
            base_url=API_URL,
            cookies=load_cookies(storage_state),
            timeout=timeout,
            follow_redirects=False,
            headers={
                "User-Agent": BROWSER_UA,
                "Accept": "application/json, text/plain, */*",
                "X-Requested-With": "XMLHttpRequest",
                "Referer": f"{BASE_URL}/",
            },
        )
        self._csrf: str | None = None

    def close(self) -> None:
        self._http.close()

    def __enter__(self) -> SplitwiseClient:
        return self

    def __exit__(self, *_exc: object) -> None:
        self.close()

    def _csrf_token(self) -> str:
        """Scrape Rails' CSRF token off a page and keep it for the process.

        Non-GET requests are rejected without it. The token is tied to the
        session cookie, so it stays valid as long as the cookie does.
        """
        if self._csrf:
            return self._csrf
        resp = self._http.get(APP_URL, headers={"Accept": "text/html"})
        if resp.status_code in (401, 403) or 300 <= resp.status_code < 400:
            raise SessionExpired()
        match = _CSRF_RE.search(resp.text)
        if not match:
            raise SplitwiseError(
                "could not find a csrf-token on the app page -- the session is probably "
                "expired, or Splitwise changed its markup"
            )
        self._csrf = match.group(1)
        return self._csrf

    def _unwrap(self, resp: httpx.Response) -> dict:
        if resp.status_code in (401, 403) or 300 <= resp.status_code < 400:
            raise SessionExpired()
        ctype = resp.headers.get("content-type", "")
        if "json" not in ctype:
            # An HTML body where JSON was asked for means we were bounced to
            # the login page.
            raise SessionExpired()
        try:
            body = resp.json()
        except ValueError as exc:
            raise SplitwiseError(f"Splitwise returned unparseable JSON: {exc}") from exc
        errors = body.get("errors") if isinstance(body, dict) else None
        if errors:
            raise SplitwiseError(f"Splitwise rejected the request: {errors}")
        if resp.status_code >= 400:
            raise SplitwiseError(f"Splitwise returned HTTP {resp.status_code}: {body}")
        return body

    def get_current_user(self) -> dict:
        return self._unwrap(self._http.get("/get_current_user"))["user"]

    def get_groups(self) -> list[dict]:
        return self._unwrap(self._http.get("/get_groups"))["groups"]

    def get_expenses(self, group_id: int, limit: int = 10) -> list[dict]:
        resp = self._http.get(
            "/get_expenses", params={"group_id": group_id, "limit": limit}
        )
        return self._unwrap(resp)["expenses"]

    def create_expense(self, params: dict[str, str]) -> dict:
        resp = self._http.post(
            "/create_expense",
            data=params,
            headers={"X-CSRF-Token": self._csrf_token()},
        )
        expenses = self._unwrap(resp).get("expenses") or []
        if not expenses:
            raise SplitwiseError(
                "Splitwise accepted the request but created no expense"
            )
        return expenses[0]


def load_cache(path: Path = CACHE_FILE) -> dict:
    try:
        return json.loads(path.read_text())
    except FileNotFoundError as exc:
        raise SplitwiseError(
            f"{path} does not exist -- run `systemctl start splitwise-mcp-refresh-cache`"
        ) from exc
    except json.JSONDecodeError as exc:
        raise SplitwiseError(f"{path} is not valid JSON: {exc}") from exc
