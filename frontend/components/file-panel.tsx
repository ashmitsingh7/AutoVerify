'use client'

import { ArrowLeft, Check, Download, FileCode, Loader2 } from 'lucide-react'
import { useEffect, useState } from 'react'
import { AvButton } from '@/components/av-button'
import { Divider } from '@/components/divider'
import { downloadJobZip } from '@/lib/services/download'
import { getGeneratedFileText } from '@/lib/services/generate'
import { cn } from '@/lib/utils'

interface FilePanelProps {
  jobId: string
  moduleName: string
  files: string[]
  activeFile: string
  onSelect: (name: string) => void
  onBack: () => void
}

export function FilePanel({
  jobId,
  moduleName,
  files,
  activeFile,
  onSelect,
  onBack,
}: FilePanelProps) {
  const [downloading, setDownloading] = useState(false)
  const [downloadError, setDownloadError] = useState<string | null>(null)

  async function handleDownload() {
    setDownloading(true)
    setDownloadError(null)
    try {
      await downloadJobZip(jobId, moduleName)
    } catch (err) {
      setDownloadError(err instanceof Error ? err.message : 'Download failed')
    } finally {
      setDownloading(false)
    }
  }

  return (
    <div className="animate-slide-in flex h-full flex-col">
      <div className="flex items-center justify-between">
        <button
          onClick={onBack}
          className="flex items-center gap-2 text-[13px] text-muted-foreground transition-colors hover:text-foreground"
        >
          <ArrowLeft className="size-4" />
          Back
        </button>
        <div className="flex items-center gap-2 text-[13px] text-[color:var(--success)]">
          <Check className="size-4" />
          Generated
        </div>
      </div>

      <div className="mt-8">
        <h2 className="text-2xl font-semibold tracking-tight text-foreground">
          Generated files
        </h2>
        <p className="mt-1 text-[15px] text-muted-foreground">
          {files.length} files · {moduleName}
        </p>
      </div>

      <div className="mt-6 flex-1 overflow-y-auto">
        <Divider />
        {files.map((name) => {
          const active = name === activeFile
          return (
            <button
              key={name}
              onClick={() => onSelect(name)}
              className={cn(
                'flex w-full items-center gap-3 border-b border-border py-3.5 text-left transition-colors',
                active ? 'text-foreground' : 'text-muted-foreground hover:text-foreground',
              )}
            >
              <FileCode
                className={cn(
                  'size-4 shrink-0',
                  active ? 'text-foreground' : 'text-muted-foreground',
                )}
              />
              <span className="font-mono text-[13px]">{name}</span>
              {active && <span className="ml-auto size-1.5 rounded-full bg-foreground" />}
            </button>
          )
        })}
      </div>

      <div className="mt-6">
        <AvButton
          size="lg"
          className="w-full"
          onClick={handleDownload}
          disabled={downloading}
        >
          {downloading ? <Loader2 className="animate-spin" /> : <Download />}
          {downloading ? 'Preparing…' : 'Download ZIP'}
        </AvButton>
        {downloadError && (
          <p className="mt-2 text-[13px] text-[color:var(--error)]">{downloadError}</p>
        )}
      </div>
    </div>
  )
}

/** Hook used by the Generate page to lazily fetch and cache the text of
 * whichever generated file is currently selected. Kept out of FilePanel
 * itself so the panel stays a pure list/selection component and the editor
 * pane (which actually renders the content) owns its own loading state. */
export function useGeneratedFileText(jobId: string | null, filename: string | null) {
  const [content, setContent] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!jobId || !filename) return
    let cancelled = false
    setLoading(true)
    setError(null)
    getGeneratedFileText(jobId, filename)
      .then((text) => {
        if (!cancelled) setContent(text)
      })
      .catch((err) => {
        if (!cancelled) setError(err instanceof Error ? err.message : 'Failed to load file')
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [jobId, filename])

  return { content, loading, error }
}
