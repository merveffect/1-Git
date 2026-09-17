import contextlib
import time
from datetime import datetime, timedelta
from types import SimpleNamespace

import pytest

fastapi = pytest.importorskip("fastapi")
from fastapi.testclient import TestClient  # noqa: E402

from doctolib_agent.models import Practitioner, SearchIntent, Slot, TimeWindow  # noqa: E402
from doctolib_agent.web import jobs as jobs_mod  # noqa: E402
from doctolib_agent.web.app import create_app  # noqa: E402

CONFIG = """
country: de
location: berlin
location_label: Berlin
booking:
  mode: assist
"""


def fake_intent(text, cfg, client=None):
    return SearchIntent(
        specialty_slugs=["hals-nasen-ohren-arzt"],
        specialty_label="HNO",
        reason_summary="boğaz ağrısı",
        location=cfg.location,
        location_label=cfg.location_label,
        windows=[TimeWindow(weekdays=[1])],
        red_flags=["göğüs ağrısı"] if "göğüs" in text else [],
    )


@contextlib.contextmanager
def fake_closing_client(cfg, page=None, dump_dir=None):
    yield SimpleNamespace(transport=SimpleNamespace(close=lambda: None))


def fake_slots(cfg, intent, client, progress=lambda _m: None):
    progress("sahte tarama")
    when = datetime.now() + timedelta(days=3)
    return [
        Slot(
            start=when,
            practitioner=Practitioner(
                name="Dr Berlin", slug="dr-berlin", speciality="HNO",
                city="Berlin", link="https://www.doctolib.de/hno/berlin/dr-berlin",
            ),
            visit_motive_id=1,
            visit_motive_name="Erstberatung",
        )
    ]


@pytest.fixture()
def client(tmp_path, monkeypatch):
    monkeypatch.setattr(jobs_mod, "parse_intent", fake_intent)
    monkeypatch.setattr(jobs_mod, "scan_once", fake_slots)
    monkeypatch.setattr(jobs_mod, "closing_client", fake_closing_client)
    cfg_file = tmp_path / "doctolib.yaml"
    cfg_file.write_text(CONFIG, encoding="utf-8")
    monkeypatch.delenv("DOCTOLIB_WEB_TOKEN", raising=False)
    with TestClient(create_app(str(cfg_file))) as c:
        yield c


def wait_for_done(client, job_id, timeout=5.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        job = client.get(f"/api/jobs/{job_id}").json()
        if job["status"] in ("done", "error"):
            return job
        time.sleep(0.05)
    raise AssertionError("iş zamanında bitmedi")


def test_config_reports_locked_berlin(client):
    data = client.get("/api/config").json()
    assert data["location"] == "berlin"
    assert data["location_label"] == "Berlin"
    assert data["country"] == "de"
    # assist modunda sunucu tarafı rezervasyon kapalı olmalı.
    assert data["server_booking"] is False


def test_search_runs_and_returns_slots(client):
    job_id = client.post("/api/search", json={"text": "boğazım ağrıyor"}).json()["job_id"]
    job = wait_for_done(client, job_id)
    assert job["status"] == "done"
    assert job["intent"]["location_label"] == "Berlin"
    assert len(job["slots"]) == 1
    slot = job["slots"][0]
    assert slot["practitioner"] == "Dr Berlin"
    assert slot["key"] and slot["link"].startswith("https://www.doctolib.de/")
    assert "sahte tarama" in job["log"]


def test_red_flags_surface_in_response(client):
    job_id = client.post("/api/search", json={"text": "göğüs ağrım var"}).json()["job_id"]
    job = wait_for_done(client, job_id)
    assert job["intent"]["red_flags"] == ["göğüs ağrısı"]


def test_short_text_rejected(client):
    assert client.post("/api/search", json={"text": "a"}).status_code == 422


def test_unknown_job_is_404(client):
    assert client.get("/api/jobs/yok").status_code == 404


def test_booking_blocked_unless_auto_mode(client):
    job_id = client.post("/api/search", json={"text": "boğazım ağrıyor"}).json()["job_id"]
    job = wait_for_done(client, job_id)
    res = client.post(f"/api/jobs/{job_id}/book", json={"slot_key": job["slots"][0]["key"]})
    assert res.status_code == 409
    assert "assist" in res.json()["message"]


def test_history_lists_jobs(client):
    client.post("/api/search", json={"text": "diş ağrısı"})
    job_id = client.post("/api/search", json={"text": "cilt sorunu"}).json()["job_id"]
    wait_for_done(client, job_id)
    texts = [j["text"] for j in client.get("/api/jobs").json()["jobs"]]
    assert "diş ağrısı" in texts and "cilt sorunu" in texts


def test_index_and_static_are_served(client):
    assert "Randevu ara" in client.get("/").text
    assert client.get("/static/app.js").status_code == 200
    assert client.get("/static/manifest.webmanifest").status_code == 200


def test_token_required_when_env_set(tmp_path, monkeypatch):
    monkeypatch.setattr(jobs_mod, "parse_intent", fake_intent)
    monkeypatch.setattr(jobs_mod, "scan_once", fake_slots)
    cfg_file = tmp_path / "doctolib.yaml"
    cfg_file.write_text(CONFIG, encoding="utf-8")
    monkeypatch.setenv("DOCTOLIB_WEB_TOKEN", "gizli")
    with TestClient(create_app(str(cfg_file))) as c:
        assert c.get("/api/config").status_code == 401
        assert c.get("/api/config", headers={"X-Token": "yanlis"}).status_code == 401
        assert c.get("/api/config", headers={"X-Token": "gizli"}).status_code == 200
        # Sorgu parametresi de kabul edilir (paylaşılan bağlantı için).
        assert c.get("/api/config?token=gizli").status_code == 200
