export function CodeBlock({ children }: { children: string }) {
  return (
    <pre className="my-6 overflow-x-auto rounded-xl border border-border bg-card px-5 py-4">
      <code className="font-mono text-[13px] leading-relaxed text-foreground">
        {children}
      </code>
    </pre>
  )
}
