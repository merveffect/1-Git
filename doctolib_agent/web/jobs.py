"""Arka plan tarama işleri.

Doctolib'e giden istekleri nazik tutmak için tek bir çalışan iş parçacığı var;
işler sıraya girer, paralel tarama yapılmaz.
"""
from __future__ import annotations

import logging
import queue
import threading
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Literal, Optional

from ..agent import book_slots, build_client, closing_client, scan_once
from ..booker import browser_session
from ..config import AgentConfig
from ..intent import parse_intent
from ..models import SearchIntent, Slot

log = logging.getLogger(__name__)

JobStatus = Literal["queued", "running", "done", "error", "cancelled"]
MAX_JOBS = 50


@dataclass
class Job:
    id: str
    text: str
    status: JobStatus = "queued"
    created_at: datetime = field(default_factory=datetime.now)
    finished_at: Optional[datetime] = None
    intent: Optional[SearchIntent] = None
    slots: list[Slot] = field(default_factory=list)
    log: list[str] = field(default_factory=list)
    error: str = ""
    booking_message: str = ""
    booking_ok: bool = False

    def add_log(self, line: str) -> None:
        self.log.append(line)
        del self.log[:-200]  # sınırsız büyümesin

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "text": self.text,
            "status": self.status,
            "created_at": self.created_at.isoformat(timespec="seconds"),
            "finished_at": self.finished_at.isoformat(timespec="seconds") if self.finished_at else None,
            "intent": _intent_dict(self.intent),
            "slots": [_slot_dict(s) for s in self.slots],
            "log": self.log,
            "error": self.error,
            "booking_message": self.booking_message,
            "booking_ok": self.booking_ok,
        }


def _intent_dict(intent: SearchIntent | None) -> dict[str, Any] | None:
    if intent is None:
        return None
    return {
        "reason_summary": intent.reason_summary,
        "specialty_label": intent.specialty_label,
        "specialty_slugs": intent.specialty_slugs,
        "location_label": intent.location_label or intent.location,
        "windows": intent.window_summary(),
        "urgency": intent.urgency,
        "red_flags": intent.red_flags,
        "earliest_date": intent.earliest_date.isoformat() if intent.earliest_date else None,
        "latest_date": intent.latest_date.isoformat() if intent.latest_date else None,
        "notes": intent.notes,
    }


def _slot_dict(slot: Slot) -> dict[str, Any]:
    return {
        "key": slot.key(),
        "start": slot.start.isoformat(),
        "date": slot.start.strftime("%d.%m.%Y"),
        "time": slot.start.strftime("%H:%M"),
        "weekday": slot.start.weekday(),
        "practitioner": slot.practitioner.name,
        "speciality": slot.practitioner.speciality,
        "address": slot.practitioner.location_line,
        "motive": slot.visit_motive_name,
        "link": slot.practitioner.link,
        "telehealth": slot.practitioner.telehealth,
    }


class JobRunner:
    """Tek çalışanlı iş kuyruğu."""

    def __init__(self, cfg: AgentConfig) -> None:
        self.cfg = cfg
        self.jobs: dict[str, Job] = {}
        self.order: list[str] = []
        self._queue: "queue.Queue[str]" = queue.Queue()
        self._lock = threading.Lock()
        self._worker = threading.Thread(target=self._loop, name="doctolib-worker", daemon=True)
        self._worker.start()

    # ---------- genel arayüz ----------

    def submit(self, text: str) -> Job:
        job = Job(id=uuid.uuid4().hex[:12], text=text.strip())
        with self._lock:
            self.jobs[job.id] = job
            self.order.append(job.id)
            self._evict_old()
        self._queue.put(job.id)
        return job

    def get(self, job_id: str) -> Optional[Job]:
        with self._lock:
            return self.jobs.get(job_id)

    def recent(self, limit: int = 10) -> list[Job]:
        with self._lock:
            ids = self.order[-limit:][::-1]
            return [self.jobs[i] for i in ids if i in self.jobs]

    def book(self, job_id: str, slot_key: str) -> tuple[bool, str]:
        """Seçilen slotu sunucu tarafında rezerve etmeyi dene (sadece auto modu)."""
        job = self.get(job_id)
        if job is None:
            return False, "İş bulunamadı."
        if self.cfg.booking.mode != "auto":
            return False, (
                "Sunucu tarafı rezervasyon kapalı (booking.mode: "
                f"{self.cfg.booking.mode}). Doctolib bağlantısını telefonda aç ve oradan tamamla."
            )
        slot = next((s for s in job.slots if s.key() == slot_key), None)
        if slot is None:
            return False, "Slot bu iş içinde bulunamadı."

        try:
            results = book_slots(self.cfg, [slot], progress=job.add_log)
        except Exception as exc:  # noqa: BLE001 - hata kullanıcıya dönsün
            log.exception("Rezervasyon hatası")
            job.booking_message = f"Rezervasyon hatası: {exc}"
            job.booking_ok = False
            return False, job.booking_message

        if not results:
            job.booking_message = "Rezervasyon denenmedi."
            return False, job.booking_message
        job.booking_ok = results[0].ok
        job.booking_message = results[0].message
        return job.booking_ok, job.booking_message

    # ---------- dahili ----------

    def _evict_old(self) -> None:
        while len(self.order) > MAX_JOBS:
            old = self.order.pop(0)
            self.jobs.pop(old, None)

    def _loop(self) -> None:
        while True:
            job_id = self._queue.get()
            job = self.get(job_id)
            if job is None:
                continue
            try:
                self._run(job)
            except Exception as exc:  # noqa: BLE001 - çalışan ölmesin
                log.exception("İş başarısız: %s", job_id)
                job.status = "error"
                job.error = str(exc)
            finally:
                job.finished_at = datetime.now()

    def _run(self, job: Job) -> None:
        job.status = "running"
        job.add_log("İstek çözümleniyor...")
        job.intent = parse_intent(job.text, self.cfg)
        job.add_log(
            f"{job.intent.specialty_label} @ {job.intent.location_label or job.intent.location}"
        )
        if job.intent.red_flags:
            job.add_log("⚠ Acil değerlendirme işaretleri: " + "; ".join(job.intent.red_flags))

        if self.cfg.transport == "browser":
            with browser_session(self.cfg, headless=True) as page:
                page.goto(self.cfg.base_url, wait_until="domcontentloaded")
                client = build_client(self.cfg, page=page)
                job.slots = scan_once(self.cfg, job.intent, client, progress=job.add_log)
        else:
            with closing_client(self.cfg) as client:
                job.slots = scan_once(self.cfg, job.intent, client, progress=job.add_log)

        job.add_log(f"{len(job.slots)} uygun randevu bulundu.")
        job.status = "done"
