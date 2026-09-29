#!/usr/bin/env python3
"""
EN KUCUK CALISAN AGENT - ogrenme amacli.

Amac: "agent" diye bir urun olmadigini gostermek. Agent = bir dongu
icinde model cagirmak + modele arac vermek. Hepsi bu.

Calistirmak icin:
    pip install -r requirements.txt
    gcloud auth application-default login
    export GCP_PROJECT=researcher-360-prod-e7fd74be
    export GCP_LOCATION=europe-west1          # Vertex baglantinla ayni bolge
    python demo_agent.py "hangi roller var ve hcp kac kisi?"

NOT: Bu dosya gercek projeyi calistirmiyor. Sadece agent mekanigini
gosteriyor. Gercek agent dbt pipeline'i bittikten sonra yazilacak.
"""

import os
import sys

from google import genai
from google.genai import types

PROJECT = os.environ.get("GCP_PROJECT", "researcher-360-prod-e7fd74be")
LOCATION = os.environ.get("GCP_LOCATION", "europe-west1")
MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")


# ───────────────────────────────────────────────────────────────────────────
# ARACLAR (TOOLS)
#
# Bunlar sadece normal Python fonksiyonlari. Ozel bir sey yok.
# Modelin gordugu tek sey: fonksiyon adi, parametreleri ve DOCSTRING.
# Docstring = modelin bu araci ne zaman kullanacagini anladigi yer.
# Iyi docstring = iyi agent. Prompt muhendisliginin yarisi burada.
# ───────────────────────────────────────────────────────────────────────────

def list_roles() -> dict:
    """Sistemde tanimli olan tum rolleri ve aciklamalarini dondurur.

    Kullanicinin hangi rolleri sorabilecegini ogrenmek icin, veya bir
    rol adinin gecerli olup olmadigini kontrol etmek icin kullan.
    """
    # Gercekte: dbt_project.yml'den veya BigQuery'den okunur
    return {
        "roles": [
            {"key": "hcp", "label": "Healthcare Professional"},
            {"key": "pharmacist", "label": "Pharmacist"},
            {"key": "librarian", "label": "Librarian"},
            {"key": "researcher", "label": "Researcher (all fields)"},
            {"key": "faculty_head", "label": "Head of Faculty"},
        ]
    }


def count_audience(role_key: str, country_code: str = "") -> dict:
    """Belirtilen rol icin audience buyuklugunu dondurur.

    Args:
        role_key: list_roles()'un dondurdugu anahtarlardan biri.
                  Emin degilsen once list_roles() cagir.
        country_code: ISO ulke kodu (orn. 'DE'). Bos birakilirsa tum dunya.

    Returns:
        identified  - tespit edilen kisi sayisi
        marketable  - pazarlama izni olanlar (asil onemli sayi)
    """
    # Gercekte: BigQuery'de marts.fct_role_audience_summary sorgulanir
    fake = {"hcp": (47231, 10580), "librarian": (8140, 2210),
            "researcher": (112400, 24900), "pharmacist": (6320, 1410),
            "faculty_head": (9870, 2050)}
    if role_key not in fake:
        return {"error": f"bilinmeyen rol: {role_key}. once list_roles() cagir."}
    identified, marketable = fake[role_key]
    if country_code:
        identified, marketable = identified // 12, marketable // 12
    return {
        "role_key": role_key,
        "country_code": country_code or "ALL",
        "identified": identified,
        "marketable": marketable,
    }


TOOLS = [list_roles, count_audience]


# ───────────────────────────────────────────────────────────────────────────
# AGENT
#
# Agent'i agent yapan sey su: model KENDISI hangi araci ne zaman
# cagiracagina karar veriyor. Biz sirayi yazmiyoruz.
#
# "hcp kac kisi?" sorusunda model kendi basina:
#   1. list_roles() cagirir  -> 'hcp' gecerli mi bakar
#   2. count_audience('hcp') -> sayiyi alir
#   3. cevabi yazar
# Bu sirayi biz kodlamadik. Model kurdu. Fark bu.
# ───────────────────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """Sen ORCID verisinden rol bazli audience cikaran bir asistansin.

Kurallar:
- Rol adindan emin degilsen ONCE list_roles() cagir, tahmin etme.
- Sayi verirken HER ZAMAN hem 'identified' hem 'marketable' sayisini soyle.
  Pazarlama ekibi icin onemli olan 'marketable' - onu vurgula.
- Elinde veri yoksa uydurma, aracla dogrula.
- Kisa ve net cevap ver.
"""


def main() -> None:
    question = " ".join(sys.argv[1:]) or "hangi roller var?"

    # vertexai=True -> Vertex AI uzerinden gider (ayri API anahtari GEREKMEZ,
    # application-default credentials kullanir). Embedding icin kullandigin
    # AYNI erisim.
    client = genai.Client(vertexai=True, project=PROJECT, location=LOCATION)

    print(f"\n[soru] {question}\n")

    # automatic_function_calling: SDK dongu'yu kendisi cevirir.
    # Model arac cagirir -> SDK fonksiyonu calistirir -> sonucu modele
    # geri verir -> model devam eder. Elle while dongusu yazmana gerek yok.
    response = client.models.generate_content(
        model=MODEL,
        contents=question,
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM_PROMPT,
            tools=TOOLS,
            temperature=0.0,
        ),
    )

    print(f"[cevap]\n{response.text}\n")

    # Modelin hangi araclari cagirdigini gor - agent'i anlamanin en iyi yolu
    history = getattr(response, "automatic_function_calling_history", None)
    if history:
        print("[modelin kendi kararlari]")
        for item in history:
            for part in getattr(item, "parts", []) or []:
                if getattr(part, "function_call", None):
                    fc = part.function_call
                    print(f"  -> {fc.name}({dict(fc.args)})")


if __name__ == "__main__":
    main()
