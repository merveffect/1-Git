from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models.monitor import MonitorConfig
from services.scheduler import schedule_monitor
import json

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
