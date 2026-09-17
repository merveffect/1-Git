"""Serbest metni (Türkçe/İngilizce/Fransızca) aranabilir niyete çevirir."""
from __future__ import annotations

import logging
from datetime import date

import anthropic

from .config import AgentConfig
from .models import SearchIntent

log = logging.getLogger(__name__)

# Doctolib'in uzmanlık slug'ları ülkeye göre değişir. Model bunları çıkış noktası
# olarak kullanır; tam liste değildir, en sık kullanılanlardır.
COMMON_SLUGS = {
    "fr": [
        "medecin-generaliste", "dentiste", "pediatre", "dermatologue", "ophtalmologue",
        "gynecologue", "orl", "cardiologue", "psychiatre", "psychologue",
        "kinesitherapeute", "sage-femme", "rhumatologue", "gastro-enterologue",
        "endocrinologue-diabetologue", "pneumologue", "neurologue", "urologue",
        "chirurgien-orthopediste", "allergologue", "radiologue", "podologue",
        "osteopathe", "dieteticien", "orthodontiste", "infirmier",
    ],
    "de": [
        "allgemeinmedizin", "zahnarzt", "kinderarzt", "hautarzt", "augenarzt",
        "frauenarzt", "hals-nasen-ohren-arzt", "kardiologe", "psychiater",
        "psychotherapeut", "physiotherapeut", "orthopade", "urologe",
        "neurologe", "internist", "radiologe", "dermatologe",
    ],
    "it": [
        "medico-di-base", "dentista", "pediatra", "dermatologo", "oculista",
        "ginecologo", "otorinolaringoiatra", "cardiologo", "psichiatra",
        "psicologo", "fisioterapista", "ortopedico", "urologo", "neurologo",
    ],
}

SYSTEM = """Sen bir sağlık randevusu arama asistanısın. Kullanıcının serbest metinle
yazdığı şikayetini ve müsaitlik tercihini, Doctolib'de aranabilir yapılandırılmış
bir niyete çevirirsin.

Kurallar:
- `specialty_slugs`: Doctolib URL slug'ları, en olası olan başta, en fazla 3 tane.
  Emin değilsen daha genel olanı (aile hekimi) da listeye ekle.
- `location`: Doctolib konum slug'ı - küçük harf, boşluklar tire. "Paris 11" -> "paris".
- `windows`: Kullanıcının müsait olduğu aralıklar. weekdays 0=Pazartesi..6=Pazar.
  "öğleden sonra" = 12:00-18:00, "sabah" = 08:00-12:00, "akşam" = 18:00-21:00,
  "hafta içi" = 0-4, "hafta sonu" = 5-6. Kullanıcı saat belirtmediyse windows boş bırak.
- `earliest_date` / `latest_date`: Sadece kullanıcı tarih aralığı ima ettiyse doldur
  ("önümüzdeki hafta", "ayın 20'sinden sonra"). Aksi halde null.
- `red_flags`: Acil servis gerektirebilecek işaretler (göğüs ağrısı + nefes darlığı,
  ani felç/konuşma bozukluğu, kontrolsüz kanama, bilinç kaybı, intihar düşüncesi vb.).
  Varsa listele; yoksa boş liste. Teşhis koyma, sadece işaretleri not et.
- Asla tıbbi teşhis yazma. `reason_summary` sadece şikayetin nötr özeti olsun.
"""


def parse_intent(
    text: str,
    cfg: AgentConfig,
    client: anthropic.Anthropic | None = None,
) -> SearchIntent:
    """Kullanıcının cümlesini `SearchIntent`e çevir."""
    client = client or anthropic.Anthropic()
    slugs = COMMON_SLUGS.get(cfg.country, COMMON_SLUGS["fr"])

    prompt = (
        f"Bugünün tarihi: {date.today().isoformat()} ({date.today():%A}).\n"
        f"Ülke: doctolib.{cfg.country}\n"
        f"Sık kullanılan uzmanlık slug'ları: {', '.join(slugs)}\n\n"
        f"Kullanıcının mesajı:\n---\n{text}\n---"
    )

    response = client.messages.parse(
        model=cfg.model,
        max_tokens=4096,
        system=SYSTEM,
        thinking={"type": "adaptive"},
        messages=[{"role": "user", "content": prompt}],
        output_format=SearchIntent,
    )

    if response.stop_reason == "refusal":
        detail = getattr(response.stop_details, "explanation", "") or ""
        raise RuntimeError(f"Model isteği reddetti: {detail}")

    intent = response.parsed_output
    # Ülke bilgisi yapılandırmadan gelir, modelin tahmininden değil.
    intent.country = cfg.country  # type: ignore[assignment]
    if cfg.profile.insurance_sector and intent.insurance_sector == "unknown":
        intent.insurance_sector = cfg.profile.insurance_sector  # type: ignore[assignment]
    return intent
