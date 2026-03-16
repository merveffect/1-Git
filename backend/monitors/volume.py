"""
VolumeMonitor — detects row count anomalies.
Uses TableUpdateHistory (actual table refresh events) to build a rolling
average baseline. Requires min_baseline_runs data points before flagging.
Flags when current count deviates > deviation_pct_threshold % from baseline.
"""
from monitors.base import BaseMonitor, CheckResult, CheckStatus
from services.bigquery_client import bq_client
import statistics


class VolumeMonitor(BaseMonitor):
    def __init__(self, project, dataset, table, config,
                 historical_counts=None, is_first_run=True):
        super().__init__(project, dataset, table, config)
        self.historical_counts = [c for c in (historical_counts or []) if c is not None and c > 0]
        self.is_first_run = is_first_run

    def run(self) -> CheckResult:
        min_baseline = self.config.get("min_baseline_runs", 5)
        deviation_threshold = self.config.get("deviation_pct_threshold", 25.0)

        try:
            meta = bq_client.get_table_metadata(self.project, self.dataset, self.table)
            current_count = int(meta.get("row_count") or 0) if meta else 0

            if len(self.historical_counts) < min_baseline:
                needed = min_baseline - len(self.historical_counts)
                return CheckResult(
                    status=CheckStatus.PASS,
                    message=f"Row count: {current_count:,} — building baseline ({len(self.historical_counts)}/{min_baseline} refreshes recorded)",
                    value=current_count,
                    details={
                        "row_count": current_count,
                        "baseline_runs": len(self.historical_counts),
                        "needed_for_baseline": needed,
                    },
                )

            baseline_avg = statistics.mean(self.historical_counts)
            baseline_stdev = statistics.stdev(self.historical_counts) if len(self.historical_counts) > 1 else 0

            if baseline_avg == 0:
                return CheckResult(
                    status=CheckStatus.PASS,
                    message=f"Row count: {current_count:,} (baseline avg: 0, skipping check)",
                    value=current_count,
                )

            deviation_pct = abs(current_count - baseline_avg) / baseline_avg * 100
            direction = "dropped" if current_count < baseline_avg else "increased"

            if deviation_pct > deviation_threshold:
                status = CheckStatus.FAIL
                message = (
                    f"Volume anomaly: {current_count:,} rows "
                    f"({direction} {deviation_pct:.1f}% from baseline avg of {int(baseline_avg):,})"
                )
            elif deviation_pct > deviation_threshold * 0.6:
                status = CheckStatus.WARNING
                message = (
                    f"Volume slightly unusual: {current_count:,} rows "
                    f"({deviation_pct:.1f}% from baseline avg of {int(baseline_avg):,})"
                )
            else:
                status = CheckStatus.PASS
                message = (
                    f"Volume normal: {current_count:,} rows "
                    f"(baseline avg: {int(baseline_avg):,}, deviation: {deviation_pct:.1f}%)"
                )

            return CheckResult(
                status=status,
                message=message,
                value=current_count,
                threshold=deviation_threshold,
                details={
                    "row_count": current_count,
                    "baseline_avg": round(baseline_avg),
                    "baseline_stdev": round(baseline_stdev),
                    "deviation_pct": round(deviation_pct, 2),
                    "direction": direction,
                    "baseline_runs_used": len(self.historical_counts),
                },
            )
        except Exception as e:
            return CheckResult(status=CheckStatus.ERROR, message=str(e))
