from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models.monitor import MonitorRun, MonitorConfig

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
