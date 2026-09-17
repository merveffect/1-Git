"""Playwright ile rezervasyon akışı.

Doctolib'in DOM'u sık değişir. Bu yüzden seçiciler tek tek sabit yazılmak yerine
`SELECTORS` içinde aday listeleri olarak tutulur ve ilk tutan kullanılır;
`selectors.yaml` ile kod değiştirmeden güncellenebilir.

Modlar:
  notify -> buraya hiç gelinmez (tarayıcı açılmaz)
  assist -> son onay ekranına kadar götürür, son tıkı insan yapar
  auto   -> son onayı da agent yapar
"""
from __future__ import annotations

import logging
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path
from typing import Any, Iterator, Sequence

import yaml

from .config import AgentConfig
from .models import BookingResult, Slot

log = logging.getLogger(__name__)

SELECTORS: dict[str, list[str]] = {
    "cookie_accept": [
        "#didomi-notice-agree-button",
        "button:has-text('Accepter')",
        "button:has-text('Akzeptieren')",
        "button:has-text('Accept')",
    ],
    "logged_in_marker": [
        "[data-design-system-component='Avatar']",
        "a[href*='/account']",
        ".dl-navbar-account",
    ],
    "booking_button": [
        "a:has-text('Prendre rendez-vous')",
        "button:has-text('Prendre rendez-vous')",
        "a:has-text('Termin buchen')",
    ],
    "slot_button": [
        "button.availabilities-slot",
        "[data-test='availability-slot']",
        "button[data-slot-date]",
    ],
    "next_step": [
        "button:has-text('Confirmer')",
        "button:has-text('Suivant')",
        "button:has-text('Continuer')",
        "button:has-text('Weiter')",
        "button:has-text('Bestätigen')",
    ],
    "final_confirm": [
        "button:has-text('Confirmer le rendez-vous')",
        "button:has-text('Confirmer mon rendez-vous')",
        "button:has-text('Termin bestätigen')",
        "[data-test='confirm-appointment']",
    ],
    "confirmation_marker": [
        "text=/rendez-vous (est )?confirm/i",
        "text=/Termin.*bestätigt/i",
        "[data-test='appointment-confirmed']",
    ],
}


def load_selectors(path: str | Path | None) -> dict[str, list[str]]:
    """Varsayılan seçicileri isteğe bağlı bir YAML ile birleştir."""
    merged = {k: list(v) for k, v in SELECTORS.items()}
    if not path:
        return merged
    p = Path(path)
    if not p.exists():
        return merged
    override = yaml.safe_load(p.read_text(encoding="utf-8")) or {}
    for key, value in override.items():
        vals = value if isinstance(value, list) else [value]
        # Kullanıcı seçicileri önce denensin.
        merged[key] = [str(v) for v in vals] + merged.get(key, [])
    return merged


def _first_visible(page: Any, candidates: Sequence[str], timeout: float = 4000) -> Any | None:
    """Aday seçicilerden görünür olan ilkini döndür."""
    for sel in candidates:
        try:
            loc = page.locator(sel).first
            loc.wait_for(state="visible", timeout=timeout)
            return loc
        except Exception:  # noqa: BLE001 - seçici tutmadı, sıradakine geç
            continue
    return None


@contextmanager
def browser_session(cfg: AgentConfig, headless: bool | None = None) -> Iterator[Any]:
    """Kalıcı oturumlu bir Playwright sayfası aç."""
    from playwright.sync_api import sync_playwright

    state_path = Path(cfg.booking.storage_state)
    use_headless = cfg.booking.headless if headless is None else headless

    with sync_playwright() as pw:
        browser = pw.chromium.launch(
            headless=use_headless,
            slow_mo=cfg.booking.slow_mo_ms,
            args=["--disable-blink-features=AutomationControlled"],
        )
        ctx_kwargs: dict[str, Any] = {
            "locale": {"fr": "fr-FR", "de": "de-DE", "it": "it-IT"}.get(cfg.country, "fr-FR"),
            "user_agent": cfg.scan.user_agent,
            "viewport": {"width": 1366, "height": 900},
        }
        if state_path.exists():
            ctx_kwargs["storage_state"] = str(state_path)
        context = browser.new_context(**ctx_kwargs)
        page = context.new_page()
        try:
            yield page
        finally:
            try:
                context.storage_state(path=str(state_path))
            except Exception as exc:  # noqa: BLE001
                log.warning("Oturum durumu kaydedilemedi: %s", exc)
            context.close()
            browser.close()


def login_interactive(cfg: AgentConfig) -> bool:
    """Tarayıcıyı aç, kullanıcı elle giriş yapsın, oturumu kaydet.

    Parola hiçbir zaman yapılandırmada tutulmaz - giriş insana ait.
    """
    selectors = load_selectors("selectors.yaml")
    with browser_session(cfg, headless=False) as page:
        page.goto(f"{cfg.base_url}/sessions/new", wait_until="domcontentloaded")
        btn = _first_visible(page, selectors["cookie_accept"], timeout=5000)
        if btn:
            btn.click()
        print("\nTarayıcıda Doctolib hesabına giriş yap (2FA dahil).")
        print("Giriş bitince bu pencereye dön ve Enter'a bas...")
        input()
        marker = _first_visible(page, selectors["logged_in_marker"], timeout=8000)
        ok = marker is not None
        print("Oturum kaydedildi." if ok else "Giriş doğrulanamadı; yine de durum kaydedildi.")
        return ok


class Booker:
    def __init__(self, cfg: AgentConfig, page: Any, selectors_path: str | None = "selectors.yaml") -> None:
        self.cfg = cfg
        self.page = page
        self.sel = load_selectors(selectors_path)
        self.shots = Path(cfg.booking.screenshot_dir)
        self.shots.mkdir(parents=True, exist_ok=True)

    # ---------- yardımcılar ----------

    def _screenshot(self, tag: str) -> str:
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        path = self.shots / f"{stamp}-{tag}.png"
        try:
            self.page.screenshot(path=str(path), full_page=True)
        except Exception as exc:  # noqa: BLE001
            log.warning("Ekran görüntüsü alınamadı: %s", exc)
            return ""
        return str(path)

    def _dismiss_cookies(self) -> None:
        btn = _first_visible(self.page, self.sel["cookie_accept"], timeout=3000)
        if btn:
            btn.click()

    def is_logged_in(self) -> bool:
        return _first_visible(self.page, self.sel["logged_in_marker"], timeout=5000) is not None

    # ---------- akış ----------

    def open_slot(self, slot: Slot) -> bool:
        """Slot'un rezervasyon akışını aç ve o saati seç."""
        self.page.goto(slot.booking_url, wait_until="domcontentloaded")
        self._dismiss_cookies()

        book = _first_visible(self.page, self.sel["booking_button"], timeout=6000)
        if book:
            book.click()

        label = slot.start.strftime("%H:%M")
        # Önce tam saat etiketine sahip bir slot düğmesi ara.
        for sel in self.sel["slot_button"]:
            loc = self.page.locator(f"{sel}:has-text('{label}')").first
            try:
                loc.wait_for(state="visible", timeout=4000)
                loc.click()
                return True
            except Exception:  # noqa: BLE001
                continue

        # Etiketle bulunamadıysa saat metnini doğrudan dene.
        try:
            self.page.get_by_text(label, exact=True).first.click(timeout=4000)
            return True
        except Exception as exc:  # noqa: BLE001
            log.warning("%s saatli slot sayfada bulunamadı: %s", label, exc)
            return False

    def advance_to_confirmation(self, max_steps: int = 8) -> bool:
        """Ara adımları (sebep, hasta seçimi, sorular) geçip son onay ekranına gel."""
        for step in range(max_steps):
            final = _first_visible(self.page, self.sel["final_confirm"], timeout=2500)
            if final:
                return True
            nxt = _first_visible(self.page, self.sel["next_step"], timeout=3000)
            if not nxt:
                log.info("Adım %d: ilerleyecek düğme yok, akış burada duruyor.", step + 1)
                return False
            nxt.click()
            self.page.wait_for_load_state("networkidle", timeout=15000)
        return _first_visible(self.page, self.sel["final_confirm"], timeout=2500) is not None

    def book(self, slot: Slot) -> BookingResult:
        mode = self.cfg.booking.mode

        if not self.is_logged_in():
            return BookingResult(
                ok=False,
                slot=slot,
                message="Doctolib oturumu yok. Önce `doctolib-agent login` çalıştır.",
            )

        if not self.open_slot(slot):
            return BookingResult(
                ok=False, slot=slot,
                message="Slot açılamadı - muhtemelen bu arada kapıldı.",
                screenshot_path=self._screenshot("slot-not-found"),
            )

        reached = self.advance_to_confirmation()
        shot = self._screenshot("confirmation-screen" if reached else "stalled")

        if not reached:
            return BookingResult(
                ok=False, slot=slot,
                message="Son onay ekranına ulaşılamadı (ek soru/adım olabilir). Tarayıcı açık, elle tamamlayabilirsin.",
                screenshot_path=shot,
            )

        if mode == "assist":
            return BookingResult(
                ok=False, slot=slot,
                message=(
                    "Son onay ekranına gelindi. Randevuyu kesinleştirmek için tarayıcıdaki "
                    "onay düğmesine sen bas. (Tam otomatik için booking.mode: auto)"
                ),
                confirmation_url=self.page.url,
                screenshot_path=shot,
            )

        # mode == "auto"
        final = _first_visible(self.page, self.sel["final_confirm"], timeout=5000)
        if not final:
            return BookingResult(ok=False, slot=slot, message="Onay düğmesi kayboldu.", screenshot_path=shot)
        final.click()
        self.page.wait_for_load_state("networkidle", timeout=20000)

        confirmed = _first_visible(self.page, self.sel["confirmation_marker"], timeout=8000)
        done_shot = self._screenshot("booked" if confirmed else "post-confirm-unclear")
        if confirmed:
            return BookingResult(
                ok=True, slot=slot,
                message="Randevu onaylandı.",
                confirmation_url=self.page.url,
                screenshot_path=done_shot,
            )
        return BookingResult(
            ok=False, slot=slot,
            message="Onaya basıldı ama doğrulama metni görülmedi. Hesabındaki randevuları kontrol et.",
            confirmation_url=self.page.url,
            screenshot_path=done_shot,
        )
