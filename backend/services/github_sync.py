"""
GitHub repository sync service for dbt projects.

- Clones a GitHub repo on first add (shallow clone, depth=1)
- git-pulls periodically (every 30 min by default) to stay current
- Auto-discovers all dbt projects inside the repo (supports monorepos)
- Private repos: set GITHUB_TOKEN in backend/.env
"""

import subprocess
import logging
from pathlib import Path
from datetime import datetime

from database import SessionLocal
from models.monitor import DbtGithubRepo

logger = logging.getLogger(__name__)

REPOS_DIR = Path("./dbt_repos")


def _safe_dirname(repo_url: str) -> str:
    """Convert a GitHub URL to a safe directory name."""
    parts = repo_url.rstrip("/").split("/")
    name = "_".join(parts[-2:]) if len(parts) >= 2 else parts[-1]
    return "".join(c if c.isalnum() or c in "-_" else "_" for c in name)


def _auth_url(repo_url: str, token: str | None) -> str:
    """Inject a PAT into the HTTPS URL for authentication."""
    if token and repo_url.startswith("https://"):
        return repo_url.replace("https://", f"https://{token}@")
    return repo_url


def clone_or_pull(repo_url: str, branch: str, local_path: str, token: str | None = None) -> None:
    """Clone the repo if it doesn't exist locally, otherwise git-pull."""
    path = Path(local_path)
    REPOS_DIR.mkdir(parents=True, exist_ok=True)
    auth = _auth_url(repo_url, token)

    if not (path / ".git").exists():
        result = subprocess.run(
            ["git", "clone", "--depth=1", "--branch", branch, auth, str(path)],
            capture_output=True, text=True, timeout=180,
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "git clone failed")
    else:
        # Update remote URL (token may have changed), then fetch + reset
        subprocess.run(
            ["git", "-C", str(path), "remote", "set-url", "origin", auth],
            capture_output=True, timeout=30,
        )
        result = subprocess.run(
            ["git", "-C", str(path), "fetch", "--depth=1", "origin", branch],
            capture_output=True, text=True, timeout=120,
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "git fetch failed")
        subprocess.run(
            ["git", "-C", str(path), "reset", "--hard", f"origin/{branch}"],
            capture_output=True, timeout=30,
        )


def find_dbt_projects(local_path: str) -> list[str]:
    """Return absolute paths of all dbt project roots within a cloned repo."""
    base = Path(local_path)
    return sorted(str(p.parent) for p in base.rglob("dbt_project.yml"))


def sync_repo(repo_id: int) -> dict:
    """Clone/pull a single repo by DB id. Returns status dict."""
    from config import settings
    db = SessionLocal()
    repo = None
    try:
        repo = db.query(DbtGithubRepo).filter(DbtGithubRepo.id == repo_id).first()
        if not repo:
            return {"ok": False, "error": "Repo not found"}

        repo.sync_status = "syncing"
        db.commit()

        clone_or_pull(repo.repo_url, repo.branch, repo.local_path, settings.github_token)

        projects = find_dbt_projects(repo.local_path)
        repo.last_synced_at = datetime.utcnow()
        repo.sync_status = "ok"
        repo.sync_error = None
        db.commit()

        logger.info(
            f"github_sync: synced {repo.repo_url} — "
            f"found {len(projects)} dbt project(s): {projects}"
        )
        return {"ok": True, "projects": projects, "project_count": len(projects)}

    except Exception as e:
        logger.error(f"github_sync: failed repo {repo_id}: {e}")
        if repo:
            repo.sync_status = "error"
            repo.sync_error = str(e)
            db.commit()
        return {"ok": False, "error": str(e)}
    finally:
        db.close()


def sync_all_repos():
    """APScheduler job — pulls every configured repo."""
    db = SessionLocal()
    try:
        repo_ids = [r.id for r in db.query(DbtGithubRepo).all()]
    finally:
        db.close()

    for rid in repo_ids:
        try:
            sync_repo(rid)
        except Exception as e:
            logger.error(f"github_sync: error in sync loop for repo {rid}: {e}")


def get_all_project_paths_from_repos() -> list[str]:
    """Returns all dbt project paths found across all successfully synced repos."""
    db = SessionLocal()
    try:
        repos = db.query(DbtGithubRepo).filter(DbtGithubRepo.sync_status == "ok").all()
        paths: list[str] = []
        for repo in repos:
            if repo.local_path:
                paths.extend(find_dbt_projects(repo.local_path))
        return paths
    finally:
        db.close()


def start_github_sync_watcher(scheduler, interval_minutes: int = 30):
    scheduler.add_job(
        sync_all_repos,
        trigger="interval",
        minutes=interval_minutes,
        id="github_sync_watcher",
        replace_existing=True,
    )
    logger.info(f"github_sync: watcher started (every {interval_minutes} min)")
