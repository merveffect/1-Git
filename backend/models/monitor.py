from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Text
from sqlalchemy.orm import relationship
from database import Base

class MonitoredTable(Base):
    __tablename__ = "monitored_tables"
    id = Column(Integer, primary_key=True)
    project_id = Column(String, nullable=False)
    dataset_id = Column(String, nullable=False)
    table_id = Column(String, nullable=False)
    display_name = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime)
    monitor_configs = relationship("MonitorConfig", back_populates="table")
    alerts = relationship("Alert", back_populates="table")

class MonitorConfig(Base):
    __tablename__ = "monitor_configs"
    id = Column(Integer, primary_key=True)
    table_id = Column(Integer, ForeignKey("monitored_tables.id"), nullable=False)
    monitor_type = Column(String, nullable=False)  # freshness, volume, null_rate, duplicate, schema_drift
    is_enabled = Column(Boolean, default=True)
    config_json = Column(Text, default="{}")
    schedule_minutes = Column(Integer, default=60)
    table = relationship("MonitoredTable", back_populates="monitor_configs")
    runs = relationship("MonitorRun", back_populates="monitor_config")

class MonitorRun(Base):
    __tablename__ = "monitor_runs"
    id = Column(Integer, primary_key=True)
    monitor_config_id = Column(Integer, ForeignKey("monitor_configs.id"), nullable=False)
    started_at = Column(DateTime)
    completed_at = Column(DateTime)
    status = Column(String)  # pass, warning, fail, error, running
    result_json = Column(Text)
    error_message = Column(Text)
    monitor_config = relationship("MonitorConfig", back_populates="runs")

class Alert(Base):
    __tablename__ = "alerts"
    id = Column(Integer, primary_key=True)
    monitor_run_id = Column(Integer, ForeignKey("monitor_runs.id"))
    table_id = Column(Integer, ForeignKey("monitored_tables.id"))
    monitor_type = Column(String)
    severity = Column(String)  # warning, critical
    message = Column(Text)
    created_at = Column(DateTime)
    is_acknowledged = Column(Boolean, default=False)
    table = relationship("MonitoredTable", back_populates="alerts")

class SchemaSnapshot(Base):
    __tablename__ = "schema_snapshots"
    id = Column(Integer, primary_key=True)
    table_id = Column(Integer, ForeignKey("monitored_tables.id"))
    snapshot_json = Column(Text)
    is_baseline = Column(Boolean, default=False)
    created_at = Column(DateTime)

class DbtRunSnapshot(Base):
    """One row per dbt run detected by the file watcher."""
    __tablename__ = "dbt_run_snapshots"
    id = Column(Integer, primary_key=True)
    # When dbt itself ran (from run_results.json metadata.generated_at)
    run_at = Column(DateTime, nullable=False)
    # When our watcher noticed the file changed
    detected_at = Column(DateTime, nullable=False)
    # Total elapsed time reported by dbt
    elapsed_time = Column(Float)
    # Counts by resource type + status
    models_pass  = Column(Integer, default=0)
    models_fail  = Column(Integer, default=0)
    models_error = Column(Integer, default=0)
    models_skip  = Column(Integer, default=0)
    tests_pass   = Column(Integer, default=0)
    tests_fail   = Column(Integer, default=0)
    tests_error  = Column(Integer, default=0)
    tests_warn   = Column(Integer, default=0)
    # Full results JSON for drill-down
    results_json = Column(Text)
