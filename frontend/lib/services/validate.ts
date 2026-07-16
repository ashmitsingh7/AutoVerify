import { request } from '@/lib/api'
import type { ValidateResponse } from '@/lib/types'

export function validateRtl(rtl: string): Promise<ValidateResponse> {
  return request<ValidateResponse>('/validate', {
    method: 'POST',
    body: JSON.stringify({ rtl }),
  })
}
