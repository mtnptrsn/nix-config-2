"""MCP server over the Matchi web app.

One tool, read-only. Booking and cancelling both cost money or lose a court, so
neither is exposed: with the secret URL as the only credential, anyone holding
it can look at the calendar and nothing else.
"""

from __future__ import annotations

import functools
import os
from collections.abc import Callable
from typing import Any, TypeVar

from fastmcp import FastMCP
from fastmcp.exceptions import ToolError
from starlette.requests import Request
from starlette.responses import JSONResponse, PlainTextResponse

from client import MatchiClient, MatchiError

HOST = os.environ.get("MATCHI_MCP_HOST", "127.0.0.1")
PORT = int(os.environ.get("MATCHI_MCP_PORT", "8767"))

mcp = FastMCP(
    "matchi",
    instructions=(
        "Read the user's Matchi court bookings (badminton, padel, tennis) and "
        "what each one cost. Read-only: this cannot book or cancel anything. "
        "Upcoming and past bookings come back together -- compare the date "
        "against today to tell them apart."
    ),
)

F = TypeVar("F", bound=Callable[..., Any])


def readable_errors(fn: F) -> F:
    """Let MatchiError messages reach the client.

    FastMCP masks exception details by default, which would turn "session is no
    longer valid, re-run matchi-mcp-login" into a generic failure. ToolError is
    the one kind it passes through.
    """

    @functools.wraps(fn)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        try:
            return fn(*args, **kwargs)
        except MatchiError as exc:
            raise ToolError(str(exc)) from exc

    return wrapper  # type: ignore[return-value]


@mcp.tool
@readable_errors
def list_bookings(limit: int = 20, since: str | None = None) -> list[dict]:
    """List the user's court bookings and what each one cost, newest first.

    Covers upcoming and past alike; compare `date` against today to tell which
    is which. Read from Matchi's payment history, which is the only page that
    carries an amount.

    Each row has the session `date` and `start_time`/`end_time`, the `amount`
    and `currency`, and a `reference`. `venue` holds the facility and court
    together, exactly as Matchi writes it, because nothing in the string marks
    where one ends.

    `payment_text` is Matchi's own wording for whether the money has moved
    ("was withdrawn from your account 2026-08-23" versus "is reserved since
    2026-08-23"); read it rather than assuming. `reserved_on` is the date the
    booking was made, and is only available while a payment is still reserved --
    once settled, Matchi shows only the withdrawal date, which is usually the
    day after the session.

    Args:
        limit: How many rows to return. Matchi renders a fixed page of history,
            so this trims rather than fetching more.
        since: Drop sessions before this ISO date, e.g. "2026-08-01".
    """
    with MatchiClient() as client:
        bookings = client.payments()
    if since:
        bookings = [b for b in bookings if (b["date"] or "") >= since]
    return bookings[: max(1, limit)]


@mcp.custom_route("/healthz", methods=["GET"])
async def healthz(_request: Request) -> PlainTextResponse:
    """Loopback liveness check. Says nothing about the Matchi session."""
    return PlainTextResponse("ok")


@mcp.custom_route("/readyz", methods=["GET"])
async def readyz(_request: Request) -> JSONResponse:
    """Reports whether the cookie still gets us a logged-in page.

    Separate from /healthz so an expired SSO session shows up as a failing
    check rather than a tool call that dies when it is next needed.
    """
    try:
        with MatchiClient() as client:
            bookings = client.payments()
    except MatchiError as exc:
        return JSONResponse({"ready": False, "error": str(exc)}, status_code=503)
    return JSONResponse({"ready": True, "bookings": len(bookings)})


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
