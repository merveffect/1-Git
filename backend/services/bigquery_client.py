from google.cloud import bigquery
from google.auth import default as google_auth_default
import logging

logger = logging.getLogger(__name__)

class BigQueryClient:
    def __init__(self):
        credentials, project = google_auth_default()
        self.client = bigquery.Client(credentials=credentials)

    def run_query(self, query: str, params: dict = None) -> list[dict]:
        """Execute a query and return results as list of dicts"""
        job_config = bigquery.QueryJobConfig(maximum_bytes_billed=10 * 1024**3)  # 10GB cap
        job = self.client.query(query, job_config=job_config)
        results = job.result()
        return [dict(row) for row in results]

    def get_table_metadata(self, project: str, dataset: str, table: str) -> dict:
        """
        Get table metadata using the BQ client API — region-agnostic, no bytes billed.
        Returns last_modified_time (datetime), row_count (int), size_bytes (int).
        """
        try:
            table_ref = self.client.get_table(f"{project}.{dataset}.{table}")
            return {
                "last_modified_time": table_ref.modified,   # datetime with tz
                "row_count": table_ref.num_rows,
                "size_bytes": table_ref.num_bytes,
            }
        except Exception as e:
            logger.error(f"get_table_metadata failed for {project}.{dataset}.{table}: {e}")
            return {}

    def get_table_schema(self, project: str, dataset: str, table: str) -> list[dict]:
        """Get column schema - free metadata query"""
        query = f"""
        SELECT column_name, ordinal_position, is_nullable, data_type
        FROM `{project}.{dataset}`.INFORMATION_SCHEMA.COLUMNS
        WHERE table_name = '{table}'
        ORDER BY ordinal_position
        """
        return self.run_query(query)

    def list_datasets(self, project: str) -> list[str]:
        return [ds.dataset_id for ds in self.client.list_datasets(project)]

    def list_tables(self, project: str, dataset: str) -> list[str]:
        dataset_ref = self.client.dataset(dataset, project=project)
        return [t.table_id for t in self.client.list_tables(dataset_ref)]

    def get_partition_info(self, project: str, dataset: str, table: str) -> dict:
        """Returns partition field info from BQ table metadata."""
        try:
            tbl = self.client.get_table(f"{project}.{dataset}.{table}")
            if tbl.time_partitioning:
                return {
                    "is_partitioned": True,
                    "partition_type": "time",
                    "partition_field": tbl.time_partitioning.field,  # None = _PARTITIONTIME
                }
            if tbl.range_partitioning:
                return {
                    "is_partitioned": True,
                    "partition_type": "range",
                    "partition_field": tbl.range_partitioning.field,
                }
        except Exception as e:
            logger.warning(f"get_partition_info failed: {e}")
        return {"is_partitioned": False, "partition_type": None, "partition_field": None}

    def get_sample_clause(self, project: str, dataset: str, table: str,
                          is_first_run: bool, config: dict) -> str:
        """
        Returns the appropriate filter/sample clause for a monitor query.
        - First run: TABLESAMPLE SYSTEM (10 PERCENT)
        - Partitioned table: filter to latest partition
        - Non-partitioned with timestamp_column config: filter to last N hours
        - Non-partitioned without: TABLESAMPLE SYSTEM (10 PERCENT)
        """
        if is_first_run:
            return "TABLESAMPLE SYSTEM (10 PERCENT)"

        info = self.get_partition_info(project, dataset, table)
        full_id = f"`{project}.{dataset}.{table}`"

        if info["is_partitioned"]:
            field = info["partition_field"]
            if info["partition_type"] == "range" and field:
                return f"WHERE {field} = (SELECT MAX({field}) FROM {full_id})"
            elif field:
                return f"WHERE DATE({field}) = (SELECT MAX(DATE({field})) FROM {full_id})"
            else:
                return f"WHERE DATE(_PARTITIONTIME) = (SELECT MAX(DATE(_PARTITIONTIME)) FROM {full_id} WHERE _PARTITIONTIME IS NOT NULL)"

        ts_col = config.get("timestamp_column")
        schedule_hours = config.get("schedule_hours", 24)
        if ts_col:
            return f"WHERE CAST({ts_col} AS TIMESTAMP) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {int(schedule_hours * 2)} HOUR)"

        return "TABLESAMPLE SYSTEM (10 PERCENT)"

bq_client = BigQueryClient()
