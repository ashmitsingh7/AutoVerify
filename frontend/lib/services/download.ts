import { API_BASE } from '@/lib/api'
import { ApiError } from '@/lib/types'

/** POST /download returns the zip bytes directly (FileResponse on the
 * backend), so this fetches the blob and triggers a browser save rather
 * than going through the shared JSON `request()` helper. */
export async function downloadJobZip(jobId: string, moduleName: string): Promise<void> {
  const res = await fetch(`${API_BASE}/download`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ job_id: jobId }),
  })
  if (!res.ok) {
    throw new ApiError(res.status, `Download failed (${res.status})`)
  }
  const blob = await res.blob()
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${moduleName}.zip`
  a.click()
  URL.revokeObjectURL(url)
}
