import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  'inline-flex shrink-0 select-none items-center justify-center gap-2 whitespace-nowrap rounded-lg font-medium transition-all duration-200 outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-40 [&_svg]:pointer-events-none [&_svg]:shrink-0',
  {
    variants: {
      variant: {
        primary:
          'bg-primary text-primary-foreground hover:opacity-90 active:opacity-80',
        secondary:
          'border border-border bg-transparent text-foreground hover:border-[#2e2e2e] hover:bg-accent',
        ghost:
          'bg-transparent text-muted-foreground hover:bg-accent hover:text-foreground',
      },
      size: {
        sm: 'h-8 px-3 text-[13px] [&_svg]:size-4',
        default: 'h-10 px-4 text-sm [&_svg]:size-4',
        lg: 'h-12 px-6 text-[15px] [&_svg]:size-[18px]',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'default',
    },
  },
)

export interface AvButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

export function AvButton({
  className,
  variant,
  size,
  ...props
}: AvButtonProps) {
  return (
    <button className={cn(buttonVariants({ variant, size, className }))} {...props} />
  )
}
