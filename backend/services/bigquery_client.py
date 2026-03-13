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
        """Get table metadata from INFORMATION_SCHEMA - free, no bytes billed"""
        query = f"""
        SELECT last_modified_time, row_count, size_bytes
        FROM `{project}.{dataset}`.INFORMATION_SCHEMA.TABLE_STORAGE_BY_PROJECT
        WHERE project_id = '{project}' AND dataset_id = '{dataset}' AND table_id = '{table}'
        """
        try:
            rows = self.run_query(query)
            return rows[0] if rows else {}
        except Exception as e:
            # Fallback to TABLE_STORAGE
            query2 = f"""
            SELECT last_modified_time, row_count, size_bytes
            FROM `region-us`.INFORMATION_SCHEMA.TABLE_STORAGE
            WHERE project_id = '{project}' AND dataset_id = '{dataset}' AND table_id = '{table}'
            """
            try:
                rows = self.run_query(query2)
                return rows[0] if rows else {}
            except:
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

bq_client = BigQueryClient()
