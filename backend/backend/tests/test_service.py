"""Service-layer tests: call app.service directly (no HTTP), including error
paths, job isolation, zip contents, and expiry cleanup."""
import time
import zipfile
from pathlib import Path

import pytest

from app import service

EXAMPLES = Path(__file__).resolve().parents[2] / "examples"


@pytest.fixture
def counter_rtl():
    return (EXAMPLES / "counter.v").read_text()


def test_validate_rtl_good(counter_rtl):
    result = service.validate_rtl(counter_rtl)
    assert result["ok"] is True
    assert result["module_name"] == "counter"


def test_validate_rtl_raises_core_error_on_bad_input():
    with pytest.raises(service.CoreError) as exc_info:
        service.validate_rtl("not verilog at all")
    assert exc_info.value.error_type == "AutoVerify::ParserError"


def test_generate_rtl_creates_isolated_job_dir(counter_rtl):
    record = service.generate_rtl(counter_rtl, {"num_txns": 10})
    assert record.outdir.exists()
    assert record.zip_path.exists()
    assert record.zip_path.suffix == ".zip"
    assert record.module_name == "counter"
    assert len(record.files) == 9


def test_generate_rtl_two_calls_produce_different_job_ids(counter_rtl):
    r1 = service.generate_rtl(counter_rtl)
    r2 = service.generate_rtl(counter_rtl)
    assert r1.job_id != r2.job_id
    assert r1.outdir != r2.outdir
    # both remain independently retrievable - no cross-contamination
    assert service.get_job(r1.job_id).module_name == "counter"
    assert service.get_job(r2.job_id).module_name == "counter"


def test_zip_contains_expected_files(counter_rtl):
    record = service.generate_rtl(counter_rtl)
    with zipfile.ZipFile(record.zip_path) as z:
        names = set(z.namelist())
    assert "run_sim.tcl" in names
    assert "Makefile" in names
    assert "README.md" in names
    for suffix in ("pkg", "if", "transaction", "driver", "monitor", "scoreboard", "env", "tb_top"):
        assert f"counter_{suffix}.sv" in names


def test_get_job_returns_none_for_unknown_id():
    assert service.get_job("no-such-job") is None


def test_cleanup_expired_jobs_removes_old_but_not_fresh(counter_rtl, monkeypatch):
    record = service.generate_rtl(counter_rtl)
    job_dir = service.JOBS_ROOT / record.job_id

    # simulate the job being old by rewinding its mtime, rather than sleeping
    old_time = time.time() - 999999
    import os
    os.utime(job_dir, (old_time, old_time))

    fresh = service.generate_rtl(counter_rtl)

    removed = service.cleanup_expired_jobs(ttl_seconds=3600)
    assert removed >= 1
    assert not job_dir.exists()
    assert (service.JOBS_ROOT / fresh.job_id).exists()


def test_bridge_execution_error_on_missing_perl(counter_rtl, monkeypatch):
    monkeypatch.setattr(service, "BRIDGE", Path("/nonexistent/bridge.pl"))
    with pytest.raises(service.BridgeExecutionError):
        service.validate_rtl(counter_rtl)
