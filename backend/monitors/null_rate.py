"""
NullRateMonitor — checks configured columns for nulls.
- Default: checks key columns (passed from duplicate monitor config)
- Additional columns configurable via check_columns in config
- Binary result: FAIL if ANY null found, PASS otherwise
- Partition-aware: first run uses full scan/TABLESAMPLE, subsequent runs filter to latest partition
"""
from monitors.base import BaseMonitor, CheckResult, CheckStatus
from services.bigquery_client import bq_client


class NullRateMonitor(BaseMonitor):
    def __init__(self, project, dataset, table, config,
                 key_columns_from_duplicate=None, is_first_run=True):
        super().__init__(project, dataset, table, config)
        self.key_cols = key_columns_from_duplicate or []
        self.is_first_run = is_first_run

    def run(self) -> CheckResult:
        # Determine which columns to check
        extra_cols = self.config.get("check_columns", [])
        use_key_cols = self.config.get("use_key_columns", True)

        check_cols = list(extra_cols)
        if use_key_cols:
            for c in self.key_cols:
                if c not in check_cols:
                    check_cols.append(c)

        if not check_cols:
            return CheckResult(
                status=CheckStatus.WARNING,
                message="No columns configured for null check. Set key columns in the Duplicates monitor.",
                details={"check_columns": []},
            )

        try:
            sample_clause = bq_client.get_sample_clause(
                self.project, self.dataset, self.table,
                self.is_first_run, self.config
            )

            null_checks = ",\n  ".join(
                f"COUNTIF(`{col}` IS NULL) AS `{col}_nulls`"
                for col in check_cols
            )

            query = f"""
            SELECT
              {null_checks},
              COUNT(*) AS total_rows
            FROM {self.full_table_id}
            {sample_clause}
            """

            rows = bq_client.run_query(query)
            if not rows:
                return CheckResult(status=CheckStatus.ERROR, message="Query returned no results")

            row = rows[0]
            total = int(row.get("total_rows") or 0)

            # Fetch real total row count from BQ metadata (free API call, no bytes billed)
            meta = bq_client.get_table_metadata(self.project, self.dataset, self.table)
            total_table_rows = int(meta.get("row_count") or 0) if meta else 0

            failing_cols = []
            col_results = {}
            for col in check_cols:
                nulls = int(row.get(f"{col}_nulls") or 0)
                col_results[col] = nulls
                if nulls > 0:
                    failing_cols.append(f"{col} ({nulls:,} nulls)")

            scan_type = "full scan" if self.is_first_run else "latest partition"

            if total_table_rows > 0 and total_table_rows != total:
                scan_info = f"{total:,} rows scanned ({scan_type}); {total_table_rows:,} rows total"
            else:
                scan_info = f"{total:,} rows, {scan_type}"

            if failing_cols:
                status = CheckStatus.FAIL
                message = f"Nulls found in: {', '.join(failing_cols[:3])}"
            else:
                status = CheckStatus.PASS
                message = f"No nulls in {len(check_cols)} column(s) — {scan_info}"

            return CheckResult(
                status=status,
                message=message,
                value=len(failing_cols),
                details={
                    "columns_checked": check_cols,
                    "column_null_counts": col_results,
                    "failing_columns": failing_cols,
                    "rows_scanned": total,
                    "total_table_rows": total_table_rows,
                    "scan_type": scan_type,
                },
            )
        except Exception as e:
            return CheckResult(status=CheckStatus.ERROR, message=str(e))
