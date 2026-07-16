import { AlertCircle } from 'lucide-react'
import { ApiError } from '@/lib/types'

export function ErrorPanel({ error }: { error: unknown }) {
  const isApiError = error instanceof ApiError
  const message = error instanceof Error ? error.message : 'Something went wrong'
  const body = isApiError ? error.body : undefined

  return (
    <div className="rounded-lg border border-[color:var(--error)]/30 bg-[color:var(--error)]/5 px-4 py-3">
      <div className="flex items-start gap-2.5">
        <AlertCircle className="mt-0.5 size-4 shrink-0 text-[color:var(--error)]" />
        <div className="min-w-0 flex-1">
          <p className="text-[13px] text-foreground">{message}</p>
          {body?.file && (
            <p className="mt-1 font-mono text-[12px] text-muted-foreground">
              {body.file}
              {body.line != null ? `:${body.line}` : ''}
              {body.column != null ? `:${body.column}` : ''}
            </p>
          )}
          {body?.suggestion && (
            <p className="mt-1.5 text-[12px] text-muted-foreground">{body.suggestion}</p>
          )}
        </div>
      </div>
    </div>
  )
}
