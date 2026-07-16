'use client'

import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'

const stages = [
  'Verilog',
  'Lexer',
  'Parser',
  'AST',
  'Generator',
  'Renderer',
  'Testbench',
]

export function ArchitectureFlow() {
  const [active, setActive] = useState(-1)

  useEffect(() => {
    let i = -1
    const id = setInterval(() => {
      i = i + 1 > stages.length ? 0 : i + 1
      setActive(i)
    }, 900)
    return () => clearInterval(id)
  }, [])

  return (
    <div className="flex flex-col items-center" aria-hidden="true">
      {stages.map((stage, index) => {
        const isActive = index <= active
        return (
          <div key={stage} className="flex flex-col items-center">
            <div
              className={cn(
                'font-mono text-[13px] tracking-wide transition-colors duration-500',
                isActive ? 'text-foreground' : 'text-muted-foreground/40',
              )}
            >
              {stage}
            </div>
            {index < stages.length - 1 && (
              <svg
                width="1"
                height="40"
                viewBox="0 0 1 40"
                className="my-2"
                fill="none"
              >
                <line
                  x1="0.5"
                  y1="0"
                  x2="0.5"
                  y2="40"
                  stroke="currentColor"
                  strokeWidth="1"
                  strokeDasharray="3 3"
                  className={cn(
                    'transition-colors duration-500',
                    index < active
                      ? 'text-foreground/60 [animation:av-flow_1s_linear_infinite]'
                      : 'text-border',
                  )}
                />
              </svg>
            )}
          </div>
        )
      })}
    </div>
  )
}
