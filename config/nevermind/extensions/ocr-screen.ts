import type { ExtensionContext, NevermindExtension } from './nevermind-extension-api'

const INDICATOR_ID = 'ocr-screen'

async function copyVisibleScreenText(ctx: ExtensionContext) {
  ctx.ui.indicator.show({
    id: INDICATOR_ID,
    title: 'OCR Screen',
    subtitle: 'Reading visible text…',
    status: 'loading',
  })

  try {
    if (!ctx.ocr || !ctx.system.capabilities.has('ocr')) {
      throw new Error('Screen OCR is not available on this Mac')
    }

    const result = await ctx.ocr.screen({ timeoutMs: 30_000 })
    const text = result.text.trim()

    if (!text) {
      ctx.ui.indicator.update({
        id: INDICATOR_ID,
        title: 'OCR Screen',
        subtitle: 'No visible text found',
        status: 'error',
        durationMs: 3500,
      })
      return
    }

    if (ctx.desktop.clipboard) {
      ctx.desktop.clipboard.writeText(text)
    } else {
      ctx.ui.indicator.update({
        id: INDICATOR_ID,
        title: 'OCR Screen',
        subtitle: 'Copying recognized text…',
        status: 'loading',
      })
      return ctx.navigation.run(
        ctx.actions.copyText(text, 'Copy Visible Screen Text'),
      )
    }

    const lineCount = text.split(/\r?\n/).filter((line) => line.trim()).length
    ctx.ui.indicator.update({
      id: INDICATOR_ID,
      title: 'OCR Screen',
      subtitle: `Copied ${lineCount} ${lineCount === 1 ? 'line' : 'lines'} to the clipboard`,
      status: 'success',
      durationMs: 2500,
    })
  } catch (error) {
    ctx.logs.error('Screen OCR failed', error)
    const message = error instanceof Error ? error.message : 'Could not read the screen'
    ctx.ui.indicator.update({
      id: INDICATOR_ID,
      title: 'OCR Screen',
      subtitle: message,
      status: 'error',
      durationMs: 4500,
    })
    throw new Error(`OCR Screen failed: ${message}`)
  }
}

export default {
  id: 'ocr-screen',
  title: 'OCR Screen',
  subtitle: 'Copy all visible text from the screen',
  capabilities: ['ocr', 'clipboard.history'],
  actions(ctx) {
    return [
      ctx.action({
        id: 'copy-visible-screen-text',
        title: 'OCR Screen',
        subtitle: 'Copy all visible text to the clipboard',
        icon: 'scan-text',
        aliases: [
          'copy screen text',
          'extract text from screen',
          'screen text',
          'visible text',
        ],
        keywords: ['ocr', 'screen', 'copy', 'text', 'visible'],
        background: true,
        dismissAfterRun: 'auto',
        customizable: true,
        run: copyVisibleScreenText,
      }),
    ]
  },
} satisfies NevermindExtension
