from datetime import date, datetime, time, timedelta

import pytest

from doctolib_agent.config import AgentConfig
from doctolib_agent.matcher import filter_and_rank, matches
from doctolib_agent.models import Practitioner, SearchIntent, Slot, TimeWindow


def make_intent(**kw):
    base = dict(
        specialty_slugs=["orl", "medecin-generaliste"],
        specialty_label="ORL",
        reason_summary="boğaz ağrısı",
        location="paris",
    )
    base.update(kw)
    return SearchIntent(**base)


def make_slot(when: datetime, slug="dr-a", speciality="ORL"):
    return Slot(
        start=when,
        practitioner=Practitioner(name="Dr A", slug=slug, speciality=speciality),
        visit_motive_id=1,
    )


def next_weekday(target: int, hour: int) -> datetime:
    d = date.today() + timedelta(days=1)
    while d.weekday() != target:
        d += timedelta(days=1)
    return datetime.combine(d, time(hour, 0))


def test_window_filters_by_weekday_and_hour():
    cfg = AgentConfig()
    # Sadece Salı (1) öğleden sonra
    intent = make_intent(windows=[TimeWindow(weekdays=[1], start=time(12, 0), end=time(18, 0))])

    good = make_slot(next_weekday(1, 14))
    wrong_hour = make_slot(next_weekday(1, 9))
    wrong_day = make_slot(next_weekday(3, 14))

    assert matches(good, intent, cfg)
    assert not matches(wrong_hour, intent, cfg)
    assert not matches(wrong_day, intent, cfg)


def test_past_slots_rejected():
    cfg = AgentConfig()
    intent = make_intent()
    past = make_slot(datetime.now() - timedelta(days=2))
    assert not matches(past, intent, cfg)


def test_horizon_and_blackout():
    cfg = AgentConfig()
    cfg.scan.horizon_days = 7
    intent = make_intent()

    far = make_slot(datetime.combine(date.today() + timedelta(days=30), time(10, 0)))
    assert not matches(far, intent, cfg)

    near_day = date.today() + timedelta(days=3)
    cfg.blackout_dates = [near_day.isoformat()]
    blacked = make_slot(datetime.combine(near_day, time(10, 0)))
    assert not matches(blacked, intent, cfg)


def test_excluded_and_preferred_practitioners():
    cfg = AgentConfig()
    intent = make_intent()
    when = datetime.combine(date.today() + timedelta(days=2), time(10, 0))

    cfg.excluded_practitioners = ["dr-bad"]
    assert not matches(make_slot(when, slug="dr-bad-clinic"), intent, cfg)

    cfg.excluded_practitioners = []
    cfg.preferred_practitioners = ["dr-fav"]
    later = when + timedelta(days=1)
    ranked = filter_and_rank(
        [make_slot(when, slug="dr-other"), make_slot(later, slug="dr-fav")], intent, cfg
    )
    # Tercih edilen hekim, daha geç olsa bile başa gelir.
    assert ranked[0].practitioner.slug == "dr-fav"


def test_dedupe_and_sort_by_time():
    cfg = AgentConfig()
    intent = make_intent()
    t1 = datetime.combine(date.today() + timedelta(days=2), time(9, 0))
    t2 = datetime.combine(date.today() + timedelta(days=1), time(9, 0))
    ranked = filter_and_rank([make_slot(t1), make_slot(t1), make_slot(t2)], intent, cfg)
    assert len(ranked) == 2
    assert ranked[0].start == t2


def test_overnight_window_wraps_midnight():
    w = TimeWindow(weekdays=[0, 1, 2, 3, 4, 5, 6], start=time(22, 0), end=time(2, 0))
    assert w.covers(datetime(2026, 9, 21, 23, 30))
    assert w.covers(datetime(2026, 9, 21, 1, 0))
    assert not w.covers(datetime(2026, 9, 21, 12, 0))


def test_invalid_weekday_rejected():
    with pytest.raises(ValueError):
        TimeWindow(weekdays=[9])
