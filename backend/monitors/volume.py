from monitors.base import BaseMonitor, CheckResult, CheckStatus
from services.bigquery_client import bq_client
import statistics

class VolumeMonitor(BaseMonitor):
    def __init__(self, project, dataset, table, config, historical_counts: list[int] = None):
        super().__init__(project, dataset, table, config)
        self.historical_counts = historical_counts or []

    def run(self) -> CheckResult:
        z_threshold = self.config.get("z_score_threshold", 3.0)
        try:
            metadata = bq_client.get_table_metadata(self.project, self.dataset, self.table)
            current_count = int(metadata.get("row_count", 0)) if metadata else 0

            if len(self.historical_counts) < 3:
                return CheckResult(
                    status=CheckStatus.PASS,
                    message=f"Current row count: {current_count:,} (collecting baseline data)",
                    value=current_count,
                    details={"row_count": current_count, "baseline_runs": len(self.historical_counts)}
                )

            mean = statistics.mean(self.historical_counts)
            stdev = statistics.stdev(self.historical_counts)

            if stdev == 0:
                z_score = 0
            else:
                z_score = abs(current_count - mean) / stdev

            pct_change = ((current_count - self.historical_counts[-1]) / self.historical_counts[-1] * 100) if self.historical_counts[-1] > 0 else 0

            if z_score > z_threshold:
                status = CheckStatus.FAIL
                message = f"Volume anomaly detected: {current_count:,} rows (Z-score: {z_score:.2f})"
            elif z_score > z_threshold * 0.7:
                status = CheckStatus.WARNING
                message = f"Volume slightly unusual: {current_count:,} rows (Z-score: {z_score:.2f})"
            else:
                status = CheckStatus.PASS
                message = f"Volume normal: {current_count:,} rows ({pct_change:+.1f}% vs last run)"

            return CheckResult(
                status=status, message=message, value=current_count, threshold=z_threshold,
                details={"row_count": current_count, "z_score": round(z_score, 3), "mean": round(mean), "pct_change": round(pct_change, 2)}
            )
        except Exception as e:
            return CheckResult(status=CheckStatus.ERROR, message=str(e))
