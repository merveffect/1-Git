from datetime import date

from doctolib_agent.client import BookingPage, DoctolibClient
from doctolib_agent.config import AgentConfig
from doctolib_agent.models import Practitioner


class FakeTransport:
    """Kayıtlı cevapları döndüren sahte taşıma."""

    def __init__(self, responses):
        self.responses = responses
        self.calls = []

    def get_json(self, url, params=None):
        self.calls.append((url, params or {}))
        for key, value in self.responses.items():
            if key in url:
                return value
        return None


def make_client(responses):
    cfg = AgentConfig()
    return DoctolibClient(cfg, FakeTransport(responses)), cfg


def test_search_parses_doctors_and_dedupes():
    doctors = [
        {"id": 1, "name_with_title": "Dr Ada", "link": "/orl/paris/ada-l", "speciality": "ORL",
         "city": "Paris", "zipcode": "75011", "address": "1 rue X"},
        {"id": 1, "name_with_title": "Dr Ada", "link": "/orl/paris/ada-l", "speciality": "ORL"},
    ]
    client, _ = make_client({"/search_results/": {"data": {"doctors": doctors}}})
    found = client.search_practitioners("orl", "paris")
    assert len(found) == 1
    assert found[0].slug == "ada-l"
    assert found[0].link.endswith("/orl/paris/ada-l")
    assert found[0].location_line == "1 rue X 75011 Paris"


def test_booking_page_motive_filtering_falls_back_to_all():
    page = BookingPage(
        practitioner=Practitioner(name="Dr A", slug="a"),
        visit_motives=[{"id": 1, "name": "Consultation ORL"}, {"id": 2, "name": "Vaccin"}],
        agendas=[],
        places=[],
        raw={},
    )
    assert [m["id"] for m in page.motives_matching(["orl"])] == [1]
    # Hiçbiri tutmazsa eleme yapma - slot kaçırmaktansa fazla bakmak iyidir.
    assert len(page.motives_matching(["kardiyoloji"])) == 2
    assert len(page.motives_matching([])) == 2


def test_agendas_skip_disabled():
    page = BookingPage(
        practitioner=Practitioner(name="Dr A", slug="a"),
        visit_motives=[],
        agendas=[
            {"id": 10, "visit_motive_ids": [1], "practice_id": 100},
            {"id": 11, "visit_motive_ids": [1], "practice_id": 100, "booking_disabled": True},
            {"id": 12, "visit_motive_ids": [2], "practice_id": 100},
        ],
        places=[],
        raw={},
    )
    assert [a["id"] for a in page.agendas_for_motive(1)] == [10]


def test_availabilities_handles_string_and_object_slots():
    avail = {
        "availabilities": [
            {"date": "2026-10-01", "slots": ["2026-10-01T09:00:00.000+02:00"]},
            {"date": "2026-10-02", "slots": [
                {"start_date": "2026-10-02T14:30:00.000+02:00", "agenda_id": 77, "practice_id": 5,
                 "steps": [{"start_date": "2026-10-02T14:30:00.000+02:00"}]},
                {"steps": [{"start_date": "2026-10-02T15:00:00.000+02:00"}]},
                {"start_date": "bozuk-tarih"},
                "tamamen-bozuk",
            ]},
        ]
    }
    client, _ = make_client({"/availabilities.json": avail})
    page = BookingPage(
        practitioner=Practitioner(name="Dr A", slug="a"),
        visit_motives=[],
        agendas=[{"id": 10, "visit_motive_ids": [1], "practice_id": 100}],
        places=[], raw={},
    )
    slots = client.availabilities(page, {"id": 1, "name": "Consultation"}, date(2026, 10, 1), 7)

    assert len(slots) == 3  # bozuk iki kayıt sessizce elendi
    assert slots[0].start.hour == 9
    assert slots[1].agenda_id == 77 and slots[1].practice_id == 5
    # Nesnede agenda yoksa ajandadan miras alınır.
    assert slots[2].agenda_id == 10
    assert all(s.visit_motive_name == "Consultation" for s in slots)


def test_availabilities_without_matching_agenda_returns_empty():
    client, _ = make_client({"/availabilities.json": {"availabilities": []}})
    page = BookingPage(
        practitioner=Practitioner(name="Dr A", slug="a"),
        visit_motives=[], agendas=[{"id": 10, "visit_motive_ids": [99]}], places=[], raw={},
    )
    assert client.availabilities(page, {"id": 1}, date(2026, 10, 1), 7) == []


def test_availabilities_sends_joined_ids():
    client, _ = make_client({"/availabilities.json": {"availabilities": []}})
    page = BookingPage(
        practitioner=Practitioner(name="Dr A", slug="a"),
        visit_motives=[],
        agendas=[
            {"id": 10, "visit_motive_ids": [1], "practice_id": 100},
            {"id": 11, "visit_motive_ids": [1], "practice_id": 101},
        ],
        places=[], raw={},
    )
    client.availabilities(page, {"id": 1}, date(2026, 10, 1), 7, insurance_sector="public")
    _, params = client.transport.calls[-1]
    assert params["agenda_ids"] == "10-11"
    assert params["practice_ids"] == "100-101"
    assert params["insurance_sector"] == "public"
