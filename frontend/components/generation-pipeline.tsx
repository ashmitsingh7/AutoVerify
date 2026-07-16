'use client'

import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'

const STAGES = ['Lexer', 'Parser', 'AST', 'Validation', 'Generator', 'Renderer']

/** Cycles through stage labels while `active` is true. This is cosmetic —
 * the backend's /generate call is a single blocking request with no
 * per-stage progress events, so there's nothing real to bind these steps
 * to. It stops (freezing on the last stage) the instant `active` goes
 * false, rather than running a fixed fake duration. */
export function GenerationPipeline({ active }: { active: boolean }) {
  const [index, setIndex] = useState(0)

  useEffect(() => {
    if (!active) {
      setIndex(0)
      return
    }
    const id = setInterval(() => {
      setIndex((i) => (i + 1 >= STAGES.length ? STAGES.length - 1 : i + 1))
    }, 350)
    return () => clearInterval(id)
  }, [active])

  return (
    <div className="flex items-center gap-2 font-mono text-[13px] text-muted-foreground">
      {STAGES.map((stage, i) => (
        <span key={stage} className="flex items-center gap-2">
          <span className={cn(i <= index && active ? 'text-foreground' : undefined)}>
            {stage}
          </span>
          {i < STAGES.length - 1 && <span className="text-border">→</span>}
        </span>
      ))}
    </div>
  )
}
