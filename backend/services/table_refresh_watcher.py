"""
Polls all active monitored tables every 5 minutes.
When last_modified_time advances, records a TableUpdateHistory row
and triggers all enabled monitors for that table immediately.
"""
import logging
from datetime import datetime
from database import SessionLocal
from models.monitor import MonitoredTable, MonitorConfig, TableUpdateHistory
from services.bigquery_client import bq_client

logger = logging.getLogger(__name__)

# In-memory cache: table_id -> last known last_modified_time (as isoformat string)
_last_seen: dict[int, str] = {}


def _get_last_from_db(table_id: int):
    db = SessionLocal()
    try:
        row = db.query(TableUpdateHistory).filter(
            TableUpdateHistory.table_id == table_id
        ).order_by(TableUpdateHistory.detected_at.desc()).first()
        return row.last_modified_time if row else None
    finally:
        db.close()


def check_all_tables():
    """Called every 5 minutes by APScheduler."""
    db = SessionLocal()
    try:
        tables = db.query(MonitoredTable).filter(MonitoredTable.is_active == True).all()
    finally:
        db.close()

    for table in tables:
        try:
            _check_table(table)
        except Exception as e:
            logger.error(f"table_refresh_watcher: error checking {table.table_id}: {e}")


def _check_table(table: MonitoredTable):
    global _last_seen

    meta = bq_client.get_table_metadata(table.project_id, table.dataset_id, table.table_id)
    if not meta or not meta.get("last_modified_time"):
        return

    lmt = meta["last_modified_time"]
    # normalise to naive UTC
    if hasattr(lmt, "tzinfo") and lmt.tzinfo is not None:
        from datetime import timezone
        lmt = lmt.astimezone(timezone.utc).replace(tzinfo=None)

    # Compare against last known value (memory first, then DB on cold start)
    last_key = _last_seen.get(table.id)
    if last_key is None:
        db_val = _get_last_from_db(table.id)
        last_key = db_val.isoformat() if db_val else None
        _last_seen[table.id] = last_key or ""

    lmt_str = lmt.isoformat()
    if last_key and lmt_str <= last_key:
        return  # no change

    # Table was updated — record it
    _last_seen[table.id] = lmt_str
    db = SessionLocal()
    try:
        history = TableUpdateHistory(
            table_id=table.id,
            last_modified_time=lmt,
            row_count=meta.get("row_count"),
            detected_at=datetime.utcnow(),
        )
        db.add(history)
        db.commit()
        logger.info(f"table_refresh_watcher: {table.dataset_id}.{table.table_id} updated at {lmt}")
    finally:
        db.close()

    # Trigger all enabled monitors for this table
    _trigger_monitors(table.id)


def _trigger_monitors(table_id: int):
    from services.scheduler import run_monitor
    db = SessionLocal()
    try:
        configs = db.query(MonitorConfig).filter(
            MonitorConfig.table_id == table_id,
            MonitorConfig.is_enabled == True,
        ).all()
        config_ids = [c.id for c in configs]
    finally:
        db.close()

    for config_id in config_ids:
        try:
            run_monitor(config_id)
        except Exception as e:
            logger.error(f"table_refresh_watcher: monitor {config_id} error: {e}")


def start_table_refresh_watcher(scheduler):
    scheduler.add_job(
        check_all_tables,
        trigger="interval",
        minutes=5,
        id="table_refresh_watcher",
        replace_existing=True,
    )
    logger.info("table_refresh_watcher: started (polling every 5 minutes)")
