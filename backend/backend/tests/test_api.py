"""API tests - exercise every route through FastAPI's TestClient."""
import zipfile
import io
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.main import app

EXAMPLES = Path(__file__).resolve().parents[2] / "examples"


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def counter_rtl():
    return (EXAMPLES / "counter.v").read_text()


@pytest.fixture
def fifo_rtl():
    return (EXAMPLES / "fifo_sync.v").read_text()


def test_root(client):
    r = client.get("/")
    assert r.status_code == 200
    assert r.json()["service"] == "AutoVerify API"


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_validate_good_rtl(client, counter_rtl):
    r = client.post("/validate", json={"rtl": counter_rtl})
    assert r.status_code == 200
    body = r.json()
    assert body["module_name"] == "counter"
    assert body["param_order"] == ["WIDTH"]
    assert body["diagnostics"] == []


def test_analyze_matches_validate_shape(client, counter_rtl):
    r = client.post("/analyze", json={"rtl": counter_rtl})
    assert r.status_code == 200
    assert r.json()["module_name"] == "counter"


def test_validate_invalid_rtl_is_422(client):
    r = client.post("/validate", json={"rtl": "totally not verilog"})
    assert r.status_code == 422
    body = r.json()
    assert body["ok"] is False
    assert body["error_type"] == "AutoVerify::ParserError"
    assert body["suggestion"]


def test_validate_blank_rtl_is_400(client):
    r = client.post("/validate", json={"rtl": "   \n  "})
    assert r.status_code == 400


def test_validate_missing_field_is_422_from_pydantic(client):
    r = client.post("/validate", json={})
    assert r.status_code == 422


def test_generate_then_download_roundtrip(client, counter_rtl):
    r = client.post("/generate", json={"rtl": counter_rtl, "options": {"num_txns": 20}})
    assert r.status_code == 200
    body = r.json()
    assert body["module_name"] == "counter"
    assert body["num_files"] == 9
    job_id = body["job_id"]

    r2 = client.post("/download", json={"job_id": job_id})
    assert r2.status_code == 200
    assert r2.headers["content-type"] == "application/zip"

    z = zipfile.ZipFile(io.BytesIO(r2.content))
    names = set(z.namelist())
    assert "run_sim.tcl" in names
    assert "Makefile" in names
    assert "README.md" in names
    assert "counter_scoreboard.sv" in names


def test_generate_fifo_sync_no_params(client, fifo_rtl):
    r = client.post("/generate", json={"rtl": fifo_rtl})
    assert r.status_code == 200
    assert r.json()["module_name"] == "fifo_sync"


def test_generate_invalid_rtl_is_422_not_500(client):
    r = client.post("/generate", json={"rtl": "module m ();"})
    assert r.status_code == 422
    assert r.json()["error_type"] == "AutoVerify::ParserError"


def test_download_unknown_job_is_404(client):
    r = client.post("/download", json={"job_id": "00000000-0000-0000-0000-000000000000"})
    assert r.status_code == 404


def test_two_jobs_from_same_rtl_get_distinct_ids_and_dont_collide(client, counter_rtl):
    r1 = client.post("/generate", json={"rtl": counter_rtl})
    r2 = client.post("/generate", json={"rtl": counter_rtl})
    id1, id2 = r1.json()["job_id"], r2.json()["job_id"]
    assert id1 != id2
    d1 = client.post("/download", json={"job_id": id1})
    d2 = client.post("/download", json={"job_id": id2})
    assert d1.status_code == 200
    assert d2.status_code == 200
