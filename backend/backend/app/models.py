"""Pydantic models for the AutoVerify API."""
from __future__ import annotations

from typing import Optional
from pydantic import BaseModel, Field


class GenerateOptions(BaseModel):
    clk: Optional[str] = Field(None, description="Force clock port name (auto-detected otherwise)")
    rst: Optional[str] = Field(None, description="Force reset port name (auto-detected otherwise)")
    rst_active_low: Optional[bool] = Field(None, description="Override auto-detected reset polarity")
    num_txns: Optional[int] = Field(100, ge=1, le=1_000_000, description="Number of random transactions")


class GenerateRequest(BaseModel):
    rtl: str = Field(..., min_length=1, description="Verilog/SystemVerilog source text (ANSI-style module header)")
    options: Optional[GenerateOptions] = None


class ValidateRequest(BaseModel):
    rtl: str = Field(..., min_length=1, description="Verilog/SystemVerilog source text to validate")


class AnalyzeRequest(BaseModel):
    rtl: str = Field(..., min_length=1, description="Verilog/SystemVerilog source text to analyze")


class DownloadRequest(BaseModel):
    job_id: str = Field(..., description="UUID returned by a prior /generate call")


class PortInfo(BaseModel):
    name: str
    dir: str
    type: str
    width: str
    signed: str


class Diagnostic(BaseModel):
    severity: str
    code: str
    message: str


class ValidateResponse(BaseModel):
    ok: bool = True
    module_name: str
    param_order: list[str]
    param_default: dict[str, str]
    ports: list[PortInfo]
    diagnostics: list[Diagnostic]


class AnalyzeResponse(ValidateResponse):
    pass


class GenerateResponse(BaseModel):
    ok: bool = True
    job_id: str
    module_name: str
    files: list[str]
    num_files: int
    diagnostics: list[Diagnostic]
    download_url: str
    clk_port: Optional[str] = None
    rst_port: Optional[str] = None


class ErrorResponse(BaseModel):
    ok: bool = False
    error_type: str
    message: str
    file: Optional[str] = None
    line: Optional[int] = None
    column: Optional[int] = None
    suggestion: Optional[str] = None
