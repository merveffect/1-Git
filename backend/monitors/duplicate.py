from monitors.base import BaseMonitor, CheckResult, CheckStatus
from services.bigquery_client import bq_client

class DuplicateMonitor(BaseMonitor):
    def __init__(self, project, dataset, table, config, is_first_run=True, **kwargs):
        super().__init__(project, dataset, table, config)
        self.is_first_run = is_first_run

    def run(self) -> CheckResult:
        key_columns = self.config.get("key_columns", [])
        threshold_pct = self.config.get("max_duplicate_pct", 1.0)

        if not key_columns:
            return CheckResult(status=CheckStatus.WARNING, message="No key columns configured for duplicate check")

        try:
            key_expr = "CONCAT(" + ", '|', ".join(f"CAST({col} AS STRING)" for col in key_columns) + ")"

            sample_clause = bq_client.get_sample_clause(
                self.project, self.dataset, self.table,
                self.is_first_run, self.config
            )

            query = f"""
            SELECT
                COUNT(*) AS total_rows,
                COUNT(DISTINCT {key_expr}) AS unique_rows,
                COUNT(*) - COUNT(DISTINCT {key_expr}) AS duplicate_count,
                ROUND((COUNT(*) - COUNT(DISTINCT {key_expr})) / COUNT(*) * 100, 2) AS duplicate_pct
            FROM {self.full_table_id}
            {sample_clause}
            """

            rows = bq_client.run_query(query)
            if not rows:
                return CheckResult(status=CheckStatus.ERROR, message="Query returned no results")

            r = rows[0]
            dup_pct = float(r["duplicate_pct"] or 0)
            dup_count = int(r["duplicate_count"] or 0)
            total = int(r["total_rows"] or 0)

            if dup_pct > threshold_pct:
                status = CheckStatus.FAIL
                message = f"Duplicates detected: {dup_count:,} rows ({dup_pct:.2f}%)"
            elif dup_pct > threshold_pct * 0.5:
                status = CheckStatus.WARNING
                message = f"Low duplicate rate: {dup_count:,} rows ({dup_pct:.2f}%)"
            else:
                status = CheckStatus.PASS
                message = f"No duplicates detected ({total:,} rows sampled)"

            return CheckResult(
                status=status, message=message, value=dup_pct, threshold=threshold_pct,
                details={"duplicate_count": dup_count, "duplicate_pct": dup_pct, "total_rows": total, "key_columns": key_columns}
            )
        except Exception as e:
            return CheckResult(status=CheckStatus.ERROR, message=str(e))
