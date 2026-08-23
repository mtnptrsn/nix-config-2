"""Tests for the Matchi payment parser. No network, no real account data.

The fixtures reproduce the real markup -- the heavy indentation, the bold runs
around the amount, the description split across lines -- because every parser
bug found so far came from exactly those details. Names and venues are invented.
"""

import pytest

import client
from client import parse_payments


@pytest.fixture(autouse=True)
def adaptive_db(tmp_path, monkeypatch):
    """Keep scrapling's fingerprint store out of the real state dir.

    Without this the parser reaches for /var/lib/matchi-mcp, which the test user
    cannot write -- and a store shared between tests would let one test's
    fingerprints change another's result.
    """
    monkeypatch.setattr(client, "ADAPTIVE_DIR", tmp_path)


def _page(panels: str) -> str:
    return f"<html><body><div class='container'>{panels}</div></body></html>"


def _payment_row(reference: str, description: str, payment: str) -> str:
    return f"""
    <div class="list-group-item row">
      <div class="col-sm-2"><strong>{reference}</strong></div>
      <div class="col-sm-3">
        <strong>
            Booking
        </strong><br>
        <p class="text-sm">
            {description}
        </p>
      </div>
      <div class="col-sm-3">
        <div><span class="text-sm">
            <strong>Online payment</strong>
                <strong>
                    {payment}
                </strong>
        </span></div>
      </div>
      <div class="col-sm-2"><a href="/profile/printReceipt/{reference}">Print</a></div>
      <div class="col-sm-2"><a href="#">withdraw</a></div>
    </div>
    """


def _payments_page(rows: str) -> str:
    return _page(
        f"""
        <div class="panel panel-default">
          <header class="panel-heading">
            <div class="row">
              <div class="col-sm-2">Reference</div>
              <div class="col-sm-3">Description</div>
              <div class="col-sm-3">Payment</div>
            </div>
          </header>
          <div class="list-group alt">{rows}</div>
        </div>
        """
    )


RESERVED = _payment_row(
    "118152180",
    "2026-08-27 21:00-22:00 Test Arena B12",
    "228.8 SEK\n</strong> is reserved since 2026-08-23.<br>Will be withdrawn 2026-08-28.<strong>",
)
SETTLED = _payment_row(
    "117820612",
    "2026-08-18 17:00-18:00 Malmo BadmintonCenter Bana 7 (SH)",
    "176,80 SEK\n</strong> was withdrawn from your account 2026-08-19.<strong>",
)


class TestParsePayments:
    def test_amount_and_session_are_extracted(self):
        got = parse_payments(_payments_page(RESERVED))
        assert len(got) == 1
        p = got[0]
        assert p["reference"] == "118152180"
        assert p["kind"] == "Booking"
        assert (p["date"], p["start_time"], p["end_time"]) == (
            "2026-08-27",
            "21:00",
            "22:00",
        )
        assert (p["amount"], p["currency"]) == ("228.8", "SEK")
        assert p["payment_method"] == "Online payment"

    def test_venue_keeps_a_multi_word_court_intact(self):
        # "Malmo BadmintonCenter Bana 7 (SH)" must not be guessed apart.
        got = parse_payments(_payments_page(SETTLED))
        assert got[0]["venue"] == "Malmo BadmintonCenter Bana 7 (SH)"

    def test_decimal_comma_is_normalised(self):
        got = parse_payments(_payments_page(SETTLED))
        assert got[0]["amount"] == "176.80"

    def test_reserved_payment_reports_the_booking_date(self):
        got = parse_payments(_payments_page(RESERVED))
        assert got[0]["reserved_on"] == "2026-08-23"

    def test_settled_payment_claims_no_booking_date(self):
        # Only the withdrawal date is on the page, which is not when it was
        # booked, so nothing is inferred.
        got = parse_payments(_payments_page(SETTLED))
        assert got[0]["reserved_on"] is None
        assert "withdrawn" in got[0]["payment_text"]

    def test_rows_without_money_are_dropped(self):
        no_money = _payment_row("1", "2026-08-18 17:00-18:00 Test Arena B1", "free")
        assert parse_payments(_payments_page(no_money)) == []

    def test_newest_session_first(self):
        got = parse_payments(_payments_page(SETTLED + RESERVED))
        assert [p["date"] for p in got] == ["2026-08-27", "2026-08-18"]

    def test_empty_page_yields_nothing(self):
        assert parse_payments(_payments_page("")) == []

    def test_booking_rows_are_not_matched(self):
        # The bookings lists use `row row-full` on otherwise similar markup;
        # the selector must not pick them up.
        booking_row = RESERVED.replace(
            'class="list-group-item row"', 'class="list-group-item row row-full"'
        )
        assert parse_payments(_payments_page(booking_row)) == []
