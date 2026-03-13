from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any

class CheckStatus(str, Enum):
    PASS = "pass"
    WARNING = "warning"
    FAIL = "fail"
    ERROR = "error"

@dataclass
class CheckResult:
    status: CheckStatus
    message: str
    value: Any = None          # The measured value (e.g., lag hours, row count, null pct)
    threshold: Any = None      # The configured threshold
    details: dict = None       # Extra structured data for UI

class BaseMonitor(ABC):
    def __init__(self, project: str, dataset: str, table: str, config: dict):
        self.project = project
        self.dataset = dataset
        self.table = table
        self.config = config
        self.full_table_id = f"`{project}.{dataset}.{table}`"

    @abstractmethod
    def run(self) -> CheckResult:
        pass
