'use client'

import Editor, { type OnMount } from '@monaco-editor/react'

interface CodeEditorProps {
  value: string
  language?: string
  onChange?: (value: string) => void
  readOnly?: boolean
}

const defineTheme: OnMount = (_editor, monaco) => {
  monaco.editor.defineTheme('autoverify', {
    base: 'vs-dark',
    inherit: true,
    rules: [
      { token: '', foreground: 'FAFAFA', background: '000000' },
      { token: 'comment', foreground: '5A5A5A', fontStyle: 'italic' },
      { token: 'keyword', foreground: 'FAFAFA' },
      { token: 'type', foreground: 'CFCFCF' },
      { token: 'number', foreground: '30D158' },
      { token: 'string', foreground: '9FE7AF' },
      { token: 'identifier', foreground: 'C8C8C8' },
    ],
    colors: {
      'editor.background': '#000000',
      'editor.foreground': '#FAFAFA',
      'editorLineNumber.foreground': '#3A3A3A',
      'editorLineNumber.activeForeground': '#888888',
      'editor.selectionBackground': '#1F1F1F',
      'editor.lineHighlightBackground': '#0A0A0A',
      'editorCursor.foreground': '#FAFAFA',
      'editor.inactiveSelectionBackground': '#141414',
      'editorIndentGuide.background1': '#141414',
      'editorGutter.background': '#000000',
      'scrollbarSlider.background': '#1F1F1F80',
      'scrollbarSlider.hoverBackground': '#2A2A2A',
      'scrollbarSlider.activeBackground': '#2A2A2A',
    },
  })
  monaco.editor.setTheme('autoverify')
}

export function CodeEditor({
  value,
  language = 'systemverilog',
  onChange,
  readOnly = false,
}: CodeEditorProps) {
  return (
    <Editor
      height="100%"
      language={language === 'systemverilog' ? 'cpp' : language}
      value={value}
      theme="autoverify"
      beforeMount={(monaco) => {
        monaco.editor.defineTheme('autoverify', {
          base: 'vs-dark',
          inherit: true,
          rules: [
            { token: 'comment', foreground: '5A5A5A', fontStyle: 'italic' },
            { token: 'number', foreground: '30D158' },
            { token: 'string', foreground: '9FE7AF' },
          ],
          colors: {
            'editor.background': '#000000',
            'editor.foreground': '#FAFAFA',
            'editorLineNumber.foreground': '#3A3A3A',
            'editorLineNumber.activeForeground': '#888888',
            'editor.selectionBackground': '#1F1F1F',
            'editor.lineHighlightBackground': '#0A0A0A',
            'editorCursor.foreground': '#FAFAFA',
            'editorGutter.background': '#000000',
            'scrollbarSlider.background': '#1F1F1F80',
            'scrollbarSlider.hoverBackground': '#2A2A2A',
            'scrollbarSlider.activeBackground': '#2A2A2A',
          },
        })
      }}
      onMount={defineTheme}
      onChange={(v) => onChange?.(v ?? '')}
      options={{
        readOnly,
        fontSize: 13,
        fontFamily:
          "'SF Mono', 'JetBrains Mono', ui-monospace, Menlo, monospace",
        fontLigatures: true,
        lineHeight: 22,
        minimap: { enabled: false },
        scrollBeyondLastLine: false,
        padding: { top: 20, bottom: 20 },
        renderLineHighlight: 'line',
        lineNumbersMinChars: 3,
        glyphMargin: false,
        folding: false,
        overviewRulerLanes: 0,
        hideCursorInOverviewRuler: true,
        scrollbar: { verticalScrollbarSize: 8, horizontalScrollbarSize: 8 },
        smoothScrolling: true,
        cursorBlinking: 'smooth',
        contextmenu: false,
        guides: { indentation: false },
      }}
    />
  )
}
