from monitors.base import BaseMonitor, CheckResult, CheckStatus
from services.bigquery_client import bq_client

class NullRateMonitor(BaseMonitor):
    def run(self) -> CheckResult:
        threshold_pct = self.config.get("max_null_pct", 5.0)
        is_partitioned = self.config.get("is_partitioned", False)

        try:
            columns = bq_client.get_table_schema(self.project, self.dataset, self.table)
            if not columns:
                return CheckResult(status=CheckStatus.ERROR, message="Could not retrieve schema")

            col_names = [c["column_name"] for c in columns]
            null_checks = ",\n  ".join([
                f"COUNTIF({col} IS NULL) / COUNT(*) * 100 AS `{col}_null_pct`"
                for col in col_names
            ])

            if is_partitioned:
                sample_clause = "WHERE DATE(_PARTITIONTIME) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)"
            else:
                sample_clause = "TABLESAMPLE SYSTEM (10 PERCENT)"

            query = f"""
            SELECT {null_checks}, COUNT(*) AS sampled_rows
            FROM {self.full_table_id}
            {sample_clause}
            """

            rows = bq_client.run_query(query)
            if not rows:
                return CheckResult(status=CheckStatus.ERROR, message="Query returned no results")

            row = rows[0]
            sampled_rows = row.pop("sampled_rows", 0)

            column_results = {}
            failing_cols = []
            for key, val in row.items():
                col_name = key.replace("_null_pct", "")
                null_pct = float(val or 0)
                column_results[col_name] = round(null_pct, 2)
                if null_pct > threshold_pct:
                    failing_cols.append(f"{col_name} ({null_pct:.1f}%)")

            if failing_cols:
                status = CheckStatus.FAIL
                message = f"High null rates: {', '.join(failing_cols[:3])}"
            else:
                max_null = max(column_results.values()) if column_results else 0
                status = CheckStatus.PASS
                message = f"Null rates OK (max: {max_null:.1f}%, sampled {sampled_rows:,} rows)"

            return CheckResult(
                status=status, message=message, threshold=threshold_pct,
                details={"columns": column_results, "sampled_rows": sampled_rows, "failing_columns": failing_cols}
            )
        except Exception as e:
            return CheckResult(status=CheckStatus.ERROR, message=str(e))
