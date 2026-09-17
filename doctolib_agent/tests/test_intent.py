from types import SimpleNamespace

from doctolib_agent.config import AgentConfig
from doctolib_agent.intent import parse_intent
from doctolib_agent.models import SearchIntent


class FakeAnthropic:
    """messages.parse çağrısını yakalayan sahte istemci."""

    def __init__(self, parsed: SearchIntent, stop_reason: str = "end_turn"):
        self.captured: dict = {}
        outer = self

        class Messages:
            def parse(self, **kwargs):
                outer.captured = kwargs
                return SimpleNamespace(
                    parsed_output=parsed.model_copy(deep=True),
                    stop_reason=stop_reason,
                    stop_details=SimpleNamespace(explanation="reddedildi"),
                )

        self.messages = Messages()


def model_output(**kw) -> SearchIntent:
    base = dict(
        specialty_slugs=["hals-nasen-ohren-arzt"],
        specialty_label="HNO",
        reason_summary="boğaz ağrısı",
        location="paris",          # modelin yanlış tahmini
        location_label="Paris",
        country="fr",              # modelin yanlış tahmini
    )
    base.update(kw)
    return SearchIntent(**base)


def test_location_is_forced_to_configured_city():
    cfg = AgentConfig()  # varsayılan: de / berlin
    client = FakeAnthropic(model_output())
    intent = parse_intent("Paris'te KBB lazım", cfg, client=client)

    # Kullanıcı başka şehir yazsa da yapılandırma kazanır.
    assert intent.location == "berlin"
    assert intent.location_label == "Berlin"
    assert intent.country == "de"


def test_prompt_tells_model_the_location_is_fixed():
    cfg = AgentConfig()
    client = FakeAnthropic(model_output())
    parse_intent("diş ağrısı", cfg, client=client)

    prompt = client.captured["messages"][0]["content"]
    assert "Konum SABİT: 'berlin'" in prompt
    assert "doctolib.de" in prompt
    # Alman uzmanlık slug'ları verilmeli, Fransız olanlar değil.
    assert "zahnarzt" in prompt
    assert "dentiste" not in prompt


def test_empty_location_lets_model_decide():
    cfg = AgentConfig.from_dict({"location": ""})
    client = FakeAnthropic(model_output(location="hamburg", location_label="Hamburg"))
    intent = parse_intent("Hamburg'da diş hekimi", cfg, client=client)

    assert intent.location == "hamburg"
    assert "Konum SABİT" not in client.captured["messages"][0]["content"]


def test_configured_model_and_adaptive_thinking_are_used():
    cfg = AgentConfig()
    client = FakeAnthropic(model_output())
    parse_intent("diş ağrısı", cfg, client=client)

    assert client.captured["model"] == "claude-opus-5"
    assert client.captured["thinking"] == {"type": "adaptive"}
    assert client.captured["output_format"] is SearchIntent


def test_refusal_raises():
    cfg = AgentConfig()
    client = FakeAnthropic(model_output(), stop_reason="refusal")
    try:
        parse_intent("...", cfg, client=client)
    except RuntimeError as exc:
        assert "reddetti" in str(exc)
    else:
        raise AssertionError("reddedilen istek hata vermeliydi")


def test_insurance_sector_falls_back_to_profile():
    cfg = AgentConfig.from_dict({"profile": {"insurance_sector": "public"}})
    client = FakeAnthropic(model_output())
    assert parse_intent("diş ağrısı", cfg, client=client).insurance_sector == "public"
