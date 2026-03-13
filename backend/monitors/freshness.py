from monitors.base import BaseMonitor, CheckResult, CheckStatus
from services.bigquery_client import bq_client
from datetime import datetime, timezone

class FreshnessMonitor(BaseMonitor):
    def run(self) -> CheckResult:
        threshold_hours = self.config.get("max_lag_hours", 24)
        try:
            metadata = bq_client.get_table_metadata(self.project, self.dataset, self.table)
            if not metadata or not metadata.get("last_modified_time"):
                return CheckResult(status=CheckStatus.ERROR, message="Could not retrieve table metadata")

            last_modified = metadata["last_modified_time"]
            if hasattr(last_modified, 'tzinfo') and last_modified.tzinfo is None:
                last_modified = last_modified.replace(tzinfo=timezone.utc)

            now = datetime.now(timezone.utc)
            lag_hours = (now - last_modified).total_seconds() / 3600

            if lag_hours > threshold_hours:
                status = CheckStatus.FAIL
                message = f"Table not updated in {lag_hours:.1f} hours (threshold: {threshold_hours}h)"
            elif lag_hours > threshold_hours * 0.8:
                status = CheckStatus.WARNING
                message = f"Table freshness approaching threshold: {lag_hours:.1f}h"
            else:
                status = CheckStatus.PASS
                message = f"Table updated {lag_hours:.1f} hours ago"

            return CheckResult(
                status=status, message=message,
                value=round(lag_hours, 2), threshold=threshold_hours,
                details={"last_modified": last_modified.isoformat(), "lag_hours": round(lag_hours, 2)}
            )
        except Exception as e:
            return CheckResult(status=CheckStatus.ERROR, message=str(e))
