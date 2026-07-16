'use client'

import { useEffect, useRef, useState } from 'react'
import { AvButton } from '@/components/av-button'
import { CodeEditor } from '@/components/editor'
import { ErrorPanel } from '@/components/error-panel'
import { FilePanel, useGeneratedFileText } from '@/components/file-panel'
import { GenerationPipeline } from '@/components/generation-pipeline'
import { StatusRow } from '@/components/status-row'
import { generateRtl } from '@/lib/services/generate'
import { validateRtl } from '@/lib/services/validate'
import { EXAMPLE_VERILOG } from '@/lib/sample'
import type { GenerateResponse, ValidateResponse } from '@/lib/types'
import { cn } from '@/lib/utils'

type Mode = 'edit' | 'generated'
const VALIDATE_DEBOUNCE_MS = 500

export default function GeneratePage() {
  const [code, setCode] = useState(EXAMPLE_VERILOG)
  const [mode, setMode] = useState<Mode>('edit')

  const [validateResult, setValidateResult] = useState<ValidateResponse | null>(null)
  const [validating, setValidating] = useState(false)
  const [validateError, setValidateError] = useState<unknown>(null)

  const [generating, setGenerating] = useState(false)
  const [generateResult, setGenerateResult] = useState<GenerateResponse | null>(null)
  const [generateError, setGenerateError] = useState<unknown>(null)

  const [activeFile, setActiveFile] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const { content: activeContent, loading: fileLoading } = useGeneratedFileText(
    generateResult?.job_id ?? null,
    mode === 'generated' ? activeFile : null,
  )

  // Debounced /validate as the user edits — this is the only source of the
  // pre-generation summary (module/ports/params/diagnostics); the backend
  // doesn't compute clock/reset until /generate actually classifies ports.
  useEffect(() => {
    if (mode !== 'edit') return
    if (!code.trim()) {
      setValidateResult(null)
      setValidateError(null)
      return
    }
    setValidating(true)
    const id = setTimeout(() => {
      validateRtl(code)
        .then((res) => {
          setValidateResult(res)
          setValidateError(null)
        })
        .catch((err) => {
          setValidateResult(null)
          setValidateError(err)
        })
        .finally(() => setValidating(false))
    }, VALIDATE_DEBOUNCE_MS)
    return () => clearTimeout(id)
  }, [code, mode])

  async function handleGenerate() {
    setGenerating(true)
    setGenerateError(null)
    try {
      const result = await generateRtl(code)
      setGenerateResult(result)
      setActiveFile(result.files[0] ?? null)
      setMode('generated')
    } catch (err) {
      setGenerateError(err)
    } finally {
      setGenerating(false)
    }
  }

  function handleUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = () => setCode(String(reader.result))
    reader.readAsText(file)
  }

  const hasErrorDiagnostics = validateResult?.diagnostics.some((d) => d.severity === 'error')
  const inputs = validateResult?.ports.filter((p) => p.dir === 'input').length ?? 0
  const outputs = validateResult?.ports.filter((p) => p.dir === 'output').length ?? 0

  return (
    <main className="mx-auto h-[calc(100dvh-4rem)] max-w-[1200px] px-6 py-6">
      <div className="grid h-full grid-cols-1 gap-6 lg:grid-cols-[1.4fr_1fr]">
        {/* LEFT — editor */}
        <div className="relative flex min-h-[360px] flex-col overflow-hidden rounded-xl border border-border bg-background">
          <div className="flex items-center justify-between px-4 py-3">
            <span className="font-mono text-[12px] text-muted-foreground">
              {mode === 'generated' ? activeFile : validateResult?.module_name ?? 'untitled.sv'}
            </span>
            {mode === 'edit' && (
              <div className="flex items-center gap-1">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept=".sv,.v,.svh"
                  onChange={handleUpload}
                  className="hidden"
                />
                <AvButton variant="ghost" size="sm" onClick={() => fileInputRef.current?.click()}>
                  Upload
                </AvButton>
                <AvButton variant="ghost" size="sm" onClick={() => setCode(EXAMPLE_VERILOG)}>
                  Example
                </AvButton>
                <AvButton variant="ghost" size="sm" onClick={() => setCode('')}>
                  Clear
                </AvButton>
              </div>
            )}
          </div>
          <div className="flex-1">
            {mode === 'generated' && fileLoading ? (
              <div className="flex h-full items-center justify-center text-[13px] text-muted-foreground">
                Loading file…
              </div>
            ) : (
              <CodeEditor
                key={mode === 'generated' ? activeFile ?? 'generated' : 'editor'}
                value={mode === 'generated' ? activeContent : code}
                onChange={setCode}
                readOnly={mode === 'generated'}
              />
            )}
          </div>
        </div>

        {/* RIGHT — summary or file panel */}
        <div className="flex min-h-[360px] flex-col rounded-xl border border-border bg-card px-7 py-7">
          {mode === 'edit' ? (
            <div className="flex h-full flex-col">
              <div className="flex-1">
                {generating && (
                  <div className="mb-6">
                    <GenerationPipeline active={generating} />
                  </div>
                )}
                {validateError ? (
                  <ErrorPanel error={validateError} />
                ) : validateResult ? (
                  <>
                    <StatusRow label="Module" value={validateResult.module_name} mono />
                    <StatusRow label="Inputs" value={inputs} />
                    <StatusRow label="Outputs" value={outputs} />
                    <StatusRow label="Parameters" value={validateResult.param_order.length} />
                    <StatusRow
                      label="Validation"
                      value={
                        <span
                          className={cn(
                            'inline-flex items-center gap-1.5',
                            hasErrorDiagnostics
                              ? 'text-[color:var(--error)]'
                              : 'text-[color:var(--success)]',
                          )}
                        >
                          <span className="text-base leading-none">
                            {hasErrorDiagnostics ? '✕' : '✓'}
                          </span>
                          {hasErrorDiagnostics ? 'Failed' : 'Passed'}
                        </span>
                      }
                    />
                    {validateResult.diagnostics.length > 0 && (
                      <div className="mt-4 space-y-2">
                        {validateResult.diagnostics.map((d, i) => (
                          <p
                            key={i}
                            className={cn(
                              'text-[12px]',
                              d.severity === 'error'
                                ? 'text-[color:var(--error)]'
                                : 'text-muted-foreground',
                            )}
                          >
                            [{d.code}] {d.message}
                          </p>
                        ))}
                      </div>
                    )}
                  </>
                ) : (
                  <p className="text-[13px] text-muted-foreground">
                    {validating ? 'Validating…' : 'Paste or upload a module to begin.'}
                  </p>
                )}
                {generateError != null && (
                  <div className="mt-4">
                    <ErrorPanel error={generateError} />
                  </div>
                )}
              </div>
              <AvButton
                size="lg"
                className="mt-6 w-full"
                onClick={handleGenerate}
                disabled={
                  generating || code.trim().length === 0 || Boolean(hasErrorDiagnostics)
                }
              >
                {generating ? 'Generating…' : 'Generate'}
              </AvButton>
            </div>
          ) : generateResult && activeFile ? (
            <FilePanel
              jobId={generateResult.job_id}
              moduleName={generateResult.module_name}
              files={generateResult.files}
              activeFile={activeFile}
              onSelect={setActiveFile}
              onBack={() => setMode('edit')}
            />
          ) : null}
        </div>
      </div>
    </main>
  )
}
