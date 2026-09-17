"""Veri modelleri: niyet (intent), hekim, randevu slotu, sonuç."""
from __future__ import annotations

from datetime import date, datetime, time
from typing import Literal, Optional

from pydantic import BaseModel, Field, field_validator

Country = Literal["fr", "de", "it"]
Sector = Literal["public", "private", "self_pay", "unknown"]
Urgency = Literal["routine", "soon", "urgent"]

WEEKDAY_NAMES_TR = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]


class TimeWindow(BaseModel):
    """Kullanıcının müsait olduğu tekrar eden zaman aralığı.

    weekdays: 0=Pazartesi ... 6=Pazar
    """

    weekdays: list[int] = Field(
        default_factory=lambda: list(range(7)),
        description="0=Pazartesi, 6=Pazar.",
    )
    start: time = Field(default=time(0, 0), description="24 saat biçiminde 'HH:MM'.")
    end: time = Field(default=time(23, 59), description="24 saat biçiminde 'HH:MM'.")

    @field_validator("start", "end", mode="before")
    @classmethod
    def _lenient_time(cls, v):
        """Modelin 'HH:MM', 'HH' veya '9h' gibi gevşek biçimlerini de kabul et."""
        if not isinstance(v, str):
            return v
        raw = v.strip().lower().replace("h", ":").rstrip(":")
        if not raw:
            return v
        parts = raw.split(":")
        try:
            hour = int(parts[0])
            minute = int(parts[1]) if len(parts) > 1 and parts[1] else 0
        except ValueError:
            return v
        if not (0 <= hour <= 23 and 0 <= minute <= 59):
            return v
        return time(hour, minute)

    @field_validator("weekdays")
    @classmethod
    def _check_weekdays(cls, v: list[int]) -> list[int]:
        bad = [d for d in v if d < 0 or d > 6]
        if bad:
            raise ValueError(f"weekdays 0-6 arasında olmalı, geçersiz: {bad}")
        return sorted(set(v))

    def covers(self, dt: datetime) -> bool:
        if dt.weekday() not in self.weekdays:
            return False
        t = dt.time()
        if self.start <= self.end:
            return self.start <= t <= self.end
        # Gece yarısını aşan aralık (ör. 22:00-02:00)
        return t >= self.start or t <= self.end

    def describe(self) -> str:
        days = ", ".join(WEEKDAY_NAMES_TR[d] for d in self.weekdays)
        return f"{days} {self.start:%H:%M}-{self.end:%H:%M}"


class SearchIntent(BaseModel):
    """Serbest metinden çıkarılan aranabilir niyet."""

    specialty_slugs: list[str] = Field(
        description="Doctolib uzmanlık slug'ları, en olası olan başta (ör. 'medecin-generaliste')."
    )
    specialty_label: str = Field(description="İnsan okunur uzmanlık adı.")
    reason_summary: str = Field(description="Şikayetin tek cümlelik özeti.")
    location: str = Field(description="Doctolib konum slug'ı, ör. 'paris' veya 'berlin'.")
    location_label: str = ""
    country: Country = "fr"
    windows: list[TimeWindow] = Field(default_factory=list)
    earliest_date: Optional[date] = None
    latest_date: Optional[date] = None
    insurance_sector: Sector = "unknown"
    telehealth_ok: bool = False
    urgency: Urgency = "routine"
    red_flags: list[str] = Field(
        default_factory=list,
        description="Acil servise yönlendirmeyi gerektirebilecek uyarı işaretleri.",
    )
    notes: str = ""

    def window_summary(self) -> str:
        if not self.windows:
            return "her zaman"
        return " | ".join(w.describe() for w in self.windows)


class Practitioner(BaseModel):
    id: Optional[int] = None
    name: str
    slug: str
    speciality: str = ""
    address: str = ""
    zipcode: str = ""
    city: str = ""
    link: str = ""
    telehealth: bool = False

    @property
    def location_line(self) -> str:
        return " ".join(p for p in (self.address, self.zipcode, self.city) if p)


class Slot(BaseModel):
    start: datetime
    practitioner: Practitioner
    visit_motive_id: Optional[int] = None
    visit_motive_name: str = ""
    agenda_id: Optional[int] = None
    practice_id: Optional[int] = None
    booking_url: str = ""
    # Doctolib bazı slotlarda çok adımlı "steps" döner; olduğu gibi taşıyoruz.
    steps: Optional[list] = None

    def key(self) -> str:
        return f"{self.practitioner.slug}|{self.start.isoformat()}|{self.visit_motive_id}"


class BookingResult(BaseModel):
    ok: bool
    slot: Optional[Slot] = None
    message: str = ""
    confirmation_url: str = ""
    screenshot_path: str = ""
