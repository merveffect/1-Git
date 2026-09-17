"""Telefondan kullanılan FastAPI sunucusu.

Çalıştırma:
    python -m doctolib_agent.web.app --host 0.0.0.0 --port 8600

Ağa açıyorsan DOCTOLIB_WEB_TOKEN tanımla - bu sunucu senin Doctolib
oturumunu tutuyor.
"""
from __future__ import annotations

import os
import secrets
from pathlib import Path
from typing import Optional

from fastapi import Depends, FastAPI, HTTPException, Query, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

from ..config import AgentConfig
from .jobs import JobRunner

STATIC_DIR = Path(__file__).parent / "static"
LOCAL_HOSTS = {"127.0.0.1", "::1", "localhost", "testclient"}


class SearchRequest(BaseModel):
    text: str = Field(min_length=3, max_length=2000)


class BookRequest(BaseModel):
    slot_key: str = Field(min_length=1, max_length=500)


def create_app(config_path: str = "doctolib.yaml") -> FastAPI:
    cfg = AgentConfig.load(config_path)
    runner = JobRunner(cfg)
    token = os.environ.get("DOCTOLIB_WEB_TOKEN", "").strip()

    app = FastAPI(title="Doctolib Randevu Agent'ı", docs_url=None, redoc_url=None)
    app.state.cfg = cfg
    app.state.runner = runner
    app.state.token = token

    def require_auth(request: Request, t: Optional[str] = Query(None, alias="token")) -> None:
        """Token tanımlıysa her istekte iste; tanımlı değilse sadece localhost'a izin ver."""
        if token:
            supplied = request.headers.get("x-token") or t or ""
            if not secrets.compare_digest(supplied, token):
                raise HTTPException(status_code=401, detail="Geçersiz veya eksik token.")
            return
        host = request.client.host if request.client else ""
        if host not in LOCAL_HOSTS:
            raise HTTPException(
                status_code=403,
                detail="Uzaktan erişim için DOCTOLIB_WEB_TOKEN tanımlanmalı.",
            )

    @app.get("/api/config")
    def get_config(_: None = Depends(require_auth)) -> dict:
        return {
            "country": cfg.country,
            "location": cfg.location,
            "location_label": cfg.location_label or cfg.location,
            "booking_mode": cfg.booking.mode,
            "horizon_days": cfg.scan.horizon_days,
            "server_booking": cfg.booking.mode == "auto",
        }

    @app.post("/api/search")
    def start_search(body: SearchRequest, _: None = Depends(require_auth)) -> dict:
        job = runner.submit(body.text)
        return {"job_id": job.id, "status": job.status}

    @app.get("/api/jobs")
    def list_jobs(_: None = Depends(require_auth)) -> dict:
        return {
            "jobs": [
                {
                    "id": j.id,
                    "text": j.text,
                    "status": j.status,
                    "created_at": j.created_at.isoformat(timespec="seconds"),
                    "slot_count": len(j.slots),
                }
                for j in runner.recent()
            ]
        }

    @app.get("/api/jobs/{job_id}")
    def get_job(job_id: str, _: None = Depends(require_auth)) -> dict:
        job = runner.get(job_id)
        if job is None:
            raise HTTPException(status_code=404, detail="İş bulunamadı.")
        return job.to_dict()

    @app.post("/api/jobs/{job_id}/book")
    def book(job_id: str, body: BookRequest, _: None = Depends(require_auth)) -> JSONResponse:
        ok, message = runner.book(job_id, body.slot_key)
        return JSONResponse({"ok": ok, "message": message}, status_code=200 if ok else 409)

    @app.get("/healthz")
    def healthz() -> dict:
        return {"ok": True}

    @app.get("/")
    def index() -> FileResponse:
        return FileResponse(STATIC_DIR / "index.html")

    app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
    return app


def main(argv: list[str] | None = None) -> int:
    import argparse

    import uvicorn

    parser = argparse.ArgumentParser(prog="doctolib-agent-web")
    parser.add_argument("-c", "--config", default="doctolib.yaml")
    parser.add_argument("--host", default="127.0.0.1", help="Telefondan erişim için 0.0.0.0")
    parser.add_argument("--port", type=int, default=8600)
    args = parser.parse_args(argv)

    token = os.environ.get("DOCTOLIB_WEB_TOKEN", "").strip()
    if args.host not in ("127.0.0.1", "localhost") and not token:
        print(
            "DOCTOLIB_WEB_TOKEN tanımlı değil ve sunucu ağa açılıyor.\n"
            "Bu sunucu Doctolib oturumunu tutuyor - token olmadan uzak istekler reddedilecek.\n"
            "  export DOCTOLIB_WEB_TOKEN=$(python -c 'import secrets;print(secrets.token_urlsafe(24))')",
        )

    uvicorn.run(create_app(args.config), host=args.host, port=args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
