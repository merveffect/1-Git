"""Tarama turlarını yöneten üst seviye orkestrasyon."""
from __future__ import annotations

import logging
import time
from datetime import date
from typing import Callable, Iterator

from .booker import Booker, browser_session
from .client import BrowserTransport, DoctolibClient, HttpTransport, RateLimited
from .config import AgentConfig
from .matcher import filter_and_rank
from .models import BookingResult, SearchIntent, Slot

log = logging.getLogger(__name__)

EMERGENCY_NOTICE = (
    "\n⚠  Mesajında acil değerlendirme gerektirebilecek işaretler var:\n"
    "   {flags}\n"
    "   Randevu beklemek yerine acil servisi veya 112'yi (FR: 15 / 112) ara.\n"
)


def build_client(cfg: AgentConfig, page=None, dump_dir: str | None = None) -> DoctolibClient:
    if cfg.transport == "browser":
        if page is None:
            raise ValueError("browser taşıma modu için bir Playwright sayfası gerekir.")
        transport = BrowserTransport(cfg, page)
    else:
        transport = HttpTransport(cfg)
    return DoctolibClient(cfg, transport, dump_dir=dump_dir)


def scan_once(
    cfg: AgentConfig,
    intent: SearchIntent,
    client: DoctolibClient,
    progress: Callable[[str], None] = lambda _m: None,
) -> list[Slot]:
    """Tek tur: hekimleri bul, müsaitlikleri topla, filtrele ve sırala."""
    all_slots: list[Slot] = []
    keywords = [intent.specialty_label, intent.reason_summary]
    budget = cfg.scan.max_practitioners

    for slug in intent.specialty_slugs[:3]:
        if budget <= 0:
            break
        progress(f"Aranıyor: {slug} @ {intent.location}")
        try:
            doctors = client.search_practitioners(slug, intent.location)
        except RateLimited as exc:
            progress(f"  ! {exc}")
            break
        progress(f"  {len(doctors)} hekim bulundu")

        for doc in doctors[:budget]:
            try:
                slots = client.collect_slots(
                    doc,
                    keywords,
                    start=intent.earliest_date or date.today(),
                    days=cfg.scan.horizon_days,
                    insurance_sector=intent.insurance_sector,
                )
            except RateLimited as exc:
                progress(f"  ! {exc}")
                return filter_and_rank(all_slots, intent, cfg)
            if slots:
                progress(f"  {doc.name}: {len(slots)} ham slot")
            all_slots.extend(slots)
            budget -= 1

    return filter_and_rank(all_slots, intent, cfg)


def watch(
    cfg: AgentConfig,
    intent: SearchIntent,
    client: DoctolibClient,
    max_rounds: int | None = None,
    progress: Callable[[str], None] = lambda _m: None,
) -> Iterator[list[Slot]]:
    """Eşleşme çıkana kadar (veya tur limitine kadar) periyodik tara."""
    rounds = 0
    while max_rounds is None or rounds < max_rounds:
        rounds += 1
        progress(f"--- Tur {rounds} ---")
        matches = scan_once(cfg, intent, client, progress)
        yield matches
        if matches:
            return
        progress(f"Eşleşme yok, {cfg.scan.poll_interval_seconds}s sonra tekrar denenecek.")
        time.sleep(cfg.scan.poll_interval_seconds)


def book_slots(
    cfg: AgentConfig,
    slots: list[Slot],
    progress: Callable[[str], None] = lambda _m: None,
) -> list[BookingResult]:
    """En iyi slot(lar)ı rezerve etmeyi dene. `notify` modunda hiçbir şey yapmaz."""
    if cfg.booking.mode == "notify":
        return []
    if not slots:
        return []

    results: list[BookingResult] = []
    limit = cfg.booking.max_bookings_per_run
    with browser_session(cfg) as page:
        booker = Booker(cfg, page)
        for slot in slots[:limit]:
            progress(f"Rezervasyon deneniyor: {slot.start:%d.%m %H:%M} — {slot.practitioner.name}")
            result = booker.book(slot)
            results.append(result)
            progress(("  ✓ " if result.ok else "  · ") + result.message)
            if result.ok:
                break
            if cfg.booking.mode == "assist":
                # assist modunda tarayıcı insanın tamamlaması için açık kalmalı.
                progress(f"  Tarayıcı {cfg.booking.confirm_timeout_seconds}s açık kalacak.")
                time.sleep(cfg.booking.confirm_timeout_seconds)
                break
    return results
