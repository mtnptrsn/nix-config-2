"""MCP server over the Splitwise web API.

Exposed to the internet over Tailscale Funnel behind a secret URL path, so the
tool set is kept deliberately small: three reads and one write, and no delete.
Anyone holding the URL can do exactly what is listed here.
"""

from __future__ import annotations

import functools
import os
from collections.abc import Callable
from decimal import Decimal
from typing import Any, TypeVar

from fastmcp import FastMCP
from fastmcp.exceptions import ToolError
from starlette.requests import Request
from starlette.responses import JSONResponse, PlainTextResponse

from client import (
    SplitwiseClient,
    SplitwiseError,
    build_expense_params,
    load_cache,
    money,
    normalise_date,
    resolve_group,
    resolve_member,
    split_equally,
    summarise_expense,
)

F = TypeVar("F", bound=Callable[..., Any])


def readable_errors(fn: F) -> F:
    """Let SplitwiseError messages reach the client.

    FastMCP masks exception details by default, which would turn "no member of
    Badminton matches 'Ebba'" into a generic failure. ToolError is the one kind
    it passes through, so the deliberate messages are re-raised as that and
    everything else stays masked.
    """

    @functools.wraps(fn)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        try:
            return fn(*args, **kwargs)
        except SplitwiseError as exc:
            raise ToolError(str(exc)) from exc

    return wrapper  # type: ignore[return-value]


HOST = os.environ.get("SPLITWISE_MCP_HOST", "127.0.0.1")
PORT = int(os.environ.get("SPLITWISE_MCP_PORT", "8766"))

mcp = FastMCP(
    "splitwise",
    instructions=(
        "Read and add expenses in the user's Splitwise groups. Group names and "
        "members are cached, so call list_groups/list_members to resolve a "
        "first name like 'Ebbe' before creating an expense. Amounts default to "
        "SEK. There is no way to delete an expense here -- confirm the details "
        "with the user before writing."
    ),
)


def _label(member: dict) -> str:
    return member.get("name") or member.get("first_name") or str(member.get("id"))


@mcp.tool
@readable_errors
def list_groups() -> list[dict]:
    """List the user's Splitwise groups, with member names and ids.

    Served from the local cache, so it costs nothing. Use it to find the group
    id and the exact spelling of members' names.
    """
    cache = load_cache()
    return [
        {
            "id": g["id"],
            "name": g["name"],
            "members": [_label(m) for m in g.get("members", [])],
        }
        for g in cache.get("groups", [])
    ]


@mcp.tool
@readable_errors
def list_members(group: str) -> dict:
    """List the members of one group, with their user ids.

    `group` is a group name (partial is fine, as long as it is unambiguous) or
    a group id.
    """
    cache = load_cache()
    resolved = resolve_group(cache, group)
    me = cache.get("current_user", {}).get("id")
    return {
        "group": resolved["name"],
        "group_id": resolved["id"],
        "members": [
            {
                "id": m["id"],
                "name": _label(m),
                "first_name": m.get("first_name"),
                "is_you": m["id"] == me,
            }
            for m in resolved.get("members", [])
        ],
    }


@mcp.tool
@readable_errors
def list_recent_expenses(group: str, limit: int = 10) -> list[dict]:
    """Show the most recent expenses in a group, newest first.

    Hits Splitwise live rather than the cache, so it is also the way to confirm
    that a create_expense call landed.
    """
    cache = load_cache()
    resolved = resolve_group(cache, group)
    with SplitwiseClient() as client:
        expenses = client.get_expenses(resolved["id"], limit=max(1, min(limit, 50)))
    return [
        {
            "id": e.get("id"),
            "date": e.get("date"),
            "description": e.get("description"),
            "cost": e.get("cost"),
            "currency": e.get("currency_code"),
            "created_by": (e.get("created_by") or {}).get("first_name"),
            "deleted": bool(e.get("deleted_at")),
            "shares": {
                (u.get("user") or {}).get("first_name"): {
                    "paid": u.get("paid_share"),
                    "owes": u.get("owed_share"),
                }
                for u in e.get("users", [])
            },
        }
        for e in expenses
    ]


@mcp.tool
@readable_errors
def create_expense(
    group: str,
    description: str,
    amount: str,
    currency: str = "SEK",
    paid_by: str = "me",
    split_between: list[str] | None = None,
    shares: dict[str, str] | None = None,
    date: str | None = None,
    notes: str | None = None,
) -> dict:
    """Add an expense to a Splitwise group.

    This writes to Splitwise and cannot be undone from here -- confirm the
    amount, the group and who is involved with the user first.

    Args:
        group: Group name (partial is fine if unambiguous) or group id.
        description: What the expense was, e.g. "Badminton".
        amount: Total cost, e.g. "200" or "200.50".
        currency: ISO currency code. Defaults to SEK.
        paid_by: Who paid the whole amount. A first name, or "me".
        split_between: Names to split equally between. Defaults to every member
            of the group. Include the payer if they take a share.
        shares: Explicit per-person amounts, e.g. {"Ebbe": "150", "me": "50"}.
            Must sum to `amount`. Overrides split_between.
        date: Day of the expense as YYYY-MM-DD. Defaults to now.
        notes: Free-text note stored with the expense, shown as its comment in
            Splitwise. Optional.
    """
    cache = load_cache()
    resolved = resolve_group(cache, group)
    me = cache.get("current_user", {}).get("id")

    cost = money(amount)
    payer = resolve_member(resolved, paid_by, me)

    if shares:
        owed: list[tuple[int, Decimal]] = []
        for name, value in shares.items():
            member = resolve_member(resolved, name, me)
            owed.append((member["id"], money(value)))
    else:
        if split_between:
            participants = [resolve_member(resolved, n, me) for n in split_between]
        else:
            participants = list(resolved.get("members", []))
        if not participants:
            raise SplitwiseError(f"{resolved['name']} has no members to split between")
        amounts = split_equally(cost, len(participants))
        owed = [(m["id"], a) for m, a in zip(participants, amounts)]

    params = build_expense_params(
        group_id=resolved["id"],
        description=description,
        cost=cost,
        currency=currency,
        date=normalise_date(date),
        payer_id=payer["id"],
        owed=owed,
        details=notes,
    )

    with SplitwiseClient() as client:
        expense = client.create_expense(params)

    return {
        "id": expense.get("id"),
        "group": resolved["name"],
        "summary": summarise_expense(expense),
        "paid_by": _label(payer),
    }


@mcp.custom_route("/healthz", methods=["GET"])
async def healthz(_request: Request) -> PlainTextResponse:
    """Loopback liveness check. Says nothing about the Splitwise session."""
    return PlainTextResponse("ok")


@mcp.custom_route("/readyz", methods=["GET"])
async def readyz(_request: Request) -> JSONResponse:
    """Reports whether the cookie and the cache are actually usable.

    Separate from /healthz so an expired session shows up as a failing check
    rather than a tool call that dies at 3am.
    """
    try:
        cache = load_cache()
        with SplitwiseClient() as client:
            user = client.get_current_user()
    except SplitwiseError as exc:
        return JSONResponse({"ready": False, "error": str(exc)}, status_code=503)
    return JSONResponse(
        {
            "ready": True,
            "user": user.get("first_name"),
            "groups": len(cache.get("groups", [])),
        }
    )


if __name__ == "__main__":
    # stateless_http keeps every request self-contained, so a client that
    # reconnects through the funnel never lands on a session this process has
    # forgotten.
    mcp.run(
        transport="http",
        host=HOST,
        port=PORT,
        path="/mcp",
        stateless_http=True,
        show_banner=False,
    )
