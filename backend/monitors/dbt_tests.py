"""
DbtTestsMonitor — surfaces dbt test results from run_results.json for a model.
Does not run BigQuery queries; reads local artifact files only.
"""

from monitors.base import BaseMonitor, CheckResult, CheckStatus
from services.dbt_reader import get_model_test_results, is_configured


class DbtTestsMonitor(BaseMonitor):
    def run(self) -> CheckResult:
        if not is_configured():
            return CheckResult(
                status=CheckStatus.WARNING,
                message="dbt project path not configured. Set DBT_PROJECT_PATH in .env",
            )

        results = get_model_test_results(self.table)
        if not results:
            return CheckResult(
                status=CheckStatus.PASS,
                message="No dbt tests found for this model (or run_results.json not present)",
                details={"tests": []},
            )

        failed = [t for t in results if t["status"] in ("fail", "error")]
        warned = [t for t in results if t["status"] == "warn"]
        passed = [t for t in results if t["status"] == "pass"]
        not_run = [t for t in results if t["status"] == "not_run"]

        if failed:
            status = CheckStatus.FAIL
            names = ", ".join(t["name"] for t in failed[:3])
            message = f"{len(failed)} test(s) failing: {names}"
        elif warned:
            status = CheckStatus.WARNING
            message = f"{len(warned)} test(s) with warnings"
        else:
            status = CheckStatus.PASS
            message = f"All {len(passed)} dbt test(s) passing"

        return CheckResult(
            status=status,
            message=message,
            value=len(failed),
            details={
                "tests": results,
                "summary": {
                    "failed": len(failed),
                    "warned": len(warned),
                    "passed": len(passed),
                    "not_run": len(not_run),
                    "total": len(results),
                },
            },
        )
