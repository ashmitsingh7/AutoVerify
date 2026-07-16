import { ApiError, type ApiErrorBody } from '@/lib/types'

// No hardcoded localhost — falls back to it only for local dev convenience,
// matching the Dockerfile/DEPLOYMENT.md convention on the backend side.
const API_BASE = (process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000').replace(
  /\/+$/,
  '',
)

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  let res: Response
  try {
    res = await fetch(`${API_BASE}${path}`, {
      ...init,
      headers: { 'Content-Type': 'application/json', ...init?.headers },
    })
  } catch (err) {
    throw new ApiError(0, 'Could not reach the AutoVerify API. Is the backend running?')
  }

  if (!res.ok) {
    let body: ApiErrorBody | undefined
    try {
      body = (await res.json()) as ApiErrorBody
    } catch {
      // non-JSON error body (e.g. proxy 502) — fall through with no body
    }
    throw new ApiError(res.status, body?.message ?? `Request failed (${res.status})`, body)
  }

  return res.json() as Promise<T>
}

export function apiUrl(path: string): string {
  return `${API_BASE}${path}`
}

export { request, API_BASE }
