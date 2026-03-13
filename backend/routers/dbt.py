"""
dbt-specific API endpoints:
  GET  /api/dbt/status          - is dbt configured + project name
  GET  /api/dbt/models          - all models from manifest.json
  GET  /api/dbt/models/{name}/lineage   - upstream/downstream for a model
  GET  /api/dbt/models/{name}/tests     - test results for a model
  POST /api/dbt/import          - import all dbt models as monitored tables
  POST /api/dbt/settings        - update dbt_project_path at runtime
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from services import dbt_reader
from config import settings
from models.monitor import MonitoredTable, MonitorConfig
from datetime import datetime
import json

router = APIRouter(prefix="/api/dbt", tags=["dbt"])


@router.get("/status")
def dbt_status():
    configured = dbt_reader.is_configured()
    project_name = dbt_reader.get_project_name() if configured else None
    models = dbt_reader.get_models() if configured else []
    return {
        "configured": configured,
        "project_path": settings.dbt_project_path,
        "project_name": project_name,
        "model_count": len(models),
    }


@router.post("/settings")
def update_dbt_path(body: dict):
    """
    Update the dbt project path at runtime (persisted to .env not yet —
    restart required for full effect, but reader picks it up immediately).
    """
    path = body.get("dbt_project_path", "").strip()
    if not path:
        raise HTTPException(status_code=400, detail="dbt_project_path is required")
    settings.dbt_project_path = path

    # Write to .env so it persists across restarts
    env_path = ".env"
    lines = []
    found = False
    try:
        with open(env_path) as f:
            lines = f.readlines()
    except FileNotFoundError:
        pass

    new_line = f"DBT_PROJECT_PATH={path}\n"
    for i, line in enumerate(lines):
        if line.startswith("DBT_PROJECT_PATH="):
            lines[i] = new_line
            found = True
            break
    if not found:
        lines.append(new_line)

    with open(env_path, "w") as f:
        f.writelines(lines)

    return {"ok": True, "project_path": path}


@router.post("/settings/clear")
def clear_dbt_path():
    """Remove the dbt project path from settings and .env."""
    settings.dbt_project_path = None

    env_path = ".env"
    try:
        with open(env_path) as f:
            lines = f.readlines()
        lines = [l for l in lines if not l.startswith("DBT_PROJECT_PATH=")]
        with open(env_path, "w") as f:
            f.writelines(lines)
    except FileNotFoundError:
        pass

    return {"ok": True}


@router.get("/models")
def list_models():
    if not dbt_reader.is_configured():
        return {"models": [], "configured": False}
    models = dbt_reader.get_models()
    run_results = dbt_reader.get_last_run_results()
    enriched = []
    for m in models:
        result = run_results.get(m["unique_id"], {})
        enriched.append({
            **m,
            "last_run_status": result.get("status"),
            "last_run_time": result.get("execution_time"),
        })
    return {"models": enriched, "configured": True}


@router.get("/models/{model_name}/lineage")
def model_lineage(model_name: str):
    models = dbt_reader.get_models()
    model = next((m for m in models if m["name"] == model_name), None)
    if not model:
        raise HTTPException(status_code=404, detail=f"Model '{model_name}' not found in manifest")
    return dbt_reader.get_model_lineage(model["unique_id"])


@router.get("/models/{model_name}/tests")
def model_tests(model_name: str):
    return {"tests": dbt_reader.get_model_test_results(model_name)}


@router.post("/import")
def import_dbt_models(db: Session = Depends(get_db)):
    """
    Import all dbt models from manifest.json as MonitoredTables.
    Skips models already added. Auto-creates all 6 monitor types including dbt_tests.
    """
    if not dbt_reader.is_configured():
        raise HTTPException(status_code=400, detail="DBT_PROJECT_PATH not set")

    models = dbt_reader.get_models()
    if not models:
        raise HTTPException(status_code=404, detail="No models found in manifest.json")

    added = []
    skipped = []

    for m in models:
        project_id = m["database"]
        dataset_id = m["schema"]
        table_id = m["name"]

        if not project_id or not dataset_id or not table_id:
            skipped.append(m["name"])
            continue

        existing = db.query(MonitoredTable).filter(
            MonitoredTable.project_id == project_id,
            MonitoredTable.dataset_id == dataset_id,
            MonitoredTable.table_id == table_id,
        ).first()

        if existing:
            skipped.append(m["name"])
            continue

        table = MonitoredTable(
            project_id=project_id,
            dataset_id=dataset_id,
            table_id=table_id,
            display_name=m.get("description") or f"{dataset_id}.{table_id}",
            is_active=True,
            created_at=datetime.utcnow(),
        )
        db.add(table)
        db.flush()

        default_monitors = [
            {"type": "freshness",   "config": {"max_lag_hours": 24}},
            {"type": "volume",      "config": {"z_score_threshold": 3.0}},
            {"type": "null_rate",   "config": {"max_null_pct": 5.0}},
            {"type": "duplicate",   "config": {"key_columns": [], "max_duplicate_pct": 1.0}},
            {"type": "schema_drift","config": {}},
            {"type": "dbt_tests",   "config": {}},
        ]
        for mon in default_monitors:
            cfg = MonitorConfig(
                table_id=table.id,
                monitor_type=mon["type"],
                is_enabled=True,
                config_json=json.dumps(mon["config"]),
                schedule_minutes=60,
            )
            db.add(cfg)

        added.append(m["name"])

    db.commit()

    # Schedule all newly added monitors
    from services.scheduler import schedule_monitor
    for name in added:
        tbl = db.query(MonitoredTable).filter(MonitoredTable.table_id == name).first()
        if tbl:
            for cfg in tbl.monitor_configs:
                schedule_monitor(cfg.id, cfg.schedule_minutes)

    return {"imported": len(added), "skipped": len(skipped), "models": added}


# ---------------------------------------------------------------------------
# Run history (file watcher snapshots)
# ---------------------------------------------------------------------------

@router.get("/history")
def get_dbt_run_history(limit: int = 100, db: Session = Depends(get_db)):
    """
    Returns all dbt run snapshots ordered newest first.
    Each entry represents one dbt run detected by the file watcher.
    """
    from models.monitor import DbtRunSnapshot
    rows = (
        db.query(DbtRunSnapshot)
        .order_by(DbtRunSnapshot.run_at.desc())
        .limit(limit)
        .all()
    )
    return [
        {
            "id": r.id,
            "run_at": r.run_at.isoformat() if r.run_at else None,
            "detected_at": r.detected_at.isoformat() if r.detected_at else None,
            "elapsed_time": r.elapsed_time,
            "models": {
                "pass":  r.models_pass,
                "fail":  r.models_fail,
                "error": r.models_error,
                "skip":  r.models_skip,
            },
            "tests": {
                "pass":  r.tests_pass,
                "fail":  r.tests_fail,
                "error": r.tests_error,
                "warn":  r.tests_warn,
            },
        }
        for r in rows
    ]


@router.get("/history/{snapshot_id}/results")
def get_snapshot_results(snapshot_id: int, db: Session = Depends(get_db)):
    """Full per-node results for a specific dbt run snapshot (for drill-down)."""
    from models.monitor import DbtRunSnapshot
    row = db.query(DbtRunSnapshot).filter(DbtRunSnapshot.id == snapshot_id).first()
    if not row:
        raise HTTPException(status_code=404, detail="Snapshot not found")
    results = json.loads(row.results_json or "[]")
    return {"run_at": row.run_at.isoformat(), "results": results}
