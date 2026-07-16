import { request } from '@/lib/api'
import type { AnalyzeResponse } from '@/lib/types'

export function analyzeRtl(rtl: string): Promise<AnalyzeResponse> {
  return request<AnalyzeResponse>('/analyze', {
    method: 'POST',
    body: JSON.stringify({ rtl }),
  })
}
