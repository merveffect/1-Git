"""Slotları kullanıcının müsaitliğine göre süz ve sırala."""
from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Iterable

from .config import AgentConfig
from .models import SearchIntent, Slot


def _as_naive_local(dt: datetime) -> datetime:
    """Doctolib slot'ları offset'li gelir; karşılaştırmayı yerel duvar saatinde yap."""
    return dt.replace(tzinfo=None) if dt.tzinfo else dt


def _parse_blackouts(values: Iterable[str]) -> set[date]:
    out: set[date] = set()
    for v in values:
        try:
            out.add(date.fromisoformat(str(v).strip()))
        except ValueError:
            continue
    return out


def matches(slot: Slot, intent: SearchIntent, cfg: AgentConfig) -> bool:
    start = _as_naive_local(slot.start)
    today = date.today()

    if start.date() < today:
        return False
    if intent.earliest_date and start.date() < intent.earliest_date:
        return False
    if intent.latest_date and start.date() > intent.latest_date:
        return False
    if start.date() > today + timedelta(days=cfg.scan.horizon_days):
        return False
    if start.date() in _parse_blackouts(cfg.blackout_dates):
        return False

    slug = slot.practitioner.slug.lower()
    if any(x.lower() in slug for x in cfg.excluded_practitioners):
        return False

    if intent.windows and not any(w.covers(start) for w in intent.windows):
        return False
    return True


def score(slot: Slot, intent: SearchIntent, cfg: AgentConfig) -> tuple:
    """Sıralama anahtarı - küçük olan daha iyi.

    Tercih edilen hekimler öne, sonra en erken tarih, sonra ilk uzmanlık tercihi.
    """
    slug = slot.practitioner.slug.lower()
    preferred = 0 if any(x.lower() in slug for x in cfg.preferred_practitioners) else 1

    spec = slot.practitioner.speciality.lower()
    try:
        spec_rank = next(
            i for i, s in enumerate(intent.specialty_slugs) if s.lower().replace("-", " ") in spec.replace("-", " ")
        )
    except StopIteration:
        spec_rank = len(intent.specialty_slugs)

    return (preferred, _as_naive_local(slot.start), spec_rank)


def filter_and_rank(slots: Iterable[Slot], intent: SearchIntent, cfg: AgentConfig) -> list[Slot]:
    seen: set[str] = set()
    kept: list[Slot] = []
    for s in slots:
        if not matches(s, intent, cfg):
            continue
        k = s.key()
        if k in seen:
            continue
        seen.add(k)
        kept.append(s)
    kept.sort(key=lambda s: score(s, intent, cfg))
    return kept
