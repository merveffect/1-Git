
from doctolib_agent.config import AgentConfig


def test_rate_limits_have_hard_floors():
    cfg = AgentConfig.from_dict({"scan": {"poll_interval_seconds": 5, "min_request_interval": 0.01}})
    assert cfg.scan.poll_interval_seconds == 300
    assert cfg.scan.min_request_interval == 1.0


def test_booking_count_is_capped():
    cfg = AgentConfig.from_dict({"booking": {"max_bookings_per_run": 50}})
    assert cfg.booking.max_bookings_per_run == 3


def test_horizon_clamped():
    assert AgentConfig.from_dict({"scan": {"horizon_days": 500}}).scan.horizon_days == 90
    assert AgentConfig.from_dict({"scan": {"horizon_days": 0}}).scan.horizon_days == 1


def test_base_url_follows_country():
    assert AgentConfig.from_dict({"country": "de"}).base_url == "https://www.doctolib.de"


def test_default_mode_is_assist_not_auto():
    # Varsayılan tam otomatik olmamalı.
    assert AgentConfig().booking.mode == "assist"


def test_profile_missing_fields():
    cfg = AgentConfig.from_dict({"profile": {"first_name": "Merve", "email": "a@b.c"}})
    assert set(cfg.profile.missing_fields()) == {"last_name", "birthdate", "phone"}
