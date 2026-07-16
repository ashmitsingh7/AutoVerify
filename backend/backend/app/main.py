"""
AutoVerify FastAPI backend.

Architecture reminder (per Phase 3 brief): this file must never contain
parser or generation logic. Every route calls into app.service, which in
turn shells out to bin/autoverify_bridge.pl (Perl) -> AutoVerify::Core.
This file's only job is: request validation, calling the service layer,
mapping Core/service exceptions to HTTP responses, and job/zip plumbing.
"""
from __future__ import annotations

import os

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse, PlainTextResponse

from . import service
from .models import (
    GenerateRequest, ValidateRequest, AnalyzeRequest, DownloadRequest,
    GenerateResponse, ValidateResponse, AnalyzeResponse, ErrorResponse,
)

app = FastAPI(
    title="AutoVerify API",
    description="HTTP service layer over AutoVerify Core (HDL testbench generator).",
    version="0.3.0",
)

# CORS: the frontend (Vercel in prod, localhost:3000 in dev) calls this API
# from the browser. Origins are configurable via env so this stays
# deployment-agnostic (per Step 9/10 of the integration brief) - no
# hardcoded hosts here beyond a localhost dev fallback.
_default_origins = "http://localhost:3000,http://127.0.0.1:3000"
_allowed_origins = [
    o.strip()
    for o in os.environ.get("AUTOVERIFY_ALLOWED_ORIGINS", _default_origins).split(",")
    if o.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _error_response(exc: Exception) -> JSONResponse:
    """Map a service/Core-layer exception to a structured (status, body) pair."""
    if isinstance(exc, service.CoreError):
        # ParserError / ValidationError mean the *input RTL* was the problem
        # - that's a client error (422 Unprocessable Entity), not a server fault.
        status = 422 if exc.error_type in ("AutoVerify::ParserError", "AutoVerify::ValidationError") else 500
        body = ErrorResponse(error_type=exc.error_type, message=exc.message,
                              file=exc.file, line=exc.line, column=exc.column,
                              suggestion=exc.suggestion)
        return JSONResponse(status_code=status, content=body.model_dump())

    if isinstance(exc, service.BridgeExecutionError):
        body = ErrorResponse(error_type="BridgeExecutionError", message=str(exc))
        return JSONResponse(status_code=500, content=body.model_dump())

    if isinstance(exc, FileExistsError):
        body = ErrorResponse(error_type="JobConflict", message=str(exc))
        return JSONResponse(status_code=500, content=body.model_dump())

    body = ErrorResponse(error_type=type(exc).__name__, message=str(exc))
    return JSONResponse(status_code=500, content=body.model_dump())


def _require_nonblank(rtl: str) -> None:
    if not rtl.strip():
        raise HTTPException(status_code=400, detail="rtl field is present but blank")


@app.get("/")
def root():
    return {"service": "AutoVerify API", "version": app.version, "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/validate", response_model=ValidateResponse, responses={422: {"model": ErrorResponse}})
def validate(req: ValidateRequest):
    _require_nonblank(req.rtl)
    try:
        result = service.validate_rtl(req.rtl)
    except Exception as exc:
        return _error_response(exc)
    return ValidateResponse(**result)


@app.post("/analyze", response_model=AnalyzeResponse, responses={422: {"model": ErrorResponse}})
def analyze(req: AnalyzeRequest):
    _require_nonblank(req.rtl)
    try:
        result = service.analyze_rtl(req.rtl)
    except Exception as exc:
        return _error_response(exc)
    return AnalyzeResponse(**result)


@app.post("/generate", response_model=GenerateResponse, responses={422: {"model": ErrorResponse}})
def generate(req: GenerateRequest):
    _require_nonblank(req.rtl)
    service.cleanup_expired_jobs()    # opportunistic sweep on write-path requests
    opts = req.options.model_dump(exclude_none=True) if req.options else {}
    try:
        record = service.generate_rtl(req.rtl, opts)
    except Exception as exc:
        return _error_response(exc)

    return GenerateResponse(
        job_id=record.job_id,
        module_name=record.module_name,
        files=record.files,
        num_files=len(record.files),
        diagnostics=record.diagnostics,
        download_url="/download",
        clk_port=record.clk_port,
        rst_port=record.rst_port,
    )


@app.post("/download", responses={404: {"model": ErrorResponse}})
def download(req: DownloadRequest):
    record = service.get_job(req.job_id)
    if record is None:
        raise HTTPException(status_code=404, detail=f"no such job: {req.job_id}")
    return FileResponse(
        path=record.zip_path,
        media_type="application/zip",
        filename=f"{record.module_name}.zip",
    )


@app.get("/jobs/{job_id}/files/{filename}", responses={404: {"model": ErrorResponse}})
def job_file(job_id: str, filename: str):
    """Read-only text preview of a single generated file (Output Explorer).
    Not a Core operation - just a guarded read of files service.py already
    wrote to disk during /generate."""
    text = service.get_job_file_text(job_id, filename)
    if text is None:
        raise HTTPException(status_code=404, detail=f"no such file: {filename}")
    return PlainTextResponse(text)
