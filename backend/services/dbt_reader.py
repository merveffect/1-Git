"""
Reads dbt Core artifact files from one or more dbt project target/ directories.

Artifacts parsed:
  manifest.json     - models, tests, sources, column info, lineage
  run_results.json  - last run results per node
  catalog.json      - column-level metadata (after dbt docs generate)

Configure via .env:
  DBT_PROJECT_PATHS=/path/to/project1,/path/to/project2   (multi-project)
  DBT_PROJECT_PATH=/path/to/project                        (legacy single)
"""

import json
from pathlib import Path
from typing import Optional
from config import settings
import logging

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _get_all_paths() -> list[str]:
    """Returns deduplicated list of all configured dbt project root paths."""
    seen: set[str] = set()
    paths: list[str] = []

    if settings.dbt_project_paths:
        for p in settings.dbt_project_paths.split(","):
            p = p.strip()
            if p and p not in seen:
                paths.append(p)
                seen.add(p)

    # Legacy single path — used when dbt_project_paths is not set
    if not paths and settings.dbt_project_path:
        p = settings.dbt_project_path.strip()
        if p and p not in seen:
            paths.append(p)

    return paths


def _target_dirs() -> list[tuple[str, Path]]:
    """Returns list of (project_root, target_dir) for all valid configured projects."""
    result = []
    for root in _get_all_paths():
        target = Path(root) / "target"
        if target.exists():
            result.append((root, target))
        else:
            logger.warning(f"dbt target dir not found: {target}")
    return result


def _load_all(filename: str) -> list[tuple[str, dict]]:
    """Load a dbt artifact from every configured project. Returns (project_root, data) pairs."""
    result = []
    for root, target in _target_dirs():
        fp = target / filename
        if fp.exists():
            try:
                with open(fp) as f:
                    result.append((root, json.load(f)))
            except Exception as e:
                logger.warning(f"Failed to load {fp}: {e}")
        else:
            logger.warning(f"dbt artifact not found: {fp}")
    return result


def _load_first(filename: str) -> Optional[dict]:
    """Load artifact from the first project that has it (backward compat)."""
    loaded = _load_all(filename)
    return loaded[0][1] if loaded else None


# ---------------------------------------------------------------------------
# Public helpers
# ---------------------------------------------------------------------------

def is_configured() -> bool:
    return bool(_get_all_paths())


def get_all_projects_info() -> list[dict]:
    """Returns status info for every configured project."""
    results = []
    for root in _get_all_paths():
        target = Path(root) / "target"
        exists = target.exists()
        manifest = None
        if exists:
            fp = target / "manifest.json"
            if fp.exists():
                try:
                    with open(fp) as f:
                        manifest = json.load(f)
                except Exception:
                    pass

        project_name = None
        model_count = 0
        if manifest:
            project_name = manifest.get("metadata", {}).get("dbt_project_name")
            model_count = sum(
                1 for n in manifest.get("nodes", {}).values()
                if n.get("resource_type") == "model"
            )

        results.append({
            "path": root,
            "target_exists": exists,
            "project_name": project_name,
            "model_count": model_count,
            "configured": exists and manifest is not None,
        })
    return results


def get_project_name() -> Optional[str]:
    """Returns project name from the first configured project (backward compat)."""
    info = get_all_projects_info()
    return info[0]["project_name"] if info else None


def get_models() -> list[dict]:
    """Aggregates all dbt models across all configured projects."""
    models = []
    for root, data in _load_all("manifest.json"):
        nodes = data.get("nodes", {})
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
                "project_root": root,
            })
    return models


def get_tests() -> list[dict]:
    """Aggregates all dbt tests across all configured projects."""
    tests = []
    for root, data in _load_all("manifest.json"):
        nodes = data.get("nodes", {})
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
                "project_root": root,
            })
    return tests


def get_last_run_results() -> dict[str, dict]:
    """
    Merges run_results from all configured projects.
    Returns map of unique_id -> result dict.
    """
    merged: dict[str, dict] = {}
    for _root, data in _load_all("run_results.json"):
        for r in data.get("results", []):
            uid = r.get("unique_id")
            if uid:
                merged[uid] = {
                    "unique_id": uid,
                    "status": r.get("status"),
                    "execution_time": r.get("execution_time"),
                    "failures": r.get("failures"),
                    "message": r.get("message"),
                    "adapter_response": r.get("adapter_response", {}),
                }
    return merged


def get_model_lineage(model_unique_id: str) -> dict:
    """Returns upstream/downstream for a given model (searches all projects)."""
    for _root, data in _load_all("manifest.json"):
        nodes = data.get("nodes", {})
        if model_unique_id not in nodes:
            continue

        child_map = data.get("child_map", {})
        node = nodes[model_unique_id]
        upstream = node.get("depends_on", {}).get("nodes", [])
        downstream = [
            uid for uid, children in child_map.items()
            if model_unique_id in children
        ]

        def _label(uid: str) -> dict:
            n = nodes.get(uid, {})
            return {"unique_id": uid, "name": n.get("name", uid), "resource_type": n.get("resource_type")}

        return {
            "upstream": [_label(u) for u in upstream],
            "downstream": [_label(d) for d in downstream],
        }

    return {"upstream": [], "downstream": []}


def get_model_tests_with_meta(model_name: str) -> list[dict]:
    """
    Returns all tests attached to a model, enriched with classification.
    Searches all configured projects.
    - section: "dbt"    for generic/schema tests (not_null, unique, etc.)
    - section: "custom" for singular tests
    """
    result = []
    for _root, data in _load_all("manifest.json"):
        nodes = data.get("nodes", {})
        for uid, node in nodes.items():
            if node.get("resource_type") not in ("test", "generic_test", "singular_test"):
                continue
            if model_name not in uid:
                continue

            test_meta = node.get("test_metadata", {})
            test_type = test_meta.get("name") if test_meta else None
            section = "dbt" if test_meta else "custom"

            result.append({
                "unique_id": uid,
                "name": node.get("name", uid),
                "test_type": test_type or "custom",
                "column_name": node.get("column_name"),
                "section": section,
                "tags": node.get("tags", []),
            })
    return result


def get_model_test_results(model_name: str) -> list[dict]:
    """
    Returns test results for a specific model, combining manifest test definitions
    with the latest run_results. Searches all configured projects.
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
    """Returns catalog metadata for a model. Searches all configured projects."""
    for _root, data in _load_all("catalog.json"):
        nodes = data.get("nodes", {})
        for uid, node in nodes.items():
            if node.get("metadata", {}).get("name") == model_name:
                return node
    return None
