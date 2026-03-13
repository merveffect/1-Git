from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger
from sqlalchemy.orm import Session
from database import SessionLocal
from models.monitor import MonitorConfig, MonitoredTable, MonitorRun, Alert, SchemaSnapshot
from monitors.freshness import FreshnessMonitor
from monitors.volume import VolumeMonitor
from monitors.null_rate import NullRateMonitor
from monitors.duplicate import DuplicateMonitor
from monitors.schema_drift import SchemaDriftMonitor
from monitors.dbt_tests import DbtTestsMonitor
from monitors.base import CheckStatus
from datetime import datetime
import json
import logging

logger = logging.getLogger(__name__)
scheduler = BackgroundScheduler()

MONITOR_CLASSES = {
    "freshness": FreshnessMonitor,
    "volume": VolumeMonitor,
    "null_rate": NullRateMonitor,
    "duplicate": DuplicateMonitor,
    "schema_drift": SchemaDriftMonitor,
    "dbt_tests": DbtTestsMonitor,
}

def run_monitor(monitor_config_id: int):
    db = SessionLocal()
    try:
        config = db.query(MonitorConfig).filter(MonitorConfig.id == monitor_config_id).first()
        if not config or not config.is_enabled:
            return

        table = db.query(MonitoredTable).filter(MonitoredTable.id == config.table_id).first()
        if not table or not table.is_active:
            return

        monitor_cfg = json.loads(config.config_json or "{}")
        run = MonitorRun(monitor_config_id=config.id, started_at=datetime.utcnow(), status="running")
        db.add(run)
        db.commit()

        try:
            kwargs = {}
            if config.monitor_type == "volume":
                # Get last 30 run values for Z-score
                past_runs = db.query(MonitorRun).filter(
                    MonitorRun.monitor_config_id == config.id,
                    MonitorRun.status == "pass"
                ).order_by(MonitorRun.completed_at.desc()).limit(30).all()
                kwargs["historical_counts"] = [
                    json.loads(r.result_json or "{}").get("value", 0) for r in past_runs if r.result_json
                ]
            elif config.monitor_type == "schema_drift":
                snapshot = db.query(SchemaSnapshot).filter(
                    SchemaSnapshot.table_id == table.id,
                    SchemaSnapshot.is_baseline == True
                ).order_by(SchemaSnapshot.created_at.desc()).first()
                kwargs["baseline_schema"] = json.loads(snapshot.snapshot_json) if snapshot else None

            MonitorClass = MONITOR_CLASSES[config.monitor_type]
            monitor = MonitorClass(table.project_id, table.dataset_id, table.table_id, monitor_cfg, **kwargs)
            result = monitor.run()

            run.status = result.status.value
            run.result_json = json.dumps({
                "message": result.message,
                "value": result.value,
                "threshold": result.threshold,
                "details": result.details,
            })
            run.completed_at = datetime.utcnow()

            # Save schema baseline on first run
            if config.monitor_type == "schema_drift" and result.details and result.details.get("is_first_run"):
                snapshot = SchemaSnapshot(
                    table_id=table.id,
                    snapshot_json=json.dumps(result.details["schema"]),
                    is_baseline=True,
                    created_at=datetime.utcnow()
                )
                db.add(snapshot)

            # Create alert if not passing
            if result.status in (CheckStatus.FAIL, CheckStatus.WARNING):
                alert = Alert(
                    monitor_run_id=run.id,
                    table_id=table.id,
                    monitor_type=config.monitor_type,
                    severity="critical" if result.status == CheckStatus.FAIL else "warning",
                    message=result.message,
                    created_at=datetime.utcnow(),
                    is_acknowledged=False,
                )
                db.add(alert)

            db.commit()
            logger.info(f"Monitor {config.monitor_type} for {table.table_id}: {result.status}")

        except Exception as e:
            run.status = "error"
            run.error_message = str(e)
            run.completed_at = datetime.utcnow()
            db.commit()
            logger.error(f"Monitor run error: {e}")
    finally:
        db.close()

def schedule_monitor(config_id: int, interval_minutes: int):
    job_id = f"monitor_{config_id}"
    if scheduler.get_job(job_id):
        scheduler.remove_job(job_id)
    scheduler.add_job(
        run_monitor,
        trigger=IntervalTrigger(minutes=interval_minutes),
        id=job_id,
        args=[config_id],
        replace_existing=True
    )

def start_scheduler(db: Session):
    configs = db.query(MonitorConfig).filter(MonitorConfig.is_enabled == True).all()
    for config in configs:
        schedule_monitor(config.id, config.schedule_minutes or 60)
    if not scheduler.running:
        scheduler.start()
