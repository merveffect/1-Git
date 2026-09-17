"""Doctolib okuma katmanı.

Doctolib'in herkese açık bir API'si yok; buradaki uç noktalar kendi web
istemcisinin kullandığı JSON uçlarıdır. Şema habersiz değişebilir, o yüzden
her ayrıştırma savunmacı yazıldı ve `--debug-dump` ile ham cevap saklanabilir.

İki taşıma modu:
  HttpTransport    - httpx ile hızlı; bot korumasına takılabilir.
  BrowserTransport - Playwright oturumunun çerezleriyle aynı bağlamdan ister.
"""
from __future__ import annotations

import json
import logging
import random
import time
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import Any, Iterable, Optional, Protocol

import httpx

from .config import AgentConfig
from .models import Practitioner, Slot

log = logging.getLogger(__name__)


class RateLimited(RuntimeError):
    """Doctolib 429 / bot koruması döndürdü."""


class Transport(Protocol):
    def get_json(self, url: str, params: dict[str, Any] | None = None) -> Any: ...


class _Throttle:
    """İstekler arasına minimum aralık + jitter koyar."""

    def __init__(self, min_interval: float, jitter: float) -> None:
        self.min_interval = min_interval
        self.jitter = jitter
        self._last = 0.0

    def wait(self) -> None:
        elapsed = time.monotonic() - self._last
        delay = self.min_interval - elapsed
        delay += random.uniform(0, self.jitter)
        if delay > 0:
            time.sleep(delay)
        self._last = time.monotonic()


class HttpTransport:
    def __init__(self, cfg: AgentConfig) -> None:
        self.cfg = cfg
        self.throttle = _Throttle(cfg.scan.min_request_interval, cfg.scan.jitter_seconds)
        self._client = httpx.Client(
            timeout=cfg.scan.request_timeout,
            follow_redirects=True,
            headers={
                "User-Agent": cfg.scan.user_agent,
                "Accept": "application/json, text/plain, */*",
                "Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8",
                "Referer": cfg.base_url + "/",
            },
        )

    def get_json(self, url: str, params: dict[str, Any] | None = None) -> Any:
        backoff = 4.0
        for attempt in range(4):
            self.throttle.wait()
            resp = self._client.get(url, params=params)
            if resp.status_code == 429 or resp.status_code == 403:
                retry_after = resp.headers.get("Retry-After")
                wait = float(retry_after) if retry_after and retry_after.isdigit() else backoff
                log.warning("Doctolib %s döndü, %.0fs bekleniyor (deneme %d)", resp.status_code, wait, attempt + 1)
                time.sleep(wait)
                backoff *= 2
                continue
            if resp.status_code == 404:
                return None
            resp.raise_for_status()
            try:
                return resp.json()
            except json.JSONDecodeError:
                # Bot koruması genelde JSON yerine HTML challenge döndürür.
                raise RateLimited(
                    "JSON yerine HTML geldi - muhtemelen bot koruması. "
                    "`transport: browser` moduna geç."
                )
        raise RateLimited(f"{url} için tekrarlanan 429/403 sonrası vazgeçildi.")

    def close(self) -> None:
        self._client.close()


class BrowserTransport:
    """Playwright sayfa bağlamı üzerinden fetch - oturum çerezlerini paylaşır."""

    def __init__(self, cfg: AgentConfig, page: Any) -> None:
        self.cfg = cfg
        self.page = page
        self.throttle = _Throttle(cfg.scan.min_request_interval, cfg.scan.jitter_seconds)

    def get_json(self, url: str, params: dict[str, Any] | None = None) -> Any:
        self.throttle.wait()
        full = str(httpx.URL(url).copy_merge_params(params or {}))
        resp = self.page.request.get(full, headers={"Accept": "application/json"})
        if resp.status in (403, 429):
            raise RateLimited(f"Tarayıcı bağlamında {resp.status} - oturum/koruma sorunu.")
        if resp.status == 404:
            return None
        if not resp.ok:
            raise RuntimeError(f"{full} -> HTTP {resp.status}")
        try:
            return resp.json()
        except Exception as exc:  # noqa: BLE001 - Playwright kendi hatasını atar
            raise RateLimited(f"JSON ayrıştırılamadı: {exc}")


@dataclass
class BookingPage:
    """/booking/<slug>.json içeriğinin işimize yarayan parçası."""

    practitioner: Practitioner
    visit_motives: list[dict]
    agendas: list[dict]
    places: list[dict]
    raw: dict

    def motives_matching(self, keywords: Iterable[str]) -> list[dict]:
        """Anahtar kelimeye göre ziyaret sebebi süz; eşleşme yoksa hepsini döndür."""
        kws = [k.lower() for k in keywords if k]
        if not kws:
            return self.visit_motives
        hits = [
            m for m in self.visit_motives
            if any(k in str(m.get("name", "")).lower() for k in kws)
        ]
        return hits or self.visit_motives

    def agendas_for_motive(self, motive_id: int) -> list[dict]:
        out = []
        for a in self.agendas:
            if a.get("booking_disabled") or a.get("booking_temporary_disabled"):
                continue
            if motive_id in (a.get("visit_motive_ids") or []):
                out.append(a)
        return out


class DoctolibClient:
    def __init__(self, cfg: AgentConfig, transport: Transport, dump_dir: str | None = None) -> None:
        self.cfg = cfg
        self.transport = transport
        self.base = cfg.base_url
        self.dump_dir = Path(dump_dir) if dump_dir else None
        if self.dump_dir:
            self.dump_dir.mkdir(parents=True, exist_ok=True)

    # ---------- yardımcılar ----------

    def _dump(self, name: str, payload: Any) -> None:
        if not self.dump_dir:
            return
        safe = "".join(c if c.isalnum() or c in "-_." else "_" for c in name)
        (self.dump_dir / f"{safe}.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
        )

    # ---------- arama ----------

    def search_practitioners(self, specialty_slug: str, location_slug: str) -> list[Practitioner]:
        """Uzmanlık + konum için hekim listesi."""
        found: list[Practitioner] = []
        seen: set[str] = set()
        for page in range(1, self.cfg.scan.max_pages + 1):
            url = f"{self.base}/search_results/{specialty_slug}.json"
            data = self.transport.get_json(url, {"location": location_slug, "page": page})
            if not data:
                break
            self._dump(f"search_{specialty_slug}_{location_slug}_p{page}", data)
            doctors = (data.get("data") or {}).get("doctors") or []
            if not doctors:
                break
            for d in doctors:
                slug = self._slug_from_link(d.get("link", ""))
                if not slug or slug in seen:
                    continue
                seen.add(slug)
                found.append(
                    Practitioner(
                        id=d.get("id"),
                        name=d.get("name_with_title") or d.get("name") or slug,
                        slug=slug,
                        speciality=str(d.get("speciality") or specialty_slug),
                        address=str(d.get("address") or ""),
                        zipcode=str(d.get("zipcode") or ""),
                        city=str(d.get("city") or ""),
                        link=self.base + (d.get("link") or ""),
                        telehealth=bool(d.get("telehealth")),
                    )
                )
                if len(found) >= self.cfg.scan.max_practitioners:
                    return found
        return found

    @staticmethod
    def _slug_from_link(link: str) -> str:
        # "/dentiste/paris/jean-dupont" -> "jean-dupont"
        return link.rstrip("/").rsplit("/", 1)[-1] if link else ""

    # ---------- rezervasyon sayfası ----------

    def booking_page(self, practitioner: Practitioner) -> Optional[BookingPage]:
        url = f"{self.base}/booking/{practitioner.slug}.json"
        data = self.transport.get_json(url)
        if not data:
            return None
        self._dump(f"booking_{practitioner.slug}", data)
        body = data.get("data") or {}
        return BookingPage(
            practitioner=practitioner,
            visit_motives=list(body.get("visit_motives") or []),
            agendas=list(body.get("agendas") or []),
            places=list(body.get("places") or []),
            raw=body,
        )

    # ---------- müsaitlik ----------

    def availabilities(
        self,
        page: BookingPage,
        motive: dict,
        start: date,
        days: int,
        insurance_sector: str = "",
    ) -> list[Slot]:
        motive_id = motive.get("id")
        if motive_id is None:
            return []
        agendas = page.agendas_for_motive(motive_id)
        if not agendas:
            return []

        agenda_ids = "-".join(str(a["id"]) for a in agendas if a.get("id") is not None)
        practice_ids = "-".join(
            sorted({str(a["practice_id"]) for a in agendas if a.get("practice_id") is not None})
        )
        params: dict[str, Any] = {
            "start_date": start.isoformat(),
            "visit_motive_ids": str(motive_id),
            "agenda_ids": agenda_ids,
            "practice_ids": practice_ids,
            "limit": min(days, self.cfg.scan.horizon_days),
            "destroy_temporary": "true",
        }
        if insurance_sector and insurance_sector != "unknown":
            params["insurance_sector"] = insurance_sector

        data = self.transport.get_json(f"{self.base}/availabilities.json", params)
        if not data:
            return []
        self._dump(f"avail_{page.practitioner.slug}_{motive_id}_{start}", data)
        return self._parse_slots(data, page, motive, agendas)

    def _parse_slots(
        self, data: dict, page: BookingPage, motive: dict, agendas: list[dict]
    ) -> list[Slot]:
        slots: list[Slot] = []
        default_agenda = agendas[0] if agendas else {}
        for day in data.get("availabilities") or []:
            for raw in day.get("slots") or []:
                parsed = self._slot_from_raw(raw, page, motive, default_agenda)
                if parsed:
                    slots.append(parsed)
        return slots

    def _slot_from_raw(
        self, raw: Any, page: BookingPage, motive: dict, agenda: dict
    ) -> Optional[Slot]:
        # Doctolib slot'u ya düz ISO string ya da nesne olarak döndürür.
        start_raw: Any
        steps = None
        agenda_id = agenda.get("id")
        practice_id = agenda.get("practice_id")
        if isinstance(raw, str):
            start_raw = raw
        elif isinstance(raw, dict):
            start_raw = raw.get("start_date") or raw.get("start")
            steps = raw.get("steps")
            agenda_id = raw.get("agenda_id", agenda_id)
            practice_id = raw.get("practice_id", practice_id)
            if not start_raw and steps:
                start_raw = (steps[0] or {}).get("start_date")
        else:
            return None
        if not start_raw:
            return None
        try:
            start = datetime.fromisoformat(str(start_raw).replace("Z", "+00:00"))
        except ValueError:
            log.debug("Tarih ayrıştırılamadı: %r", start_raw)
            return None

        return Slot(
            start=start,
            practitioner=page.practitioner,
            visit_motive_id=motive.get("id"),
            visit_motive_name=str(motive.get("name") or ""),
            agenda_id=agenda_id,
            practice_id=practice_id,
            booking_url=page.practitioner.link,
            steps=steps,
        )

    # ---------- üst seviye ----------

    def collect_slots(
        self,
        practitioner: Practitioner,
        motive_keywords: Iterable[str],
        start: date,
        days: int,
        insurance_sector: str = "",
    ) -> list[Slot]:
        """Bir hekim için ilgili tüm ziyaret sebeplerinin slotlarını topla."""
        page = self.booking_page(practitioner)
        if page is None:
            return []
        out: list[Slot] = []
        for motive in page.motives_matching(motive_keywords)[:3]:
            try:
                out.extend(self.availabilities(page, motive, start, days, insurance_sector))
            except RateLimited:
                raise
            except Exception as exc:  # noqa: BLE001 - tek hekim yüzünden tur ölmesin
                log.warning("%s / %s müsaitlik alınamadı: %s", practitioner.slug, motive.get("name"), exc)
        return out
