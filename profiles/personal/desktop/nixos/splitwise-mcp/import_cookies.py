"""Import a Splitwise session cookie out of a Firefox profile.

Driving a browser with Playwright does not work here: Cloudflare fingerprints
the CDP connection and blocks the login. So the login happens in the browser
the user actually uses, and this only lifts the resulting cookie out of it --
nothing for a bot check to notice, because no bot is involved.

Output is shaped like a Playwright storage state so client.py keeps one cookie
format to read.
"""

from __future__ import annotations

import configparser
import datetime as dt
import json
import shutil
import sqlite3
import sys
import tempfile
from pathlib import Path

# Home Manager moved firefox's config out of ~/.mozilla at some point, and the
# old directory is left behind, so both are searched rather than guessed at.
FIREFOX_ROOTS = [
    Path.home() / ".config/mozilla/firefox",
    Path.home() / ".mozilla/firefox",
]

# Splitwise's session lives in user_credentials; the rest of its cookies are
# carried along because the web app sends them and cheap consistency beats
# guessing which ones the API notices.
SESSION_COOKIE = "user_credentials"


class ImportError_(Exception):
    """A message for the user, not a traceback."""


# Year 3000, as seconds. Anything past this is not a plausible cookie expiry.
_MAX_PLAUSIBLE = 32_503_680_000


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
    other than *.default is still found; the glob is a fallback for roots that
    have no ini.
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
                is_relative = parser.getboolean(section, "IsRelative", fallback=True)
                found.append(root / path if is_relative else Path(path))
        found.extend(p for p in root.iterdir() if (p / "cookies.sqlite").is_file())
    return [p for p in dict.fromkeys(found) if (p / "cookies.sqlite").is_file()]


def read_cookies(profile: Path) -> list[dict]:
    """Read splitwise.com cookies out of one profile.

    The live database is copied first: Firefox keeps it open in WAL mode, so
    reading in place either blocks or misses recent writes. The -wal file comes
    along so sqlite can replay it.
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
                "from moz_cookies where host like '%splitwise.com'"
            ).fetchall()
        except sqlite3.DatabaseError as exc:
            raise ImportError_(f"could not read {profile / 'cookies.sqlite'}: {exc}")
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


def pick_profile() -> tuple[Path, list[dict]]:
    """Choose the profile that actually holds a Splitwise session.

    Several profiles usually exist and most are empty, so the one with a
    session cookie wins; ties go to whichever was written most recently.
    """
    profiles = profile_dirs()
    if not profiles:
        raise ImportError_(
            "no Firefox profile found under "
            + " or ".join(str(r) for r in FIREFOX_ROOTS)
        )

    candidates = []
    for profile in profiles:
        cookies = read_cookies(profile)
        if any(c["name"] == SESSION_COOKIE for c in cookies):
            mtime = (profile / "cookies.sqlite").stat().st_mtime
            candidates.append((mtime, profile, cookies))

    if not candidates:
        raise ImportError_(
            f"no {SESSION_COOKIE} cookie in any Firefox profile "
            f"({', '.join(p.name for p in profiles)}). Log in at "
            "https://secure.splitwise.com in Firefox first, then run this again."
        )

    candidates.sort(key=lambda c: c[0], reverse=True)
    _, profile, cookies = candidates[0]
    return profile, cookies


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <output storage_state.json>", file=sys.stderr)
        return 2
    out = Path(sys.argv[1])

    try:
        profile, cookies = pick_profile()
    except ImportError_ as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    print(f"reading {profile.name}/cookies.sqlite")
    print(
        f"found {len(cookies)} splitwise.com cookies: "
        + ", ".join(sorted(c["name"] for c in cookies))
    )

    # Worth printing: it is the answer to "when do I have to do this again".
    session = next(c for c in cookies if c["name"] == SESSION_COOKIE)
    expires = session["expires"]
    if expires > 0:
        when = dt.datetime.fromtimestamp(expires, dt.timezone.utc)
        days = (when - dt.datetime.now(dt.timezone.utc)).days
        print(f"{SESSION_COOKIE} expires {when:%Y-%m-%d} ({days} days from now)")
    else:
        print(
            f"{SESSION_COOKIE} is a session cookie with no expiry -- it will stop "
            "working when Firefox next clears its session"
        )

    out.write_text(json.dumps({"cookies": cookies, "origins": []}, indent=2) + "\n")
    out.chmod(0o600)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
