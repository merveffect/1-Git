#!/usr/bin/env python3
"""
dbt Core -> Microsoft Teams alert script (failure-only, includes failed models/tests)
Save as: dbt_alert_enhanced.py
"""

import subprocess
import requests
import sys
import json
import os
import time
from datetime import datetime
from typing import List, Dict

# -------------------- << MANUAL CHANGES / VERIFY >> --------------------
# 1) Provide your Teams webhook URL via environment variable (recommended)
#    e.g., export TEAMS_WEBHOOK_URL="https://outlook.office.com/webhook/..."
TEAMS_WEBHOOK_URL = os.getenv("TEAMS_WEBHOOK_URL")
# If you DO want to hardcode (not recommended), replace None with the URL:
# TEAMS_WEBHOOK_URL = "https://outlook.office.com/webhook/xxxxx/IncomingWebhook/yyy/zzz"  # << CHANGE THIS IF NOT USING ENV VAR >>

# 2) Environment label to show in Teams (staging / production / dev)
ENVIRONMENT = os.getenv("ENVIRONMENT", "production")  # << CHANGE if you want default different >>

# 3) Path to dbt run_results.json (adjust if your target path differs)
RUN_RESULTS_PATH = os.getenv("DBT_RUN_RESULTS_PATH", "target/run_results.json")  # << CHANGE if needed >>
# --------------------------------------------------------------------

if not TEAMS_WEBHOOK_URL:
    raise SystemExit("ERROR: TEAMS_WEBHOOK_URL not set. Export as env var or set in the script.")

def run_dbt_command(cmd: List[str]) -> subprocess.CompletedProcess:
    """Run dbt command and return CompletedProcess."""
    return subprocess.run(cmd, capture_output=True, text=True)

def parse_run_results(path: str) -> Dict:
    """Load run_results.json if it exists; return parsed dict or {}."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {}
    except Exception as e:
        print("⚠️ Could not parse run_results.json:", e)
        return {}

def extract_failures(run_results: Dict) -> Dict[str, List[str]]:
    """
    From run_results JSON, return dict with keys 'models' and 'tests' listing failed nodes.
    """
    failed_models = []
    failed_tests = []
    results = run_results.get("results", []) if isinstance(run_results, dict) else []
    for r in results:
        status = r.get("status")
        unique_id = r.get("unique_id") or r.get("node") or r.get("node_name") or r.get("name", "unknown")
        resource_type = r.get("resource_type") or r.get("node", {}).get("resource_type", "model")
        if status and status.lower() not in ("success", "skipped"):
            # Collect models and tests separately if possible
            if resource_type.lower() in ("test", "singular_test", "schema_test"):
                failed_tests.append(f"{r.get('unique_id','?')} — {r.get('status')}")
            else:
                # model or other node
                failed_models.append(f"{r.get('unique_id','?')} — {r.get('status')}")
    return {"models": failed_models, "tests": failed_tests}

def compose_message(status: str, command: List[str], duration: float, failures: Dict, raw_logs: str) -> Dict:
    """Create a MessageCard payload for Teams with failure details."""
    color = "FF0000" if status != "SUCCESS" else "00FF00"
    timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    facts = [
        {"name": "Status", "value": status},
        {"name": "Environment", "value": ENVIRONMENT},
        {"name": "Command", "value": " ".join(command)},
        {"name": "Duration", "value": f"{duration:.1f} sec"},
        {"name": "Timestamp (UTC)", "value": timestamp},
    ]

    # Build a concise failure summary
    failure_lines = []
    if failures.get("models"):
        failure_lines.append("**Failed models:**")
        failure_lines += [f"- {m}" for m in failures["models"]]
    if failures.get("tests"):
        failure_lines.append("**Failed tests:**")
        failure_lines += [f"- {t}" for t in failures["tests"]]

    body_text = "\n".join(failure_lines) if failure_lines else "No structured failures found in run_results.json."

    # include truncated raw logs for quick debugging (last 1000 chars)
    log_snippet = raw_logs[-1000:] if raw_logs else ""

    message = {
        "@type": "MessageCard",
        "@context": "https://schema.org/extensions",
        "themeColor": color,
        "summary": f"dbt Core Run {status}",
        "title": f"🚨 dbt Core Run {status}",
        "sections": [
            {
                "activityTitle": f"**Environment:** {ENVIRONMENT}",
                "facts": facts,
                "text": f"{body_text}\n\n---\n```\n{log_snippet}\n```"
            }
        ]
    }
    return message

def send_teams_message(payload: Dict) -> None:
    """POST payload to Teams webhook."""
    headers = {"Content-Type": "application/json"}
    try:
        r = requests.post(TEAMS_WEBHOOK_URL, headers=headers, json=payload, timeout=10)
        if r.status_code != 200:
            print("⚠️ Failed to send message to Teams:", r.status_code, r.text)
    except Exception as e:
        print("⚠️ Exception when sending to Teams:", e)

def main():
    dbt_cmd = sys.argv[1:] or ["dbt", "run"]  # << CHANGE default if you prefer another default command >>
    start = time.time()
    print(f"▶️ Running: {' '.join(dbt_cmd)}")
    try:
        result = run_dbt_command(dbt_cmd)
    except Exception as e:
        duration = time.time() - start
        print("💥 Exception running dbt:", e)
        # send alert about the runner error
        payload = compose_message("ERROR", dbt_cmd, duration, {"models": [], "tests": []}, str(e))
        send_teams_message(payload)
        sys.exit(1)

    duration = time.time() - start

    # If dbt failed (non-zero), parse run_results and send alert
    if result.returncode != 0:
        print("❌ dbt failed; preparing Teams alert...")
        run_results = parse_run_results(RUN_RESULTS_PATH)
        failures = extract_failures(run_results)
        # prefer stderr for errors, fallback to stdout
        raw_logs = result.stderr or result.stdout or ""
        payload = compose_message("FAILED", dbt_cmd, duration, failures, raw_logs)
        send_teams_message(payload)
    else:
        print("✅ dbt succeeded; no Teams alert sent.")
    sys.exit(result.returncode)

if __name__ == "__main__":
    main()
