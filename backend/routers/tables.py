from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models.monitor import MonitoredTable, MonitorConfig
from models.schemas import MonitoredTableCreate, MonitoredTableResponse
from services.bigquery_client import bq_client
from services.scheduler import schedule_monitor
from datetime import datetime
import json

router = APIRouter(prefix="/api/tables", tags=["tables"])

@router.get("/", response_model=list[MonitoredTableResponse])
def list_tables(db: Session = Depends(get_db)):
    return db.query(MonitoredTable).filter(MonitoredTable.is_active == True).all()

@router.get("/with-status")
def list_tables_with_status(db: Session = Depends(get_db)):
    """Returns tables with their actual current health status derived from last monitor runs."""
    from models.monitor import MonitorRun
    tables = db.query(MonitoredTable).filter(MonitoredTable.is_active == True).all()
    result = []
    status_priority = {"fail": 3, "error": 2, "warning": 1, "pass": 0}
    for table in tables:
        configs = db.query(MonitorConfig).filter(
            MonitorConfig.table_id == table.id,
            MonitorConfig.is_enabled == True
        ).all()
        worst = "no_data"
        last_checked = None
        for cfg in configs:
            run = db.query(MonitorRun).filter(
                MonitorRun.monitor_config_id == cfg.id,
                MonitorRun.completed_at != None
            ).order_by(MonitorRun.completed_at.desc()).first()
            if run:
                if worst == "no_data" or status_priority.get(run.status, -1) > status_priority.get(worst, -1):
                    worst = run.status
                if last_checked is None or run.completed_at > last_checked:
                    last_checked = run.completed_at
        result.append({
            "id": table.id,
            "project_id": table.project_id,
            "dataset_id": table.dataset_id,
            "table_id": table.table_id,
            "display_name": table.display_name,
            "status": worst,
            "last_checked": last_checked.isoformat() if last_checked else None,
        })
    return result

@router.post("/", response_model=MonitoredTableResponse)
def add_table(body: MonitoredTableCreate, db: Session = Depends(get_db)):
    table = MonitoredTable(
        project_id=body.project_id,
        dataset_id=body.dataset_id,
        table_id=body.table_id,
        display_name=body.display_name or f"{body.dataset_id}.{body.table_id}",
        is_active=True,
        created_at=datetime.utcnow(),
    )
    db.add(table)
    db.commit()
    db.refresh(table)

    # Auto-create default monitor configs for all 5 types
    default_monitors = [
        {"type": "freshness", "config": {"max_lag_hours": 24}},
        {"type": "volume", "config": {"z_score_threshold": 3.0}},
        {"type": "null_rate", "config": {"max_null_pct": 5.0}},
        {"type": "duplicate", "config": {"key_columns": [], "max_duplicate_pct": 1.0}},
        {"type": "schema_drift", "config": {}},
    ]
    for m in default_monitors:
        cfg = MonitorConfig(
            table_id=table.id,
            monitor_type=m["type"],
            is_enabled=True,
            config_json=json.dumps(m["config"]),
            schedule_minutes=60,
        )
        db.add(cfg)
    db.commit()

    # Schedule all monitors
    configs = db.query(MonitorConfig).filter(MonitorConfig.table_id == table.id).all()
    for cfg in configs:
        schedule_monitor(cfg.id, cfg.schedule_minutes)

    return table

@router.delete("/{table_id}")
def remove_table(table_id: int, db: Session = Depends(get_db)):
    table = db.query(MonitoredTable).filter(MonitoredTable.id == table_id).first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found")
    table.is_active = False
    db.commit()
    return {"ok": True}

@router.get("/{table_id}/monitors", response_model=list[dict])
def get_table_monitors(table_id: int, db: Session = Depends(get_db)):
    from models.monitor import MonitorRun
    configs = db.query(MonitorConfig).filter(MonitorConfig.table_id == table_id).all()
    result = []
    for cfg in configs:
        last_run = db.query(MonitorRun).filter(
            MonitorRun.monitor_config_id == cfg.id
        ).order_by(MonitorRun.completed_at.desc()).first()
        result.append({
            "config": {
                "id": cfg.id, "monitor_type": cfg.monitor_type,
                "is_enabled": cfg.is_enabled, "config_json": cfg.config_json,
                "schedule_minutes": cfg.schedule_minutes,
            },
            "last_run": {
                "status": last_run.status,
                "completed_at": last_run.completed_at.isoformat() if last_run and last_run.completed_at else None,
                "result_json": last_run.result_json,
            } if last_run else None,
        })
    return result

@router.post("/{table_id}/run-now")
def run_table_now(table_id: int, db: Session = Depends(get_db)):
    from services.scheduler import run_monitor
    configs = db.query(MonitorConfig).filter(
        MonitorConfig.table_id == table_id,
        MonitorConfig.is_enabled == True
    ).all()
    for cfg in configs:
        run_monitor(cfg.id)
    return {"ok": True, "monitors_run": len(configs)}

@router.get("/{table_id}/update-history")
def get_update_history(table_id: int, limit: int = 60, db: Session = Depends(get_db)):
    """Returns BQ metadata update events for timeline visualization."""
    from models.monitor import TableUpdateHistory
    rows = db.query(TableUpdateHistory).filter(
        TableUpdateHistory.table_id == table_id
    ).order_by(TableUpdateHistory.detected_at.asc()).limit(limit).all()
    return [
        {
            "id": r.id,
            "last_modified_time": r.last_modified_time.isoformat() if r.last_modified_time else None,
            "row_count": r.row_count,
            "detected_at": r.detected_at.isoformat() if r.detected_at else None,
        }
        for r in rows
    ]


@router.get("/bq/datasets")
def list_bq_datasets(project: str):
    try:
        datasets = bq_client.list_datasets(project)
        return {"datasets": datasets}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/bq/tables")
def list_bq_tables(project: str, dataset: str):
    try:
        tables = bq_client.list_tables(project, dataset)
        return {"tables": tables}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
