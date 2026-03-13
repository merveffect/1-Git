from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models.monitor import MonitorConfig, MonitoredTable
from services.scheduler import schedule_monitor
import json
import re

router = APIRouter(prefix="/api/monitors", tags=["monitors"])

@router.patch("/{config_id}")
def update_monitor_config(config_id: int, body: dict, db: Session = Depends(get_db)):
    cfg = db.query(MonitorConfig).filter(MonitorConfig.id == config_id).first()
    if not cfg:
        raise HTTPException(status_code=404)
    if "is_enabled" in body:
        cfg.is_enabled = body["is_enabled"]
    if "config_json" in body:
        cfg.config_json = json.dumps(body["config_json"]) if isinstance(body["config_json"], dict) else body["config_json"]
    if "schedule_minutes" in body:
        cfg.schedule_minutes = body["schedule_minutes"]
    db.commit()
    schedule_monitor(cfg.id, cfg.schedule_minutes)
    return {"ok": True}


# Patterns that strongly suggest a unique key column
_KEY_PATTERNS = re.compile(
    r"(^id$|_id$|^uuid$|_uuid$|^key$|_key$|^pk$|_pk$|^code$|_code$"
    r"|^identifier$|_identifier$|^ref$|_ref$|^number$|_number$)",
    re.IGNORECASE,
)


@router.get("/{config_id}/suggest-keys")
def suggest_key_columns(config_id: int, db: Session = Depends(get_db)):
    """
    Suggests unique key columns for a duplicate monitor via three sources:
    1. dbt manifest — columns with a `unique` test defined
    2. Column name heuristics — id, *_id, uuid, *_key, etc.
    3. Uniqueness verification — samples the table and confirms near-100% uniqueness
    Returns ranked candidates with a source tag and uniqueness ratio.
    """
    cfg = db.query(MonitorConfig).filter(MonitorConfig.id == config_id).first()
    if not cfg or cfg.monitor_type != "duplicate":
        raise HTTPException(status_code=404, detail="Duplicate monitor config not found")

    table = db.query(MonitoredTable).filter(MonitoredTable.id == cfg.table_id).first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")

    from services.bigquery_client import bq_client
    from services.dbt_reader import is_configured, get_tests

    suggestions: list[dict] = []
    seen: set[str] = set()

    # ── 1. dbt manifest: columns with unique tests ──────────────────────────
    if is_configured():
        tests = get_tests()
        for t in tests:
            uid = t.get("unique_id", "")
            if "unique" in uid.lower() and table.table_id in uid:
                col = t.get("column_name")
                if col and col not in seen:
                    suggestions.append({"column": col, "source": "dbt unique test", "rank": 1})
                    seen.add(col)

    # ── 2. Column name heuristics ────────────────────────────────────────────
    try:
        columns = bq_client.get_table_schema(table.project_id, table.dataset_id, table.table_id)
        all_columns = [c["column_name"] for c in columns]
        for col in all_columns:
            if _KEY_PATTERNS.search(col) and col not in seen:
                suggestions.append({"column": col, "source": "name pattern", "rank": 2})
                seen.add(col)
    except Exception:
        all_columns = []

    # ── 3. Uniqueness verification via TABLESAMPLE ───────────────────────────
    # Check top candidates (from dbt + heuristics) and verify they are actually unique
    candidates_to_verify = [s["column"] for s in suggestions[:10]]
    if candidates_to_verify:
        verified = []
        for col in candidates_to_verify:
            try:
                query = f"""
                SELECT
                  COUNT(*) AS total,
                  COUNT(DISTINCT CAST(`{col}` AS STRING)) AS uniq
                FROM `{table.project_id}.{table.dataset_id}.{table.table_id}`
                TABLESAMPLE SYSTEM (5 PERCENT)
                """
                rows = bq_client.run_query(query)
                if rows and rows[0]["total"] > 0:
                    ratio = rows[0]["uniq"] / rows[0]["total"]
                    # update the suggestion with ratio
                    for s in suggestions:
                        if s["column"] == col:
                            s["uniqueness_ratio"] = round(ratio, 4)
                            s["verified"] = ratio >= 0.95
                            break
                    if ratio >= 0.95:
                        verified.append(col)
            except Exception:
                pass

    # Sort: dbt tests first, then verified heuristics, then unverified
    def sort_key(s: dict):
        return (s["rank"], -(s.get("uniqueness_ratio") or 0))

    suggestions.sort(key=sort_key)

    # Best guess: top verified column or top suggestion
    best_guess = None
    for s in suggestions:
        if s.get("verified"):
            best_guess = [s["column"]]
            break
    if not best_guess and suggestions:
        best_guess = [suggestions[0]["column"]]

    return {
        "suggestions": suggestions,
        "best_guess": best_guess or [],
        "all_columns": all_columns,
    }
