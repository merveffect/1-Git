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


def _read_env_paths() -> list[str]:
    """Read current DBT_PROJECT_PATHS list from settings + .env."""
    raw = settings.dbt_project_paths or ""
    paths = [p.strip() for p in raw.split(",") if p.strip()]
    # Also include legacy single path if present
    if settings.dbt_project_path and settings.dbt_project_path.strip() not in paths:
        paths.append(settings.dbt_project_path.strip())
    return paths


def _write_env_paths(paths: list[str]):
    """Persist the paths list to .env as DBT_PROJECT_PATHS (and clear legacy key)."""
    env_path = ".env"
    lines = []
    try:
        with open(env_path) as f:
            lines = f.readlines()
    except FileNotFoundError:
        pass

    # Remove legacy and new keys
    lines = [l for l in lines if not l.startswith("DBT_PROJECT_PATH=") and not l.startswith("DBT_PROJECT_PATHS=")]

    value = ",".join(paths)
    if value:
        lines.append(f"DBT_PROJECT_PATHS={value}\n")

    with open(env_path, "w") as f:
        f.writelines(lines)

    # Update in-memory settings
    settings.dbt_project_paths = value or None
    settings.dbt_project_path = None  # clear legacy


@router.get("/status")
def dbt_status():
    projects = dbt_reader.get_all_projects_info()
    configured = any(p["configured"] for p in projects)
    # Legacy fields for backward compat
    first = next((p for p in projects if p["configured"]), None)
    return {
        "configured": configured,
        "project_path": first["path"] if first else None,
        "project_name": first["project_name"] if first else None,
        "model_count": sum(p["model_count"] for p in projects),
        "projects": projects,
    }


@router.post("/settings")
def add_dbt_path(body: dict):
    """Add a dbt project path to the list."""
    path = body.get("dbt_project_path", "").strip()
    if not path:
        raise HTTPException(status_code=400, detail="dbt_project_path is required")

    paths = _read_env_paths()
    if path not in paths:
        paths.append(path)
    _write_env_paths(paths)
    return {"ok": True, "paths": paths}


@router.post("/settings/remove")
def remove_dbt_path(body: dict):
    """Remove a specific dbt project path from the list."""
    path = body.get("dbt_project_path", "").strip()
    if not path:
        raise HTTPException(status_code=400, detail="dbt_project_path is required")

    paths = _read_env_paths()
    paths = [p for p in paths if p != path]
    _write_env_paths(paths)
    return {"ok": True, "paths": paths}


@router.post("/settings/clear")
def clear_all_dbt_paths():
    """Remove all configured dbt project paths."""
    _write_env_paths([])
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


@router.get("/models/{model_name}/test-history")
def model_test_history(model_name: str, limit: int = 50, db: Session = Depends(get_db)):
    """
    Returns per-test historical pass/fail for a model.
    Combines manifest test definitions with stored DbtRunSnapshot history.
    """
    if not dbt_reader.is_configured():
        return {"configured": False, "tests": []}

    tests = dbt_reader.get_model_tests_with_meta(model_name)
    if not tests:
        return {"configured": True, "tests": []}

    from models.monitor import DbtRunSnapshot
    snapshots = (
        db.query(DbtRunSnapshot)
        .order_by(DbtRunSnapshot.run_at.asc())
        .limit(limit)
        .all()
    )

    # Build per-snapshot result maps: unique_id -> status
    snapshot_maps = []
    for s in snapshots:
        results = json.loads(s.results_json or "[]")
        snapshot_maps.append({
            "run_at": s.run_at.isoformat(),
            "result_map": {r["unique_id"]: r.get("status") for r in results},
        })

    run_results = dbt_reader.get_last_run_results()
    enriched = []
    for t in tests:
        history = [
            {"run_at": snap["run_at"], "status": snap["result_map"][t["unique_id"]]}
            for snap in snapshot_maps
            if t["unique_id"] in snap["result_map"]
        ]
        latest = run_results.get(t["unique_id"], {})
        enriched.append({
            **t,
            "latest_status": latest.get("status", "not_run"),
            "failures": latest.get("failures"),
            "history": history,
        })

    return {"configured": True, "tests": enriched}


@router.post("/import")
def import_dbt_models(body: dict = {}, db: Session = Depends(get_db)):
    """
    Import dbt models as MonitoredTables.
    Optional body: {"project_path": "/path/..."} to import from a specific project only.
    Omit body (or project_path) to import from all configured projects.
    """
    if not dbt_reader.is_configured():
        raise HTTPException(status_code=400, detail="No dbt projects configured")

    filter_path = (body or {}).get("project_path")
    all_models = dbt_reader.get_models()
    models = [m for m in all_models if not filter_path or m.get("project_root") == filter_path]
    if not models and filter_path:
        raise HTTPException(status_code=404, detail=f"No models found for project: {filter_path}")
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
