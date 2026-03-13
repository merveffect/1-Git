from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models.monitor import Alert, MonitoredTable
from services.alert_service import acknowledge_alert, get_unacknowledged_count

router = APIRouter(prefix="/api/alerts", tags=["alerts"])

@router.get("/")
def list_alerts(limit: int = 50, acknowledged: bool = None, db: Session = Depends(get_db)):
    q = db.query(Alert)
    if acknowledged is not None:
        q = q.filter(Alert.is_acknowledged == acknowledged)
    alerts = q.order_by(Alert.created_at.desc()).limit(limit).all()
    result = []
    for a in alerts:
        table = db.query(MonitoredTable).filter(MonitoredTable.id == a.table_id).first()
        result.append({
            "id": a.id, "monitor_type": a.monitor_type, "severity": a.severity,
            "message": a.message,
            "created_at": a.created_at.isoformat() if a.created_at else None,
            "is_acknowledged": a.is_acknowledged,
            "table_name": f"{table.dataset_id}.{table.table_id}" if table else None,
        })
    return result

@router.post("/{alert_id}/acknowledge")
def ack_alert(alert_id: int, db: Session = Depends(get_db)):
    ok = acknowledge_alert(db, alert_id)
    return {"ok": ok}
