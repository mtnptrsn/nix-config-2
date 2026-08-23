"""Fetch groups and their members into cache.json, and refresh the session.

The point is that "Ebbe" resolves to a user id with no network round trip, so
a single sentence like "badminton with Ebbe, 200 kr" turns into one write. Run
by a weekly timer, and by hand after adding someone to a group.

It doubles as the session keepalive. Splitwise hands back a fresh
`_splitwise_session` on every authenticated request with the expiry a year out,
so this unit -- the only one that may write the state dir -- is where the
refreshed cookie gets saved. Weekly is comfortably inside every window
involved, so the login should never need repeating.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from client import CACHE_FILE, SplitwiseClient, SplitwiseError

MEMBER_FIELDS = ("id", "first_name", "last_name", "email")


def build_cache(client: SplitwiseClient) -> dict:
    user = client.get_current_user()
    groups = []
    for group in client.get_groups():
        # The catch-all "Non-group expenses" pseudo-group has id 0 and no
        # members worth resolving against.
        if group.get("id") == 0:
            continue
        members = []
        for m in group.get("members", []):
            member = {k: m.get(k) for k in MEMBER_FIELDS}
            member["name"] = " ".join(
                p for p in (m.get("first_name"), m.get("last_name")) if p
            )
            members.append(member)
        groups.append(
            {
                "id": group.get("id"),
                "name": group.get("name"),
                "simplify_by_default": group.get("simplify_by_default"),
                "members": members,
            }
        )
    return {
        "current_user": {
            "id": user.get("id"),
            "first_name": user.get("first_name"),
            "name": " ".join(
                p for p in (user.get("first_name"), user.get("last_name")) if p
            ),
        },
        "groups": groups,
    }


def main() -> int:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else CACHE_FILE
    try:
        with SplitwiseClient() as client:
            cache = build_cache(client)
            # After the requests, so the jar holds the re-issued session.
            client.save_session()
    except SplitwiseError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    # Write-then-rename so a crashed refresh cannot leave a half-written cache
    # for the server to read.
    tmp = out.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(cache, indent=2, ensure_ascii=False) + "\n")
    tmp.replace(out)
    print(
        f"{out}: {len(cache['groups'])} groups, "
        + ", ".join(f"{g['name']} ({len(g['members'])})" for g in cache["groups"])
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
