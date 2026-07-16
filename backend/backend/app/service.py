"""
autoverify_service.py - orchestration layer between FastAPI and AutoVerify Core.

Responsibilities (and ONLY these - no parsing/generation logic here):
  - receive RTL text, write it to a job-scoped temp file
  - validate input by shelling out to the Perl bridge (validate command)
  - call the Perl bridge's generate command
  - manage per-job working directories under a UUID
  - package generated output + run_sim.tcl + Makefile + README into a zip
  - expire/clean up old job directories

Every Core interaction goes through bin/autoverify_bridge.pl via subprocess.
This module never imports or reimplements parsing/codegen logic.
"""
from __future__ import annotations

import json
import shutil
import subprocess
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

CORE_ROOT = Path(__file__).resolve().parents[2]          # .../autoverify
BRIDGE = CORE_ROOT / "bin" / "autoverify_bridge.pl"
RUN_SIM_TCL = CORE_ROOT / "run_sim.tcl"
MAKEFILE = CORE_ROOT / "Makefile"

JOBS_ROOT = Path(__file__).resolve().parent / "jobs"
JOBS_ROOT.mkdir(parents=True, exist_ok=True)

JOB_TTL_SECONDS = 60 * 60    # 1 hour - matches "automatically clean up expired jobs"


class CoreError(Exception):
    """Raised when the Perl bridge reports ok=false. Carries the structured
    fields the bridge returned, so the API layer can map error_type -> HTTP status
    without needing to know anything about Core internals."""

    def __init__(self, error_type: str, message: str, file: Optional[str] = None,
                 line: Optional[int] = None, column: Optional[int] = None,
                 suggestion: Optional[str] = None):
        super().__init__(message)
        self.error_type = error_type
        self.message = message
        self.file = file
        self.line = line
        self.column = column
        self.suggestion = suggestion

    def to_dict(self) -> dict:
        return {
            "error_type": self.error_type,
            "message": self.message,
            "file": self.file,
            "line": self.line,
            "column": self.column,
            "suggestion": self.suggestion,
        }


class BridgeExecutionError(Exception):
    """The bridge process itself failed to run (not a Core-level error) -
    e.g. perl not on PATH, bridge script missing. Always a 500."""
    pass


def _run_bridge(args: list[str]) -> dict:
    if not BRIDGE.exists():
        raise BridgeExecutionError(f"bridge script not found at {BRIDGE}")
    try:
        proc = subprocess.run(
            ["perl", str(BRIDGE), *args],
            capture_output=True, text=True, timeout=30,
        )
    except subprocess.TimeoutExpired as e:
        raise BridgeExecutionError(f"bridge timed out: {e}") from e
    except FileNotFoundError as e:
        raise BridgeExecutionError(f"perl not found on PATH: {e}") from e

    if proc.returncode != 0:
        raise BridgeExecutionError(
            f"bridge exited {proc.returncode}, stderr: {proc.stderr.strip()[:2000]}"
        )
    try:
        result = json.loads(proc.stdout.strip().splitlines()[-1])
    except (json.JSONDecodeError, IndexError) as e:
        raise BridgeExecutionError(f"bridge produced non-JSON output: {proc.stdout!r}") from e

    if not result.get("ok"):
        raise CoreError(
            error_type=result.get("error_type", "UnknownError"),
            message=result.get("message", "unknown Core error"),
            file=result.get("file"), line=result.get("line"),
            column=result.get("column"), suggestion=result.get("suggestion"),
        )
    return result


@dataclass
class JobRecord:
    job_id: str
    module_name: str
    outdir: Path
    zip_path: Path
    created_at: float
    files: list[str] = field(default_factory=list)
    diagnostics: list[dict] = field(default_factory=list)
    clk_port: Optional[str] = None
    rst_port: Optional[str] = None


def new_job_id() -> str:
    return str(uuid.uuid4())


def _job_dir(job_id: str) -> Path:
    d = JOBS_ROOT / job_id
    if d.exists():
        # "never overwrite existing jobs" - job_id is a fresh uuid4 per call,
        # so collision would indicate a caller reusing an id; refuse instead
        # of silently clobbering prior output.
        raise FileExistsError(f"job directory already exists: {job_id}")
    d.mkdir(parents=True)
    return d


def validate_rtl(rtl_text: str) -> dict:
    """Write RTL to a scratch file and run the Core's validate path.
    Does not create a persistent job - this is a read-only check."""
    scratch = JOBS_ROOT / f".scratch-{uuid.uuid4()}.v"
    try:
        scratch.write_text(rtl_text)
        return _run_bridge(["validate", str(scratch)])
    finally:
        scratch.unlink(missing_ok=True)


def analyze_rtl(rtl_text: str) -> dict:
    """Same underlying call as validate - 'analyze' is validate's data framed
    as a read-only inspection (module/ports/params) for a caller that wants
    structure without diagnostics being the headline. No separate Core logic."""
    return validate_rtl(rtl_text)


def generate_rtl(rtl_text: str, opts: Optional[dict] = None) -> JobRecord:
    """Full pipeline: new job dir -> write RTL -> Core generate -> zip package."""
    job_id = new_job_id()
    job_dir = _job_dir(job_id)

    src_file = job_dir / "input.v"
    src_file.write_text(rtl_text)

    opts_json = json.dumps(opts or {})
    gen_outdir = job_dir / "generated"
    result = _run_bridge(["generate", str(src_file), str(gen_outdir), opts_json])

    module_name = result["module_name"]
    zip_path = _package_zip(job_dir, gen_outdir, module_name)

    record = JobRecord(
        job_id=job_id,
        module_name=module_name,
        outdir=gen_outdir,
        zip_path=zip_path,
        created_at=time.time(),
        files=result["files"],
        diagnostics=result.get("diagnostics", []),
        clk_port=result.get("clk_port"),
        rst_port=result.get("rst_port"),
    )
    (job_dir / "record.json").write_text(json.dumps({
        "job_id": job_id, "module_name": module_name,
        "files": result["files"], "diagnostics": result.get("diagnostics", []),
        "created_at": record.created_at,
        "clk_port": result.get("clk_port"), "rst_port": result.get("rst_port"),
    }))
    return record


def _package_zip(job_dir: Path, gen_outdir: Path, module_name: str) -> Path:
    """Bundle generated .sv files + run_sim.tcl + Makefile + a README into
    <module_name>.zip inside the job directory."""
    bundle_dir = job_dir / "bundle"
    bundle_dir.mkdir(exist_ok=True)

    for f in gen_outdir.iterdir():
        shutil.copy2(f, bundle_dir / f.name)
    if RUN_SIM_TCL.exists():
        shutil.copy2(RUN_SIM_TCL, bundle_dir / "run_sim.tcl")
    if MAKEFILE.exists():
        shutil.copy2(MAKEFILE, bundle_dir / "Makefile")

    (bundle_dir / "README.md").write_text(
        f"# {module_name} - generated testbench\n\n"
        f"Generated by AutoVerify from a single RTL module.\n\n"
        f"## Files\n\n"
        + "\n".join(f"- `{f.name}`" for f in sorted(bundle_dir.iterdir()) if f.name != "README.md")
        + "\n\n## Next step\n\n"
        f"Edit `{module_name}_scoreboard.sv`'s `check_result()` with a real reference model, "
        f"then `make sim MODULE={module_name} DUT=path/to/{module_name}.v GEN_DIR=.` "
        f"(requires a SystemVerilog-2012+ simulator - not run as part of generation).\n"
    )

    zip_base = job_dir / module_name
    zip_path = shutil.make_archive(str(zip_base), "zip", root_dir=bundle_dir)
    return Path(zip_path)


def get_job(job_id: str) -> Optional[JobRecord]:
    job_dir = JOBS_ROOT / job_id
    record_file = job_dir / "record.json"
    if not record_file.exists():
        return None
    data = json.loads(record_file.read_text())
    zip_path = job_dir / f"{data['module_name']}.zip"
    if not zip_path.exists():
        return None
    return JobRecord(
        job_id=data["job_id"], module_name=data["module_name"],
        outdir=job_dir / "generated", zip_path=zip_path,
        created_at=data["created_at"], files=data["files"],
        diagnostics=data["diagnostics"],
        clk_port=data.get("clk_port"), rst_port=data.get("rst_port"),
    )


def get_job_file_text(job_id: str, filename: str) -> Optional[str]:
    """Read one generated file's text for preview purposes. Returns None if
    the job or file doesn't exist. Guards against path traversal since
    filename ultimately comes from an HTTP request."""
    record = get_job(job_id)
    if record is None:
        return None
    if "/" in filename or "\\" in filename or filename in (".", ".."):
        return None
    target = (record.outdir / filename).resolve()
    try:
        target.relative_to(record.outdir.resolve())
    except ValueError:
        return None
    if not target.is_file():
        return None
    return target.read_text()


def cleanup_expired_jobs(ttl_seconds: int = JOB_TTL_SECONDS) -> int:
    """Remove job directories older than ttl_seconds. Returns count removed.
    Called opportunistically (see app startup / a request hook) rather than
    via a background scheduler, to keep the service dependency-free."""
    now = time.time()
    removed = 0
    for d in JOBS_ROOT.iterdir():
        if not d.is_dir():
            continue
        try:
            age = now - d.stat().st_mtime
        except FileNotFoundError:
            continue
        if age > ttl_seconds:
            shutil.rmtree(d, ignore_errors=True)
            removed += 1
    return removed
