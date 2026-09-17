from datetime import date, time

from doctolib_agent.models import SearchIntent, TimeWindow

# Claude'un yapılandırılmış çıktı olarak üretmesi beklenen tipik yük.
CLAUDE_PAYLOAD = {
    "specialty_slugs": ["orl", "medecin-generaliste"],
    "specialty_label": "ORL (Kulak Burun Boğaz)",
    "reason_summary": "Üç gündür süren boğaz ağrısı ve yutma güçlüğü",
    "location": "paris",
    "location_label": "Paris",
    "country": "fr",
    "windows": [
        {"weekdays": [1, 3], "start": "12:00", "end": "18:00"},
        {"weekdays": [4], "start": "08:00", "end": "12:00"},
    ],
    "earliest_date": "2026-09-18",
    "latest_date": None,
    "insurance_sector": "public",
    "telehealth_ok": False,
    "urgency": "soon",
    "red_flags": [],
    "notes": "",
}


def test_parses_realistic_model_output():
    intent = SearchIntent.model_validate(CLAUDE_PAYLOAD)
    assert intent.specialty_slugs[0] == "orl"
    assert intent.earliest_date == date(2026, 9, 18)
    assert intent.latest_date is None
    assert intent.windows[0].start == time(12, 0)
    assert intent.windows[1].weekdays == [4]


def test_window_summary_is_human_readable():
    intent = SearchIntent.model_validate(CLAUDE_PAYLOAD)
    assert "Salı, Perşembe 12:00-18:00" in intent.window_summary()
    assert "Cuma 08:00-12:00" in intent.window_summary()


def test_lenient_time_formats():
    assert TimeWindow(weekdays=[0], start="9", end="17").start == time(9, 0)
    assert TimeWindow(weekdays=[0], start="9h30", end="17h").start == time(9, 30)
    assert TimeWindow(weekdays=[0], start="14:00:00").start == time(14, 0)


def test_weekdays_deduped_and_sorted():
    assert TimeWindow(weekdays=[3, 1, 1]).weekdays == [1, 3]


def test_schema_is_json_serialisable():
    import json
    json.dumps(SearchIntent.model_json_schema())
