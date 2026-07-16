import { cn } from '@/lib/utils'

interface StatusRowProps {
  label: string
  value: React.ReactNode
  mono?: boolean
  className?: string
}

export function StatusRow({ label, value, mono, className }: StatusRowProps) {
  return (
    <div
      className={cn(
        'flex items-center justify-between py-4',
        className,
      )}
    >
      <span className="text-[15px] text-muted-foreground">{label}</span>
      <span
        className={cn(
          'text-[15px] text-foreground',
          mono && 'font-mono text-[13px]',
        )}
      >
        {value}
      </span>
    </div>
  )
}
