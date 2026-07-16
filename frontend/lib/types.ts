// Mirrors backend/app/models.py. Kept as a hand-written mirror rather than
// codegen since the API surface is small and stable — if it drifts, the
// fetch calls in lib/api.ts will fail loudly against the real backend.

export interface PortInfo {
  name: string
  dir: 'input' | 'output' | 'inout' | string
  type: string
  width: string
  signed: string
}

export interface Diagnostic {
  severity: 'error' | 'warning' | 'info' | string
  code: string
  message: string
}

export interface ValidateResponse {
  ok: true
  module_name: string
  param_order: string[]
  param_default: Record<string, string>
  ports: PortInfo[]
  diagnostics: Diagnostic[]
}

export type AnalyzeResponse = ValidateResponse

export interface GenerateOptions {
  clk?: string
  rst?: string
  rst_active_low?: boolean
  num_txns?: number
}

export interface GenerateResponse {
  ok: true
  job_id: string
  module_name: string
  files: string[]
  num_files: number
  diagnostics: Diagnostic[]
  download_url: string
  clk_port?: string | null
  rst_port?: string | null
}

export interface ApiErrorBody {
  ok: false
  error_type: string
  message: string
  file?: string | null
  line?: number | null
  column?: number | null
  suggestion?: string | null
}

/** Thrown by lib/api.ts whenever the backend responds with a non-2xx status
 * or a network-level failure. Carries the structured error body when the
 * backend returned one (422 CoreError, etc.) so the UI can show module
 * name / line / suggestion instead of a raw message. */
export class ApiError extends Error {
  readonly status: number
  readonly body?: ApiErrorBody

  constructor(status: number, message: string, body?: ApiErrorBody) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.body = body
  }
}
