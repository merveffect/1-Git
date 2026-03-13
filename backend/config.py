from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    database_url: str = "sqlite:///./monitor.db"
    scheduler_interval_minutes: int = 60
    default_freshness_threshold_hours: int = 24
    default_volume_zscore_threshold: float = 3.0
    default_null_rate_threshold_pct: float = 5.0
    # Set this to your dbt project root (the folder containing dbt_project.yml)
    # e.g. DBT_PROJECT_PATH=/Users/you/your-dbt-project
    dbt_project_path: Optional[str] = None

    class Config:
        env_file = ".env"

settings = Settings()
