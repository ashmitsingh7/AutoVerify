'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'

const links = [
  { href: '/generate', label: 'Generate' },
  { href: '/analyze', label: 'Analyze' },
  { href: '/docs', label: 'Docs' },
]

export function Navigation() {
  const pathname = usePathname()

  return (
    <header className="sticky top-0 z-50 w-full border-b border-border bg-background/80 backdrop-blur-xl">
      <nav className="mx-auto flex h-16 max-w-[1200px] items-center justify-between px-6">
        <Link
          href="/"
          className="text-[15px] font-semibold tracking-tight text-foreground transition-opacity hover:opacity-70"
        >
          AutoVerify
        </Link>

        <div className="flex items-center gap-1">
          {links.map((link) => {
            const active =
              pathname === link.href || pathname.startsWith(`${link.href}/`)
            return (
              <Link
                key={link.href}
                href={link.href}
                className={cn(
                  'rounded-md px-3 py-1.5 text-[13px] transition-colors',
                  active
                    ? 'text-foreground'
                    : 'text-muted-foreground hover:text-foreground',
                )}
              >
                {link.label}
              </Link>
            )
          })}
          <a
            href="https://github.com"
            target="_blank"
            rel="noreferrer"
            className="rounded-md px-3 py-1.5 text-[13px] text-muted-foreground transition-colors hover:text-foreground"
          >
            GitHub
          </a>
        </div>
      </nav>
    </header>
  )
}
