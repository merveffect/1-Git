"""
Reads dbt Core artifact files from the target/ directory of a dbt project.

Artifacts parsed:
  manifest.json     - models, tests, sources, column info, lineage (always present after dbt run/compile)
  run_results.json  - last run results per node (present after dbt run / dbt test)
  catalog.json      - column-level metadata (present after dbt docs generate)

Set DBT_PROJECT_PATH in your .env to point at the dbt project root.
"""

import json
import os
from pathlib import Path
from typing import Optional
from config import settings
import logging

logger = logging.getLogger(__name__)


def _target_dir() -> Optional[Path]:
    if not settings.dbt_project_path:
        return None
    p = Path(settings.dbt_project_path) / "target"
    if not p.exists():
        logger.warning(f"dbt target dir not found: {p}")
        return None
    return p


def _load(filename: str) -> Optional[dict]:
    target = _target_dir()
    if not target:
        return None
    fp = target / filename
    if not fp.exists():
        logger.warning(f"dbt artifact not found: {fp}")
        return None
    with open(fp) as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# Public helpers
# ---------------------------------------------------------------------------

def is_configured() -> bool:
    return bool(settings.dbt_project_path)


def get_project_name() -> Optional[str]:
    manifest = _load("manifest.json")
    if not manifest:
        return None
    return manifest.get("metadata", {}).get("dbt_project_name")


def get_models() -> list[dict]:
    """
    Returns a list of dbt models with key fields:
      unique_id, name, schema, database, fqn, description,
      columns, depends_on, tags, config
    """
    manifest = _load("manifest.json")
    if not manifest:
        return []

    nodes = manifest.get("nodes", {})
    models = []
    for uid, node in nodes.items():
        if node.get("resource_type") != "model":
            continue
        models.append({
            "unique_id": uid,
            "name": node.get("name"),
            "schema": node.get("schema"),
            "database": node.get("database"),
            "fqn": node.get("fqn", []),
            "description": node.get("description", ""),
            "columns": node.get("columns", {}),
            "depends_on": node.get("depends_on", {}).get("nodes", []),
            "tags": node.get("tags", []),
            "config": node.get("config", {}),
            "path": node.get("path"),
            "original_file_path": node.get("original_file_path"),
        })
    return models


def get_tests() -> list[dict]:
    """
    Returns all dbt tests defined in the manifest.
    """
    manifest = _load("manifest.json")
    if not manifest:
        return []

    nodes = manifest.get("nodes", {})
    tests = []
    for uid, node in nodes.items():
        if node.get("resource_type") not in ("test", "generic_test", "singular_test"):
            continue
        tests.append({
            "unique_id": uid,
            "name": node.get("name"),
            "test_type": node.get("resource_type"),
            "attached_node": node.get("attached_node"),
            "depends_on": node.get("depends_on", {}).get("nodes", []),
            "column_name": node.get("column_name"),
            "tags": node.get("tags", []),
        })
    return tests


def get_last_run_results() -> dict[str, dict]:
    """
    Returns a map of unique_id -> result dict from the most recent dbt run.
    Keys: unique_id, status, execution_time, failures, message
    """
    run_results = _load("run_results.json")
    if not run_results:
        return {}

    results = {}
    for r in run_results.get("results", []):
        uid = r.get("unique_id")
        if uid:
            results[uid] = {
                "unique_id": uid,
                "status": r.get("status"),           # success, error, warn, fail, skipped
                "execution_time": r.get("execution_time"),
                "failures": r.get("failures"),
                "message": r.get("message"),
                "adapter_response": r.get("adapter_response", {}),
            }
    return results


def get_model_lineage(model_unique_id: str) -> dict:
    """
    Returns upstream (parents) and downstream (children) for a given model.
    """
    manifest = _load("manifest.json")
    if not manifest:
        return {"upstream": [], "downstream": []}

    child_map = manifest.get("child_map", {})
    nodes = manifest.get("nodes", {})

    node = nodes.get(model_unique_id, {})
    upstream = node.get("depends_on", {}).get("nodes", [])

    downstream = []
    for uid, children in child_map.items():
        if model_unique_id in children:
            downstream.append(uid)

    def _label(uid: str) -> dict:
        n = nodes.get(uid, {})
        return {"unique_id": uid, "name": n.get("name", uid), "resource_type": n.get("resource_type")}

    return {
        "upstream": [_label(u) for u in upstream],
        "downstream": [_label(d) for d in downstream],
    }


def get_model_test_results(model_name: str) -> list[dict]:
    """
    Returns test results for a specific model, combining manifest test definitions
    with the latest run_results.
    """
    tests = get_tests()
    run_results = get_last_run_results()

    model_tests = [t for t in tests if model_name in t.get("unique_id", "")]
    enriched = []
    for t in model_tests:
        result = run_results.get(t["unique_id"], {})
        enriched.append({
            **t,
            "status": result.get("status", "not_run"),
            "execution_time": result.get("execution_time"),
            "failures": result.get("failures"),
            "message": result.get("message"),
        })
    return enriched


def get_catalog_for_model(model_name: str) -> Optional[dict]:
    """
    Returns catalog metadata (columns with types and stats) for a model.
    Requires dbt docs generate to have been run.
    """
    catalog = _load("catalog.json")
    if not catalog:
        return None

    nodes = catalog.get("nodes", {})
    for uid, node in nodes.items():
        if node.get("metadata", {}).get("name") == model_name:
            return node
    return None
