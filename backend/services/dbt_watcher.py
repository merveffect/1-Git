"""
Watches run_results.json for changes.
Every 2 minutes, checks if the file's mtime has advanced since the last
snapshot. If it has, parses the results and stores a DbtRunSnapshot row.

This builds a full history of every dbt run going forward — since dbt Core
itself only keeps the most recent run_results.json.
"""

import json
import logging
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from database import SessionLocal
from models.monitor import DbtRunSnapshot, MonitoredTable
from services.dbt_reader import _target_dir

logger = logging.getLogger(__name__)

# In-memory last-seen mtime (seconds since epoch). Persists as long as the
# backend is running; on restart we re-read from DB to avoid duplicate rows.
_last_mtime: Optional[float] = None


def _run_results_path() -> Optional[Path]:
    target = _target_dir()
    if not target:
        return None
    p = target / "run_results.json"
    return p if p.exists() else None


def _get_last_run_at_from_db() -> Optional[datetime]:
    """Return the run_at of the most recent snapshot in the DB."""
    db = SessionLocal()
    try:
        row = db.query(DbtRunSnapshot).order_by(DbtRunSnapshot.run_at.desc()).first()
        return row.run_at if row else None
    finally:
        db.close()


def _parse_and_store(path: Path) -> bool:
    """
    Parse run_results.json and store a snapshot if the run_at timestamp
    is newer than anything already in the DB.
    Returns True if a new snapshot was stored.
    """
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception as e:
        logger.error(f"dbt watcher: failed to read {path}: {e}")
        return False

    # run_results.json metadata.generated_at is ISO 8601
    generated_at_str = data.get("metadata", {}).get("generated_at")
    if not generated_at_str:
        logger.warning("dbt watcher: run_results.json has no metadata.generated_at")
        return False

    try:
        run_at = datetime.fromisoformat(generated_at_str.replace("Z", "+00:00"))
        run_at = run_at.replace(tzinfo=None)  # store as naive UTC
    except ValueError as e:
        logger.error(f"dbt watcher: bad generated_at format: {e}")
        return False

    # Deduplicate — skip if we already stored this exact run
    last_run_at = _get_last_run_at_from_db()
    if last_run_at and run_at <= last_run_at:
        return False

    # Count results by resource type + status
    counts: dict[str, dict[str, int]] = {}
    results = data.get("results", [])
    for r in results:
        uid = r.get("unique_id", "")
        rtype = uid.split(".")[0] if "." in uid else "unknown"  # model / test / seed / snapshot
        status = r.get("status", "unknown")
        counts.setdefault(rtype, {})
        counts[rtype][status] = counts[rtype].get(status, 0) + 1

    elapsed = data.get("elapsed_time")

    snapshot = DbtRunSnapshot(
        run_at=run_at,
        detected_at=datetime.utcnow(),
        elapsed_time=elapsed,
        models_pass=counts.get("model", {}).get("success", 0),
        models_fail=counts.get("model", {}).get("error", 0),
        models_error=counts.get("model", {}).get("error", 0),
        models_skip=counts.get("model", {}).get("skip", 0),
        tests_pass=counts.get("test", {}).get("pass", 0),
        tests_fail=counts.get("test", {}).get("fail", 0),
        tests_error=counts.get("test", {}).get("error", 0),
        tests_warn=counts.get("test", {}).get("warn", 0),
        results_json=json.dumps(results),
    )

    db = SessionLocal()
    try:
        db.add(snapshot)
        db.commit()
        logger.info(f"dbt watcher: stored snapshot for run at {run_at} "
                    f"(models: {snapshot.models_pass} pass / {snapshot.models_fail} fail, "
                    f"tests: {snapshot.tests_pass} pass / {snapshot.tests_fail} fail)")

        # After commit, trigger monitors for all active dbt-model tables
        try:
            from services.table_refresh_watcher import _trigger_monitors
            db2 = SessionLocal()
            tables = db2.query(MonitoredTable).filter(MonitoredTable.is_active == True).all()
            db2.close()
            for t in tables:
                _trigger_monitors(t.id)
        except Exception as e:
            logger.warning(f"dbt_watcher: failed to trigger monitors: {e}")

        return True
    except Exception as e:
        logger.error(f"dbt watcher: DB error: {e}")
        db.rollback()
        return False
    finally:
        db.close()


def check_for_new_run():
    """
    Called by APScheduler every 2 minutes.
    Checks if run_results.json has been modified and snapshots it if so.
    """
    global _last_mtime

    path = _run_results_path()
    if not path:
        return  # dbt not configured or file not present yet

    try:
        mtime = os.path.getmtime(path)
    except OSError:
        return

    if _last_mtime is None:
        # First check after startup — initialise mtime from DB to avoid
        # re-snapshotting a run we already stored before the restart.
        _last_mtime = mtime
        # Still try to store in case the backend was just installed and this
        # run_results.json was never snapshotted.
        _parse_and_store(path)
        return

    if mtime > _last_mtime:
        _last_mtime = mtime
        _parse_and_store(path)


def start_watcher(scheduler):
    """Register the watcher job with the existing APScheduler instance."""
    scheduler.add_job(
        check_for_new_run,
        trigger="interval",
        minutes=2,
        id="dbt_watcher",
        replace_existing=True,
    )
    logger.info("dbt watcher: started (checking every 2 minutes)")
