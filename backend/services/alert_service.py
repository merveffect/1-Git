from sqlalchemy.orm import Session
from models.monitor import Alert

def acknowledge_alert(db: Session, alert_id: int) -> bool:
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if not alert:
        return False
    alert.is_acknowledged = True
    db.commit()
    return True

def get_unacknowledged_count(db: Session) -> int:
    return db.query(Alert).filter(Alert.is_acknowledged == False).count()
