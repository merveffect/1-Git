"""YAML yapılandırması ve kullanıcı profili."""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Literal

import yaml

BookingMode = Literal["notify", "assist", "auto"]

DEFAULT_CONFIG_PATH = Path("doctolib.yaml")


@dataclass
class Profile:
    """Randevu formunu dolduran kişisel bilgiler."""

    first_name: str = ""
    last_name: str = ""
    birthdate: str = ""          # GG/AA/YYYY
    phone: str = ""
    email: str = ""
    insurance_sector: str = "unknown"

    def missing_fields(self) -> list[str]:
        return [f for f in ("first_name", "last_name", "birthdate", "phone", "email") if not getattr(self, f)]


@dataclass
class ScanSettings:
    """Tarama davranışı. Varsayılanlar bilinçli olarak 'nazik'."""

    horizon_days: int = 21            # kaç gün ileriye bakılacak
    poll_interval_seconds: int = 900  # watch modunda tur arası bekleme
    min_request_interval: float = 1.5  # aynı host'a ardışık istekler arası min saniye
    jitter_seconds: float = 0.8
    max_practitioners: int = 25        # tur başına incelenecek hekim sayısı tavanı
    max_pages: int = 2                 # arama sonucu sayfa tavanı
    request_timeout: float = 20.0
    user_agent: str = (
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    )

    def __post_init__(self) -> None:
        # Sunucuyu dövmemek için sert alt sınırlar.
        self.poll_interval_seconds = max(300, int(self.poll_interval_seconds))
        self.min_request_interval = max(1.0, float(self.min_request_interval))
        self.horizon_days = max(1, min(int(self.horizon_days), 90))


@dataclass
class BookingSettings:
    """Rezervasyon davranışı.

    notify : sadece uygun slotları bildirir, tarayıcı açmaz.
    assist : tarayıcıyı açar, son onay ekranına kadar götürür, son tıkı sen yaparsın. (varsayılan)
    auto   : son onayı da agent yapar. Bilinçli olarak opt-in.
    """

    mode: BookingMode = "assist"
    max_bookings_per_run: int = 1
    headless: bool = False
    storage_state: str = ".doctolib_state.json"
    slow_mo_ms: int = 150
    screenshot_dir: str = "doctolib_screenshots"
    confirm_timeout_seconds: int = 300

    def __post_init__(self) -> None:
        # Kaçak bir döngünün ondan fazla randevu kapmasını engelle.
        self.max_bookings_per_run = max(1, min(int(self.max_bookings_per_run), 3))


@dataclass
class AgentConfig:
    country: str = "de"
    # Aramanın her zaman yapılacağı Doctolib konum slug'ı. Modelin metinden
    # çıkardığı konumu ezer - boş bırakılırsa model ne bulursa o kullanılır.
    location: str = "berlin"
    location_label: str = "Berlin"
    transport: Literal["http", "browser"] = "http"
    model: str = "claude-opus-5"
    profile: Profile = field(default_factory=Profile)
    scan: ScanSettings = field(default_factory=ScanSettings)
    booking: BookingSettings = field(default_factory=BookingSettings)
    blackout_dates: list[str] = field(default_factory=list)
    preferred_practitioners: list[str] = field(default_factory=list)
    excluded_practitioners: list[str] = field(default_factory=list)

    @property
    def base_url(self) -> str:
        return f"https://www.doctolib.{self.country}"

    @classmethod
    def load(cls, path: str | os.PathLike[str] | None = None) -> "AgentConfig":
        p = Path(path or DEFAULT_CONFIG_PATH)
        if not p.exists():
            raise FileNotFoundError(
                f"Yapılandırma bulunamadı: {p}\n"
                "`config.example.yaml` dosyasını `doctolib.yaml` olarak kopyalayıp doldur."
            )
        raw: dict[str, Any] = yaml.safe_load(p.read_text(encoding="utf-8")) or {}
        return cls.from_dict(raw)

    @classmethod
    def from_dict(cls, raw: dict[str, Any]) -> "AgentConfig":
        return cls(
            country=raw.get("country", "de"),
            location=raw.get("location", "berlin"),
            location_label=raw.get("location_label") or str(raw.get("location", "berlin")).title(),
            transport=raw.get("transport", "http"),
            model=raw.get("model", "claude-opus-5"),
            profile=Profile(**(raw.get("profile") or {})),
            scan=ScanSettings(**(raw.get("scan") or {})),
            booking=BookingSettings(**(raw.get("booking") or {})),
            blackout_dates=list(raw.get("blackout_dates") or []),
            preferred_practitioners=list(raw.get("preferred_practitioners") or []),
            excluded_practitioners=list(raw.get("excluded_practitioners") or []),
        )
