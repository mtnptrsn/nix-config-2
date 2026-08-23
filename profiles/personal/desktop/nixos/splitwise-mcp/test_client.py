"""Tests for the parts that decide where money goes. No network involved."""

from decimal import Decimal

import pytest

from client import (
    SplitwiseError,
    build_expense_params,
    money,
    normalise_date,
    resolve_group,
    resolve_member,
    split_equally,
)

ME = 1
EBBE = 2

CACHE = {
    "current_user": {"id": ME, "first_name": "Mårten", "name": "Mårten Pettersson"},
    "groups": [
        {
            "id": 100,
            "name": "Badminton",
            "members": [
                {"id": ME, "first_name": "Mårten", "name": "Mårten Pettersson"},
                {"id": EBBE, "first_name": "Ebbe", "name": "Ebbe Larsson"},
                {"id": 3, "first_name": "Ebba", "name": "Ebba Nilsson"},
            ],
        },
        {
            "id": 200,
            "name": "Badminton Tuesdays",
            "members": [
                {"id": ME, "first_name": "Mårten", "name": "Mårten Pettersson"},
                {"id": 4, "first_name": "Anna", "name": "Anna Berg"},
                {"id": 5, "first_name": "Anna", "name": "Anna Sjögren"},
            ],
        },
    ],
}

GROUP = CACHE["groups"][0]
AMBIGUOUS_GROUP = CACHE["groups"][1]


class TestMoney:
    @pytest.mark.parametrize(
        ("raw", "expected"),
        [
            ("200", "200.00"),
            ("200,50", "200.50"),
            ("200.5", "200.50"),
            ("1 234,56", "1234.56"),
            (200, "200.00"),
            (200.5, "200.50"),
        ],
    )
    def test_parses(self, raw, expected):
        assert money(raw) == Decimal(expected)

    @pytest.mark.parametrize("raw", ["", "abc", "0", "-5"])
    def test_rejects(self, raw):
        with pytest.raises(SplitwiseError):
            money(raw)


class TestSplitEqually:
    @pytest.mark.parametrize(
        ("total", "count"),
        [("200", 2), ("100", 3), ("0.01", 1), ("10", 7), ("999.99", 4)],
    )
    def test_shares_always_sum_to_total(self, total, count):
        shares = split_equally(Decimal(total), count)
        assert len(shares) == count
        assert sum(shares) == Decimal(total)

    def test_remainder_goes_to_the_front(self):
        assert split_equally(Decimal("100"), 3) == [
            Decimal("33.34"),
            Decimal("33.33"),
            Decimal("33.33"),
        ]

    def test_rejects_empty_split(self):
        with pytest.raises(SplitwiseError):
            split_equally(Decimal("10"), 0)


class TestResolveMember:
    @pytest.mark.parametrize("query", ["Ebbe", "ebbe", "  EBBE  ", "Ebbe Larsson"])
    def test_first_name_match(self, query):
        assert resolve_member(GROUP, query, ME)["id"] == EBBE

    def test_self_aliases(self):
        for alias in ("me", "I", "myself", "jag"):
            assert resolve_member(GROUP, alias, ME)["id"] == ME

    def test_self_alias_without_membership(self):
        with pytest.raises(SplitwiseError, match="not a member"):
            resolve_member(GROUP, "me", 999)

    def test_user_id_match(self):
        assert resolve_member(GROUP, "2", ME)["id"] == EBBE

    def test_prefix_that_hits_two_people_is_refused(self):
        # "Ebb" prefixes both Ebbe and Ebba; guessing here would misattribute money.
        with pytest.raises(SplitwiseError, match="matches several"):
            resolve_member(GROUP, "Ebb", ME)

    def test_exact_first_name_beats_ambiguous_prefix(self):
        assert resolve_member(GROUP, "Ebba", ME)["id"] == 3

    def test_duplicate_first_names_are_refused(self):
        with pytest.raises(SplitwiseError, match="matches several"):
            resolve_member(AMBIGUOUS_GROUP, "Anna", ME)

    def test_duplicate_first_names_disambiguated_by_surname(self):
        assert resolve_member(AMBIGUOUS_GROUP, "Anna Berg", ME)["id"] == 4

    def test_unknown_name_lists_candidates(self):
        with pytest.raises(SplitwiseError, match="Ebbe Larsson"):
            resolve_member(GROUP, "Kalle", ME)

    def test_empty_query(self):
        with pytest.raises(SplitwiseError):
            resolve_member(GROUP, "", ME)


class TestResolveGroup:
    def test_exact_name_wins_over_prefix(self):
        # "Badminton" is also a prefix of "Badminton Tuesdays".
        assert resolve_group(CACHE, "Badminton")["id"] == 100

    def test_partial_name(self):
        assert resolve_group(CACHE, "tuesd")["id"] == 200

    def test_by_id(self):
        assert resolve_group(CACHE, "200")["id"] == 200

    def test_ambiguous_partial_is_refused(self):
        with pytest.raises(SplitwiseError, match="matches several"):
            resolve_group(CACHE, "badmin")

    def test_unknown_lists_candidates(self):
        with pytest.raises(SplitwiseError, match="Badminton"):
            resolve_group(CACHE, "Skiing")

    def test_empty_cache(self):
        with pytest.raises(SplitwiseError, match="cache is empty"):
            resolve_group({"groups": []}, "Badminton")


class TestBuildExpenseParams:
    def _params(self, **overrides):
        kwargs = {
            "group_id": 100,
            "description": "Badminton",
            "cost": Decimal("200.00"),
            "currency": "sek",
            "date": "2026-08-23T12:00:00Z",
            "payer_id": ME,
            "owed": [(ME, Decimal("100.00")), (EBBE, Decimal("100.00"))],
        }
        kwargs.update(overrides)
        return build_expense_params(**kwargs)

    def test_equal_split(self):
        assert self._params() == {
            "cost": "200.00",
            "description": "Badminton",
            "group_id": "100",
            "currency_code": "SEK",
            "date": "2026-08-23T12:00:00Z",
            "category_id": "18",
            "users__0__user_id": "1",
            "users__0__paid_share": "200.00",
            "users__0__owed_share": "100.00",
            "users__1__user_id": "2",
            "users__1__paid_share": "0.00",
            "users__1__owed_share": "100.00",
        }

    def test_paid_shares_sum_to_cost(self):
        params = self._params()
        paid = sum(Decimal(v) for k, v in params.items() if k.endswith("__paid_share"))
        assert paid == Decimal("200.00")

    def test_payer_taking_no_share_still_gets_a_row(self):
        params = self._params(owed=[(EBBE, Decimal("200.00"))])
        assert params["users__0__user_id"] == "1"
        assert params["users__0__paid_share"] == "200.00"
        assert params["users__0__owed_share"] == "0.00"
        assert params["users__1__owed_share"] == "200.00"

    def test_shares_that_do_not_add_up_are_refused(self):
        with pytest.raises(SplitwiseError, match="must match"):
            self._params(owed=[(ME, Decimal("50.00")), (EBBE, Decimal("100.00"))])

    def test_duplicate_user_is_refused(self):
        with pytest.raises(SplitwiseError, match="twice"):
            self._params(owed=[(EBBE, Decimal("100.00")), (EBBE, Decimal("100.00"))])


class TestNormaliseDate:
    def test_explicit_day_lands_at_midday_utc(self):
        assert normalise_date("2026-08-23") == "2026-08-23T12:00:00Z"

    def test_default_is_now(self):
        assert normalise_date(None).endswith("Z")

    @pytest.mark.parametrize("raw", ["23/08/2026", "yesterday", "2026-13-01"])
    def test_rejects_other_formats(self, raw):
        with pytest.raises(SplitwiseError):
            normalise_date(raw)
