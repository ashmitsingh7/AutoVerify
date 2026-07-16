'use client'

import { useMemo, useState } from 'react'
import { Search } from 'lucide-react'
import { CodeBlock } from '@/components/code-block'
import { cn } from '@/lib/utils'

const sections = [
  { id: 'introduction', label: 'Introduction' },
  { id: 'installation', label: 'Installation' },
  { id: 'quick-start', label: 'Quick Start' },
  { id: 'cli', label: 'CLI Reference' },
  { id: 'output', label: 'Generated Files' },
]

export default function DocsPage() {
  const [query, setQuery] = useState('')

  const filtered = useMemo(
    () =>
      sections.filter((s) =>
        s.label.toLowerCase().includes(query.toLowerCase()),
      ),
    [query],
  )

  return (
    <main className="mx-auto max-w-[1200px] px-6 py-16">
      <div className="grid grid-cols-1 gap-16 md:grid-cols-[220px_1fr]">
        {/* Left navigation */}
        <aside className="md:sticky md:top-24 md:h-fit">
          <div className="flex items-center gap-2 rounded-lg border border-border bg-card px-3 py-2">
            <Search className="size-4 text-muted-foreground" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search"
              className="w-full bg-transparent text-[13px] text-foreground outline-none placeholder:text-muted-foreground"
            />
          </div>
          <nav className="mt-6 flex flex-col gap-1">
            {filtered.map((s) => (
              <a
                key={s.id}
                href={`#${s.id}`}
                className="rounded-md px-3 py-1.5 text-[13px] text-muted-foreground transition-colors hover:text-foreground"
              >
                {s.label}
              </a>
            ))}
            {filtered.length === 0 && (
              <span className="px-3 py-1.5 text-[13px] text-muted-foreground">
                No results
              </span>
            )}
          </nav>
        </aside>

        {/* Content */}
        <article className="max-w-2xl">
          <Doc />
        </article>
      </div>
    </main>
  )
}

function H1({ id, children }: { id: string; children: string }) {
  return (
    <h1
      id={id}
      className="scroll-mt-24 text-4xl font-semibold tracking-tight text-foreground"
    >
      {children}
    </h1>
  )
}

function H2({ id, children }: { id: string; children: string }) {
  return (
    <h2
      id={id}
      className="mt-20 scroll-mt-24 text-2xl font-semibold tracking-tight text-foreground"
    >
      {children}
    </h2>
  )
}

function P({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <p className={cn('mt-4 text-[15px] leading-relaxed text-muted-foreground', className)}>
      {children}
    </p>
  )
}

function Doc() {
  return (
    <>
      <H1 id="introduction">Introduction</H1>
      <P>
        AutoVerify parses a SystemVerilog module and generates a complete
        UVM-style verification environment — interface, driver, monitor,
        scoreboard, environment, and testbench — ready to simulate.
      </P>

      <H2 id="installation">Installation</H2>
      <P>Install the CLI globally with your package manager of choice.</P>
      <CodeBlock>{`npm install -g autoverify`}</CodeBlock>

      <H2 id="quick-start">Quick Start</H2>
      <P>
        Point AutoVerify at a module and it emits a verification environment
        next to your source.
      </P>
      <CodeBlock>{`autoverify generate counter.sv --out ./tb`}</CodeBlock>
      <P>
        The generated testbench compiles against UVM 1.2 and runs with any
        standard simulator.
      </P>

      <H2 id="cli">CLI Reference</H2>
      <P>The generate command accepts the following options.</P>
      <CodeBlock>{`autoverify generate <file>

  --out <dir>       Output directory        (default: ./)
  --width <n>       Override parameter WIDTH (default: from source)
  --seed <n>        Randomization seed       (default: 1)
  --analyze         Print module summary only
  --zip             Emit a single archive`}</CodeBlock>

      <H2 id="output">Generated Files</H2>
      <P>Every run produces the same deterministic file set.</P>
      <CodeBlock>{`counter_if.sv          Interface + clocking blocks
counter_driver.sv      Sequence item driver
counter_monitor.sv     Sampling monitor
counter_scoreboard.sv  Reference model check
counter_env.sv         Agent + scoreboard wiring
counter_tb.sv          Top-level testbench
Makefile               VCS / Questa build
run_sim.tcl            Simulator run script`}</CodeBlock>
    </>
  )
}
