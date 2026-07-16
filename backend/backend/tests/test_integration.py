"""Integration-style tests: concurrent requests and large RTL input.

Honest scope note: TestClient calls are synchronous/in-process, so this
doesn't prove behavior under real concurrent network load (no port binding,
no asyncio event loop contention) - what it DOES prove is that concurrent
job creation via a thread pool doesn't corrupt job directories or leak
state between jobs, which is the actual risk area (shared JOBS_ROOT,
uuid collisions, file handle reuse).
"""
import concurrent.futures
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


def _generate_once(rtl: str) -> dict:
    c = TestClient(app)
    r = c.post("/generate", json={"rtl": rtl})
    return r.json()


def test_concurrent_generate_requests_do_not_collide(counter_rtl):
    n = 12
    with concurrent.futures.ThreadPoolExecutor(max_workers=n) as pool:
        results = list(pool.map(_generate_once, [counter_rtl] * n))

    job_ids = [r["job_id"] for r in results]
    assert len(set(job_ids)) == n, "every concurrent request must get a unique job id"
    for r in results:
        assert r["ok"] is True
        assert r["module_name"] == "counter"

    # every job independently downloadable afterwards - no shared-state bleed
    c = TestClient(app)
    for jid in job_ids:
        d = c.post("/download", json={"job_id": jid})
        assert d.status_code == 200


def test_large_rtl_module_generates_successfully(client):
    # 200 ports (100 in, 100 out) - well beyond the 7-port shipped examples,
    # to exercise the parser/generator on something the size of a real
    # wide DUT rather than only the small fixtures.
    ins = ",\n    ".join(f"input logic [31:0] in_{i}" for i in range(100))
    outs = ",\n    ".join(f"output logic [31:0] out_{i}" for i in range(100))
    big_rtl = f"""
module wide_dut (
    input logic clk,
    input logic rst_n,
    {ins},
    {outs}
);
endmodule
"""
    r = client.post("/generate", json={"rtl": big_rtl, "options": {"num_txns": 5}})
    assert r.status_code == 200
    body = r.json()
    assert body["module_name"] == "wide_dut"
    assert body["num_files"] == 9

    d = client.post("/download", json={"job_id": body["job_id"]})
    assert d.status_code == 200
    assert len(d.content) > 0


def test_large_num_txns_is_accepted(client, counter_rtl):
    r = client.post("/generate", json={"rtl": counter_rtl, "options": {"num_txns": 100000}})
    assert r.status_code == 200


def test_num_txns_over_limit_is_rejected_by_pydantic(client, counter_rtl):
    r = client.post("/generate", json={"rtl": counter_rtl, "options": {"num_txns": 10_000_000}})
    assert r.status_code == 422
