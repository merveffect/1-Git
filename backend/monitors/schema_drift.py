from monitors.base import BaseMonitor, CheckResult, CheckStatus
from services.bigquery_client import bq_client
import json

class SchemaDriftMonitor(BaseMonitor):
    def __init__(self, project, dataset, table, config, baseline_schema: list[dict] = None):
        super().__init__(project, dataset, table, config)
        self.baseline_schema = baseline_schema

    def run(self) -> CheckResult:
        try:
            current_schema = bq_client.get_table_schema(self.project, self.dataset, self.table)

            if not self.baseline_schema:
                return CheckResult(
                    status=CheckStatus.PASS,
                    message="Schema baseline established",
                    details={"schema": current_schema, "is_first_run": True}
                )

            current_cols = {c["column_name"]: c for c in current_schema}
            baseline_cols = {c["column_name"]: c for c in self.baseline_schema}

            added = [c for c in current_cols if c not in baseline_cols]
            removed = [c for c in baseline_cols if c not in current_cols]
            type_changes = [
                {"column": c, "from": baseline_cols[c]["data_type"], "to": current_cols[c]["data_type"]}
                for c in current_cols
                if c in baseline_cols and current_cols[c]["data_type"] != baseline_cols[c]["data_type"]
            ]

            if removed or type_changes:
                status = CheckStatus.FAIL
                message = f"Breaking schema change: {len(removed)} removed, {len(type_changes)} type changes"
            elif added:
                status = CheckStatus.WARNING
                message = f"Schema changed: {len(added)} columns added"
            else:
                status = CheckStatus.PASS
                message = f"Schema unchanged ({len(current_cols)} columns)"

            return CheckResult(
                status=status, message=message,
                details={"added": added, "removed": removed, "type_changes": type_changes, "current_schema": current_schema}
            )
        except Exception as e:
            return CheckResult(status=CheckStatus.ERROR, message=str(e))
