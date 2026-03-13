from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime

class MonitoredTableCreate(BaseModel):
    project_id: str
    dataset_id: str
    table_id: str
    display_name: Optional[str] = None

class MonitoredTableResponse(BaseModel):
    id: int
    project_id: str
    dataset_id: str
    table_id: str
    display_name: Optional[str]
    is_active: bool
    created_at: Optional[datetime]
    class Config:
        from_attributes = True

class MonitorConfigResponse(BaseModel):
    id: int
    table_id: int
    monitor_type: str
    is_enabled: bool
    config_json: str
    schedule_minutes: int
    class Config:
        from_attributes = True

class MonitorConfigUpdate(BaseModel):
    is_enabled: Optional[bool] = None
    config_json: Optional[Any] = None
    schedule_minutes: Optional[int] = None

class MonitorRunResponse(BaseModel):
    id: int
    monitor_config_id: int
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    status: str
    result_json: Optional[str]
    error_message: Optional[str]
    class Config:
        from_attributes = True

class AlertResponse(BaseModel):
    id: int
    table_id: Optional[int]
    monitor_type: str
    severity: str
    message: str
    created_at: Optional[datetime]
    is_acknowledged: bool
    table_name: Optional[str] = None
    class Config:
        from_attributes = True

class DashboardStats(BaseModel):
    total_tables: int
    passing: int
    warning: int
    failing: int
    error: int
    unacknowledged_alerts: int
