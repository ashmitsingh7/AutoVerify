import Link from 'next/link'
import { ArchitectureFlow } from '@/components/architecture-flow'
import { AvButton } from '@/components/av-button'

export default function HomePage() {
  return (
    <main className="mx-auto max-w-[1200px] px-6">
      <section className="flex flex-col items-center pt-32 pb-28 text-center md:pt-44">
        <h1 className="animate-fade-up max-w-4xl text-balance text-5xl font-semibold leading-[1.05] tracking-tight text-foreground md:text-7xl">
          Generate SystemVerilog verification environments.
        </h1>
        <p
          className="animate-fade-up mt-8 max-w-xl text-balance text-lg leading-relaxed text-muted-foreground"
          style={{ animationDelay: '80ms' }}
        >
          Turn a module into a complete UVM-style testbench in seconds.
        </p>

        <div
          className="animate-fade-up mt-12 flex items-center gap-3"
          style={{ animationDelay: '160ms' }}
        >
          <Link href="/generate">
            <AvButton size="lg">Generate</AvButton>
          </Link>
          <a href="https://github.com" target="_blank" rel="noreferrer">
            <AvButton variant="secondary" size="lg">
              GitHub
            </AvButton>
          </a>
        </div>
      </section>

      <section
        className="animate-fade flex justify-center pb-40"
        style={{ animationDelay: '320ms' }}
      >
        <ArchitectureFlow />
      </section>
    </main>
  )
}
