import type { NevermindExtension, ExtensionContext } from './nevermind-extension-api'

// Keep the original characters: parsing is validation only, never URL serialization.
function validUrl(value: string): boolean {
  try {
    const url = new URL(value)
    return (url.protocol === 'https:' || url.protocol === 'http:') && Boolean(url.hostname)
  } catch { return false }
}

function extractUrls(text: string): string[] {
  const lines = text.replace(/\r\n?/g, '\n').replace(/[\u200B-\u200D\uFEFF]/g, '').split('\n')
  const urls: string[] = []
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    const starts = [...line.matchAll(/https?\s*:\s*\/\s*\//gi)]
    for (let s = 0; s < starts.length; s++) {
      const start = starts[s].index!
      const end = s + 1 < starts.length ? starts[s + 1].index! : line.length
      let fragment = line.slice(start, end)
      // A URL cannot contain literal quotes or angle brackets. These usually delimit it.
      const delimiter = fragment.search(/[<>"'`]/)
      let closed = delimiter >= 0
      if (closed) fragment = fragment.slice(0, delimiter)
      // Stop at prose following an inline URL, while allowing OCR spaces near punctuation.
      const prose = fragment.search(/\s+(?=[A-Za-z]{2,}\s+[A-Za-z]{2,}(?:\s|[.!:]|$))/)
      if (prose >= 0) { fragment = fragment.slice(0, prose); closed = true }
      let value = fragment.replace(/\s+/g, '')
      if (!closed && s === starts.length - 1) {
        for (let j = i + 1; j < lines.length; j++) {
          const next = lines[j].trim()
          if (!next || /https?\s*:\s*\//i.test(next)) break
          if (/[<>"'`]/.test(next) || /[^A-Za-z0-9\s\-._~:/?#[\]@!$&()*+,;=%]/.test(next)) break
          // Don't append surrounding terminal instructions or prompts.
          if (/[A-Za-z]{2,}\s+[A-Za-z]{2,}(?:\s+[A-Za-z]{2,}|[.:!?]?$)/.test(next)) break
          if (/^(?:\$|>|❯|➜)\s/.test(next)) break
          const compact = next.replace(/\s+/g, '')
          // Bare words on the next line are more likely terminal prose than URL data.
          if (/^[A-Za-z]+[.:!?]?$/.test(compact)) break
          value += compact
        }
      }
      // Strip only unmatched closing wrappers; preserve encoded data and query punctuation.
      for (const [open, close] of [['(', ')'], ['[', ']']]) {
        while (value.endsWith(close) && value.split(close).length > value.split(open).length) value = value.slice(0, -1)
      }
      if (validUrl(value) && !urls.includes(value)) urls.push(value)
    }
  }
  return urls
}

function editUrl(ctx: ExtensionContext, content: string) {
  return ctx.actions.push('Review or Edit URL', ctx.ui.editor({
    title: 'Review URL', content, format: 'text',
    submitAction: ctx.actions.run('Copy URL', (c, action) => {
      const value = (action.editorContent ?? '').replace(/\s+/g, '')
      if (!validUrl(value)) throw new Error('Enter a complete http:// or https:// URL. The clipboard has not been changed.')
      if (!c.desktop.clipboard) throw new Error('Clipboard access is unavailable.')
      c.desktop.clipboard.writeText(value)
      c.ui.indicator.show({ title: 'URL copied', status: 'success', durationMs: 2200 })
      return c.navigation.pop()
    }),
  }))
}

export default {
  id: 'local.url-from-screenshot',
  title: 'URL from Screenshot',
  subtitle: 'Extract wrapped terminal URLs from a clipboard image',
  capabilities: ['ocr', 'clipboard.history'],
  commands: [{
    id: 'extract-url', title: 'Get URL from Screenshot', icon: 'scan-text',
    aliases: ['OCR URL', 'Copy URL from Clipboard Image', 'Terminal Login URL'],
    async run(ctx) {
      if (!ctx.ocr || !ctx.system.capabilities.has('ocr')) throw new Error('Native OCR is unavailable on this system.')
      const clipboard = ctx.desktop.clipboard
      if (!clipboard) throw new Error('Clipboard access is unavailable.')
      const image = clipboard.readImage()
      if (!image) throw new Error('Copy a screenshot to the clipboard first, then run Get URL from Screenshot.')
      ctx.ui.indicator.show({ id: 'url-ocr', title: 'Reading URL from screenshot…', status: 'loading' })
      try {
        const result = await ctx.ocr.image(image, { languages: ['en'], timeoutMs: 30000 })
        const text = result.text || result.blocks?.map(block => block.text).join('\n') || ''
        const urls = extractUrls(text)
        if (!urls.length) {
          return ctx.ui.list({
            title: 'No URL Found', contentSizing: 'fit',
            subtitle: 'Try a tighter, higher-resolution screenshot of the URL.',
            items: [{ id: 'review', title: 'Review Recognized Text', subtitle: 'Repair the URL, remove surrounding instructions, then copy it.', icon: 'text-cursor-input', primaryAction: editUrl(ctx, text) }],
          })
        }
        const copied = urls.length === 1 && clipboard.readImage() === image
        if (copied) {
          clipboard.writeText(urls[0])
          ctx.ui.indicator.show({ title: 'URL copied', subtitle: 'Wrapped lines and spaces removed', status: 'success', durationMs: 2500 })
        }
        return ctx.ui.list({
          title: copied ? 'URL Copied' : 'Choose a URL to Copy',
          subtitle: 'Local OCR • Check long authentication tokens for recognition errors.',
          contentSizing: 'fit', detail: { visible: true, placement: 'bottom' },
          items: urls.map((url, index) => ({
            id: `url-${index}`, title: new URL(url).hostname, subtitle: url, icon: 'link',
            detail: { text: url },
            primaryAction: ctx.actions.copyText(url, 'Copy URL'),
            actions: [editUrl(ctx, url), ctx.actions.push('View Recognized Text', ctx.ui.preview({ title: 'Recognized Text', content: text }))],
          })),
        })
      } finally {
        ctx.ui.indicator.hide('url-ocr')
      }
    },
  }],
} satisfies NevermindExtension
