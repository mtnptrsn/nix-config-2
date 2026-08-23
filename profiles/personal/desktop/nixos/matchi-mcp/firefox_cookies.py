"""Read cookies for a given site out of a Firefox profile.

Written generically rather than for Matchi specifically: splitwise-mcp has a
near-identical copy, and the fiddly parts -- finding profiles, coping with WAL,
Firefox's inconsistent expiry units -- should only be got right once. If these
servers ever move out of this repo, this is the one file both of them need.

Usage:
    firefox_cookies.py --host-like %matchi% --require KEYCLOAK_IDENTITY out.json
"""

from __future__ import annotations

import argparse
import configparser
import datetime as dt
import json
import shutil
import sqlite3
import tempfile
from pathlib import Path

# Home Manager moved firefox's config out of ~/.mozilla at some point and the
# old directory is left behind, so both are searched rather than guessed at.
FIREFOX_ROOTS = [
    Path.home() / ".config/mozilla/firefox",
    Path.home() / ".mozilla/firefox",
]

# Year 3000, as seconds. Anything past this is not a plausible cookie expiry.
_MAX_PLAUSIBLE = 32_503_680_000


class CookieError(Exception):
    """A message for the user, not a traceback."""


def epoch_seconds(value: int | None) -> int | None:
    """Normalise a cookie expiry to seconds.

    Firefox is not consistent about the unit -- observed in milliseconds in
    practice, documented as seconds, and microseconds elsewhere in the same
    table -- so the magnitude decides rather than a fixed divisor.
    """
    if not value or value <= 0:
        return None
    for divisor in (1, 1_000, 1_000_000):
        seconds = value // divisor
        if 0 < seconds < _MAX_PLAUSIBLE:
            return seconds
    return None


def profile_dirs() -> list[Path]:
    """Every profile directory named by a profiles.ini, plus any strays.

    Reading profiles.ini rather than globbing means a profile named something
    other than *.default is still found; the glob catches roots with no ini.
    """
    found: list[Path] = []
    for root in FIREFOX_ROOTS:
        if not root.is_dir():
            continue
        ini = root / "profiles.ini"
        if ini.is_file():
            parser = configparser.ConfigParser()
            parser.read(ini)
            for section in parser.sections():
                path = parser.get(section, "Path", fallback=None)
                if not path:
                    continue
                relative = parser.getboolean(section, "IsRelative", fallback=True)
                found.append(root / path if relative else Path(path))
        found.extend(p for p in root.iterdir() if (p / "cookies.sqlite").is_file())
    return [p for p in dict.fromkeys(found) if (p / "cookies.sqlite").is_file()]


def read_cookies(profile: Path, host_like: str) -> list[dict]:
    """Read one profile's cookies for hosts matching a SQL LIKE pattern.

    The database is copied first: Firefox keeps it open in WAL mode, so reading
    in place either blocks or misses recent writes. The -wal file comes along so
    sqlite can replay it.
    """
    with tempfile.TemporaryDirectory() as tmp:
        db = Path(tmp) / "cookies.sqlite"
        shutil.copy2(profile / "cookies.sqlite", db)
        wal = profile / "cookies.sqlite-wal"
        if wal.is_file():
            shutil.copy2(wal, db.with_name("cookies.sqlite-wal"))

        conn = sqlite3.connect(db)
        try:
            rows = conn.execute(
                "select name, value, host, path, expiry, isSecure, isHttpOnly "
                "from moz_cookies where host like ?",
                (host_like,),
            ).fetchall()
        except sqlite3.DatabaseError as exc:
            raise CookieError(f"could not read {profile / 'cookies.sqlite'}: {exc}")
        finally:
            conn.close()

    return [
        {
            "name": name,
            "value": value,
            "domain": host,
            "path": path or "/",
            "expires": epoch_seconds(expiry) or -1,
            "httpOnly": bool(http_only),
            "secure": bool(secure),
            "sameSite": "Lax",
        }
        for name, value, host, path, expiry, secure, http_only in rows
    ]


def pick_profile(host_like: str, required: str) -> tuple[Path, list[dict]]:
    """Choose the profile that actually holds a session.

    Several profiles usually exist and most are empty, so the one carrying the
    required cookie wins; ties go to whichever was written most recently.
    """
    profiles = profile_dirs()
    if not profiles:
        raise CookieError(
            "no Firefox profile found under "
            + " or ".join(str(r) for r in FIREFOX_ROOTS)
        )

    candidates = []
    for profile in profiles:
        cookies = read_cookies(profile, host_like)
        if any(c["name"] == required for c in cookies):
            mtime = (profile / "cookies.sqlite").stat().st_mtime
            candidates.append((mtime, profile, cookies))

    if not candidates:
        raise CookieError(
            f"no {required} cookie in any Firefox profile "
            f"({', '.join(p.name for p in profiles)}). Log in with Firefox "
            "first, then run this again."
        )

    candidates.sort(key=lambda c: c[0], reverse=True)
    _, profile, cookies = candidates[0]
    return profile, cookies


def report_expiry(cookies: list[dict], required: str) -> None:
    """Print when the session dies -- the answer to 'when must I redo this'."""
    session = next(c for c in cookies if c["name"] == required)
    expires = session["expires"]
    if expires > 0:
        when = dt.datetime.fromtimestamp(expires, dt.timezone.utc)
        days = (when - dt.datetime.now(dt.timezone.utc)).days
        print(f"{required} expires {when:%Y-%m-%d} ({days} days from now)")
    else:
        print(
            f"{required} is a session cookie with no expiry -- it will stop "
            "working when Firefox next clears its session"
        )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("output", help="where to write the storage state JSON")
    ap.add_argument(
        "--host-like",
        required=True,
        help="SQL LIKE pattern for the cookie host, e.g. %%matchi%%",
    )
    ap.add_argument(
        "--require",
        required=True,
        help="cookie that must be present for a profile to count as logged in",
    )
    args = ap.parse_args()

    try:
        profile, cookies = pick_profile(args.host_like, args.require)
    except CookieError as exc:
        print(f"error: {exc}")
        return 1

    print(f"reading {profile.name}/cookies.sqlite")
    print(
        f"found {len(cookies)} cookies: "
        + ", ".join(sorted(c["name"] for c in cookies))
    )
    report_expiry(cookies, args.require)

    out = Path(args.output)
    out.write_text(json.dumps({"cookies": cookies, "origins": []}, indent=2) + "\n")
    out.chmod(0o600)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
