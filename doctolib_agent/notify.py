"""Bildirim kanalları: konsol ve isteğe bağlı webhook."""
from __future__ import annotations

import logging
import os

import httpx

from .models import SearchIntent, Slot

log = logging.getLogger(__name__)

WEEKDAYS_TR = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]


def format_slot(slot: Slot, index: int | None = None) -> str:
    d = slot.start
    head = f"{index}. " if index is not None else ""
    return (
        f"{head}{d:%d.%m.%Y} {WEEKDAYS_TR[d.weekday()]} {d:%H:%M}  "
        f"{slot.practitioner.name}\n"
        f"    {slot.practitioner.speciality} — {slot.practitioner.location_line}\n"
        f"    {slot.visit_motive_name or 'sebep belirtilmedi'}\n"
        f"    {slot.practitioner.link}"
    )


def format_report(slots: list[Slot], intent: SearchIntent, limit: int = 10) -> str:
    if not slots:
        return (
            f"'{intent.specialty_label}' için {intent.location_label or intent.location} bölgesinde "
            f"({intent.window_summary()}) uygun slot bulunamadı."
        )
    lines = [
        f"{len(slots)} uygun randevu bulundu — {intent.specialty_label}, "
        f"{intent.location_label or intent.location}",
        f"Müsaitlik filtresi: {intent.window_summary()}",
        "",
    ]
    lines.extend(format_slot(s, i + 1) for i, s in enumerate(slots[:limit]))
    if len(slots) > limit:
        lines.append(f"\n... ve {len(slots) - limit} tane daha.")
    return "\n".join(lines)


def send_webhook(text: str, url: str | None = None) -> None:
    """DOCTOLIB_WEBHOOK_URL tanımlıysa düz metin gönder (Slack/Discord uyumlu)."""
    target = url or os.environ.get("DOCTOLIB_WEBHOOK_URL")
    if not target:
        return
    try:
        httpx.post(target, json={"text": text, "content": text}, timeout=10.0)
    except Exception as exc:  # noqa: BLE001 - bildirim hatası akışı durdurmasın
        log.warning("Webhook gönderilemedi: %s", exc)
