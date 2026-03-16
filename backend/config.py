from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    database_url: str = "sqlite:///./monitor.db"
    scheduler_interval_minutes: int = 60
    default_freshness_threshold_hours: int = 24
    default_volume_zscore_threshold: float = 3.0
    default_null_rate_threshold_pct: float = 5.0
    # dbt project paths — supports multiple projects
    # New:    DBT_PROJECT_PATHS=/path/project1,/path/project2  (comma-separated)
    # Legacy: DBT_PROJECT_PATH=/path/project  (single path, still supported)
    dbt_project_path: Optional[str] = None   # legacy single path
    dbt_project_paths: Optional[str] = None  # comma-separated list (new)

    class Config:
        env_file = ".env"

settings = Settings()
