import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from database import engine, Base, SessionLocal
from routers import monitors, runs, alerts, tables, dbt
from services.scheduler import start_scheduler
import logging
import os

logging.basicConfig(level=logging.INFO)

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Data Pipeline Monitor")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(tables.router)
app.include_router(monitors.router)
app.include_router(runs.router)
app.include_router(alerts.router)
app.include_router(dbt.router)

@app.get("/api/dashboard")
def dashboard_stats():
    from models.monitor import MonitoredTable, MonitorConfig, MonitorRun, Alert
    import json
    db = SessionLocal()
    try:
        active_tables = db.query(MonitoredTable).filter(MonitoredTable.is_active == True).all()
        stats = {"total_tables": len(active_tables), "passing": 0, "warning": 0, "failing": 0, "error": 0}

        for table in active_tables:
            configs = db.query(MonitorConfig).filter(
                MonitorConfig.table_id == table.id,
                MonitorConfig.is_enabled == True
            ).all()
            table_status = "passing"
            for cfg in configs:
                last_run = db.query(MonitorRun).filter(
                    MonitorRun.monitor_config_id == cfg.id
                ).order_by(MonitorRun.completed_at.desc()).first()
                if last_run:
                    if last_run.status in ("fail", "error") and table_status != "failing":
                        table_status = "failing"
                    elif last_run.status == "warning" and table_status == "passing":
                        table_status = "warning"
            stats[table_status if table_status != "failing" else "failing"] = stats.get(
                table_status if table_status != "failing" else "failing", 0) + 1

        stats["unacknowledged_alerts"] = db.query(Alert).filter(Alert.is_acknowledged == False).count()
        return stats
    finally:
        db.close()

@app.on_event("startup")
def on_startup():
    db = SessionLocal()
    try:
        start_scheduler(db)
    finally:
        db.close()

# Serve React frontend in production (after `npm run build`)
_frontend_dist = os.path.join(os.path.dirname(__file__), "..", "frontend", "dist")
if os.path.isdir(_frontend_dist):
    app.mount("/assets", StaticFiles(directory=os.path.join(_frontend_dist, "assets")), name="assets")

    @app.get("/{full_path:path}", include_in_schema=False)
    def serve_frontend(full_path: str):
        return FileResponse(os.path.join(_frontend_dist, "index.html"))
