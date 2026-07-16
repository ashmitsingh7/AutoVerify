import { API_BASE, request } from '@/lib/api'
import type { GenerateOptions, GenerateResponse } from '@/lib/types'

export function generateRtl(
  rtl: string,
  options?: GenerateOptions,
): Promise<GenerateResponse> {
  return request<GenerateResponse>('/generate', {
    method: 'POST',
    body: JSON.stringify({ rtl, options }),
  })
}

/** Text preview of one generated file — GET /jobs/{job_id}/files/{filename}.
 * Returns plain text, not JSON, so this bypasses the shared `request()`
 * JSON parsing. */
export async function getGeneratedFileText(
  jobId: string,
  filename: string,
): Promise<string> {
  const res = await fetch(
    `${API_BASE}/jobs/${encodeURIComponent(jobId)}/files/${encodeURIComponent(filename)}`,
  )
  if (!res.ok) {
    throw new Error(`Could not load ${filename} (${res.status})`)
  }
  return res.text()
}
