from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models.monitor import MonitorRun, MonitorConfig, MonitoredTable

router = APIRouter(prefix="/api/runs", tags=["runs"])

@router.get("/monitor/{config_id}")
def get_runs(config_id: int, limit: int = 30, db: Session = Depends(get_db)):
    runs = db.query(MonitorRun).filter(
        MonitorRun.monitor_config_id == config_id
    ).order_by(MonitorRun.completed_at.desc()).limit(limit).all()
    return [
        {
            "id": r.id, "status": r.status,
            "started_at": r.started_at.isoformat() if r.started_at else None,
            "completed_at": r.completed_at.isoformat() if r.completed_at else None,
            "result_json": r.result_json, "error_message": r.error_message,
        }
        for r in runs
    ]

@router.get("/all")
def get_all_runs(limit: int = 200, db: Session = Depends(get_db)):
    """
    Returns recent runs across ALL tables and monitor types.
    Used by the History page to build the cross-pipeline heatmap.
    Response shape: list of {table_id, table_name, monitor_type, status, completed_at, message}
    """
    runs = (
        db.query(MonitorRun, MonitorConfig, MonitoredTable)
        .join(MonitorConfig, MonitorRun.monitor_config_id == MonitorConfig.id)
        .join(MonitoredTable, MonitorConfig.table_id == MonitoredTable.id)
        .filter(MonitoredTable.is_active == True)
        .filter(MonitorRun.completed_at != None)
        .order_by(MonitorRun.completed_at.desc())
        .limit(limit)
        .all()
    )
    import json
    result = []
    for run, cfg, tbl in runs:
        message = None
        if run.result_json:
            try:
                message = json.loads(run.result_json).get("message")
            except Exception:
                pass
        result.append({
            "run_id": run.id,
            "table_id": tbl.id,
            "table_name": tbl.display_name or f"{tbl.dataset_id}.{tbl.table_id}",
            "dataset_id": tbl.dataset_id,
            "table_id_str": tbl.table_id,
            "monitor_type": cfg.monitor_type,
            "status": run.status,
            "completed_at": run.completed_at.isoformat() if run.completed_at else None,
            "message": message,
        })
    return result

@router.get("/table/{table_id}/all-monitors")
def get_all_monitor_history(table_id: int, limit: int = 20, db: Session = Depends(get_db)):
    """
    Returns run history for every monitor type for a single table.
    Used to render per-monitor sparkline/history charts in TableDetailPage.
    Response shape: {monitor_type: [runs...]}
    """
    import json
    configs = db.query(MonitorConfig).filter(MonitorConfig.table_id == table_id).all()
    result = {}
    for cfg in configs:
        runs = (
            db.query(MonitorRun)
            .filter(MonitorRun.monitor_config_id == cfg.id)
            .filter(MonitorRun.completed_at != None)
            .order_by(MonitorRun.completed_at.asc())
            .limit(limit)
            .all()
        )
        result[cfg.monitor_type] = [
            {
                "status": r.status,
                "completed_at": r.completed_at.isoformat() if r.completed_at else None,
                "value": json.loads(r.result_json).get("value") if r.result_json else None,
                "message": json.loads(r.result_json).get("message") if r.result_json else None,
            }
            for r in runs
        ]
    return result
