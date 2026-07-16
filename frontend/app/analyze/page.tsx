'use client'

import { useRef, useState } from 'react'
import { AvButton } from '@/components/av-button'
import { CodeEditor } from '@/components/editor'
import { Divider } from '@/components/divider'
import { ErrorPanel } from '@/components/error-panel'
import { analyzeRtl } from '@/lib/services/analyze'
import { EXAMPLE_VERILOG } from '@/lib/sample'
import type { AnalyzeResponse } from '@/lib/types'
import { cn } from '@/lib/utils'

export default function AnalyzePage() {
  const [code, setCode] = useState(EXAMPLE_VERILOG)
  const [result, setResult] = useState<AnalyzeResponse | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<unknown>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  async function handleAnalyze() {
    setLoading(true)
    setError(null)
    try {
      const res = await analyzeRtl(code)
      setResult(res)
    } catch (err) {
      setResult(null)
      setError(err)
    } finally {
      setLoading(false)
    }
  }

  function handleUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = () => setCode(String(reader.result))
    reader.readAsText(file)
  }

  const inputs = result?.ports.filter((p) => p.dir === 'input').length ?? 0
  const outputs = result?.ports.filter((p) => p.dir === 'output').length ?? 0

  return (
    <main className="mx-auto max-w-[1200px] px-6 pb-40 pt-12">
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1.2fr_1fr]">
        {/* LEFT — editor */}
        <div className="flex min-h-[420px] flex-col overflow-hidden rounded-xl border border-border bg-background">
          <div className="flex items-center justify-between px-4 py-3">
            <span className="font-mono text-[12px] text-muted-foreground">
              {result?.module_name ?? 'untitled.sv'}
            </span>
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
          </div>
          <div className="flex-1">
            <CodeEditor value={code} onChange={setCode} />
          </div>
          <div className="border-t border-border p-4">
            <AvButton
              size="lg"
              className="w-full"
              onClick={handleAnalyze}
              disabled={loading || code.trim().length === 0}
            >
              {loading ? 'Analyzing…' : 'Analyze'}
            </AvButton>
          </div>
        </div>

        {/* RIGHT — analysis output */}
        <div>
          {error ? (
            <ErrorPanel error={error} />
          ) : result ? (
            <>
              <header className="animate-fade-up">
                <p className="font-mono text-[13px] text-muted-foreground">module</p>
                <h1 className="mt-2 text-5xl font-semibold tracking-tight text-foreground">
                  {result.module_name}
                </h1>
                <p className="mt-4 text-[15px] text-muted-foreground">
                  {result.ports.length} ports · {inputs} inputs · {outputs} outputs ·{' '}
                  {result.param_order.length} parameter
                  {result.param_order.length === 1 ? '' : 's'}
                </p>
              </header>

              <section className="animate-fade-up mt-10" style={{ animationDelay: '80ms' }}>
                <h2 className="text-[13px] uppercase tracking-widest text-muted-foreground">
                  Ports
                </h2>
                <div className="mt-4">
                  <div className="grid grid-cols-[1.5fr_1fr_1fr_1fr] py-3 text-[13px] text-muted-foreground">
                    <span>Name</span>
                    <span>Direction</span>
                    <span>Width</span>
                    <span>Type</span>
                  </div>
                  <Divider />
                  {result.ports.map((port) => (
                    <div
                      key={port.name}
                      className="grid grid-cols-[1.5fr_1fr_1fr_1fr] items-center border-b border-border py-4 font-mono text-[13px]"
                    >
                      <span className="text-foreground">{port.name}</span>
                      <span
                        className={cn(
                          port.dir === 'input'
                            ? 'text-muted-foreground'
                            : 'text-[color:var(--success)]',
                        )}
                      >
                        {port.dir}
                      </span>
                      <span className="text-muted-foreground">{port.width}</span>
                      <span className="text-muted-foreground">{port.type}</span>
                    </div>
                  ))}
                </div>
              </section>

              {result.param_order.length > 0 && (
                <section className="animate-fade-up mt-10" style={{ animationDelay: '160ms' }}>
                  <h2 className="text-[13px] uppercase tracking-widest text-muted-foreground">
                    Parameters
                  </h2>
                  <div className="mt-4">
                    <div className="grid grid-cols-[1.5fr_1fr] py-3 text-[13px] text-muted-foreground">
                      <span>Name</span>
                      <span>Default</span>
                    </div>
                    <Divider />
                    {result.param_order.map((name) => (
                      <div
                        key={name}
                        className="grid grid-cols-[1.5fr_1fr] items-center border-b border-border py-4 font-mono text-[13px]"
                      >
                        <span className="text-foreground">{name}</span>
                        <span className="text-muted-foreground">
                          {result.param_default[name] ?? '—'}
                        </span>
                      </div>
                    ))}
                  </div>
                </section>
              )}

              {result.diagnostics.length > 0 && (
                <section className="animate-fade-up mt-10" style={{ animationDelay: '240ms' }}>
                  <h2 className="text-[13px] uppercase tracking-widest text-muted-foreground">
                    Diagnostics
                  </h2>
                  <div className="mt-4 space-y-2">
                    {result.diagnostics.map((d, i) => (
                      <p
                        key={i}
                        className={cn(
                          'text-[13px]',
                          d.severity === 'error'
                            ? 'text-[color:var(--error)]'
                            : 'text-muted-foreground',
                        )}
                      >
                        [{d.code}] {d.message}
                      </p>
                    ))}
                  </div>
                </section>
              )}
            </>
          ) : (
            <p className="mt-4 text-[15px] text-muted-foreground">
              Paste or upload a module, then click Analyze.
            </p>
          )}
        </div>
      </div>
    </main>
  )
}
