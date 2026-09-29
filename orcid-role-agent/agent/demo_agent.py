#!/usr/bin/env python3
"""
SMALLEST WORKING AGENT - for learning.

The point: there is no product called "agent". An agent is a loop that
calls a model and hands it tools. That is all it is.

To run:
    pip install -r requirements.txt
    gcloud auth application-default login
    export GCP_PROJECT=researcher-360-prod-e7fd74be
    export GCP_LOCATION=europe-west1          # Vertex baglantinla ayni bolge
    python demo_agent.py "which roles exist and how many HCPs?"

NOTE: this does not run the real project. It demonstrates the mechanic
only. The real agent gets written once the dbt pipeline is proven.
"""

import os
import sys

from google import genai
from google.genai import types

PROJECT = os.environ.get("GCP_PROJECT", "researcher-360-prod-e7fd74be")
LOCATION = os.environ.get("GCP_LOCATION", "europe-west1")
MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")


# ───────────────────────────────────────────────────────────────────────────
# TOOLS
#
# These are plain Python functions. Nothing special about them.
# All the model sees is: the name, the parameters, and the DOCSTRING.
# The docstring is where the model learns WHEN to reach for this tool.
# Good docstrings make good agents - half the prompt engineering is here.
# ───────────────────────────────────────────────────────────────────────────

def list_roles() -> dict:
    """Return every role defined in the system, with its label.

    Use this to discover which roles can be asked about, or to check
    whether a role name the user gave is valid.
    """
    # Real version: read from dbt_project.yml or BigQuery
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
    """Return the audience size for a role.

    Args:
        role_key: one of the keys returned by list_roles(). If unsure,
                  call list_roles() first rather than guessing.
        country_code: ISO country code (e.g. 'DE'). Empty means worldwide.

    Returns:
        identified  - people matched
        marketable  - people with marketing consent (the number that matters)
    """
    # Real version: query marts.fct_role_audience_summary in BigQuery
    fake = {"hcp": (47231, 10580), "librarian": (8140, 2210),
            "researcher": (112400, 24900), "pharmacist": (6320, 1410),
            "faculty_head": (9870, 2050)}
    if role_key not in fake:
        return {"error": f"unknown role: {role_key}. call list_roles() first."}
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
# THE AGENT
#
# What makes this an agent: the model decides ITSELF which tool to call
# and when. We never write the sequence.
#
# Asked "how many HCPs?", the model works out on its own to:
#   1. call list_roles()      -> check that 'hcp' is valid
#   2. call count_audience()  -> get the numbers
#   3. write the answer
# We did not code that order. The model built it. That is the difference.
# ───────────────────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """You build role-based audiences from ORCID data.

Rules:
- If unsure about a role name, call list_roles() FIRST. Never guess.
- When giving numbers, ALWAYS give both 'identified' and 'marketable'.
  'marketable' is the one the marketing team acts on - lead with it.
- Never invent figures. Verify with a tool.
- Keep answers short.
"""


def main() -> None:
    question = " ".join(sys.argv[1:]) or "which roles exist?"

    # vertexai=True -> routes through Vertex AI using application-default
    # credentials. No separate API key. The SAME access the embedding model
    # already uses - and NOT the BigQuery connection, which is a different
    # path (see dbt/setup/03_test_access.sql TEST 4).
    client = genai.Client(vertexai=True, project=PROJECT, location=LOCATION)

    print(f"\n[question] {question}\n")

    # The SDK turns the loop for you: model requests a tool -> SDK runs the
    # function -> result goes back to the model -> model continues. You do
    # not have to write the while loop yourself.
    response = client.models.generate_content(
        model=MODEL,
        contents=question,
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM_PROMPT,
            tools=TOOLS,
            temperature=0.0,
        ),
    )

    print(f"[answer]\n{response.text}\n")

    # See which tools the model reached for - the best way to understand it
    history = getattr(response, "automatic_function_calling_history", None)
    if history:
        print("[the model's own decisions]")
        for item in history:
            for part in getattr(item, "parts", []) or []:
                if getattr(part, "function_call", None):
                    fc = part.function_call
                    print(f"  -> {fc.name}({dict(fc.args)})")


if __name__ == "__main__":
    main()
