import type { NevermindExtension, ExtensionContext } from './nevermind-extension-api'

function cleanUrlParagraph(paragraph: string): string | null {
  // Only compact standalone URL-shaped paragraphs, never every space in prose.
  if (!/^https?:\/\//i.test(paragraph)) return null
  const compact = paragraph.replace(/[\s\u200B\uFEFF]+/g, '')
  if (!/^[\x21-\x7E]+$/.test(compact)) return null
  try {
    const url = new URL(compact)
    if (!url.hostname || !['http:', 'https:'].includes(url.protocol)) return null
    if (!/\s/.test(paragraph)) return compact
    // Check raw query structure without decoding or changing signed values.
    const query = compact.match(/\?([^#]*)/)?.[1]
    if (query && query.split('&').every(pair => /^[A-Za-z0-9_.~-]+=[^\s]*$/.test(pair))) return compact
    const fragments = paragraph.split(/\s+/)
    if (fragments.length > 1 && fragments.slice(1).every(part => /[\/%.?&#=_~+-]/.test(part))) return compact
  } catch {
    return null
  }
  return null
}

function unwrapLines(text: string): string {
  return text.replace(/\r\n?/g, '\n').trim()
    .split(/\n[\t ]*\n(?:[\t ]*\n)*/)
    .map(paragraph => cleanUrlParagraph(paragraph.trim()) ?? paragraph.replace(/[\t ]*\n[\t ]*/g, ' ').trim())
    .filter(Boolean).join('\n\n')
}

function clipboardText(value: unknown): string {
  if (typeof value === 'string') return value
  if (value && typeof value === 'object' && 'text' in value && typeof value.text === 'string') return value.text
  return ''
}

// Handle both the declared string and older hosts' Electron NativeImage.
function imageInput(value: unknown): string | null {
  if (typeof value === 'string') return value || null
  if (value && typeof value === 'object') {
    const image = value as { toDataURL?: () => string; isEmpty?: () => boolean; imageDataUrl?: string; image?: string; path?: string }
    if (typeof image.isEmpty === 'function' && image.isEmpty()) return null
    if (typeof image.toDataURL === 'function') return image.toDataURL() || null
    return image.imageDataUrl || image.image || image.path || null
  }
  return null
}

async function recognizeAndCopy(ctx: ExtensionContext, input: string) {
  if (!ctx.system.capabilities.has('ocr') || !ctx.ocr) throw new Error('Image text recognition is not supported on this system.')
  const clipboard = ctx.desktop.clipboard
  if (!clipboard) throw new Error('Clipboard access is unavailable.')
  const result = await ctx.ocr.image(input, { timeoutMs: 30000 })
  const text = unwrapLines(result.text)
  if (!text) throw new Error('No text was found in the image. The clipboard was left unchanged.')
  // Await also works with synchronous hosts and prevents premature success.
  await clipboard.writeText(text)
  ctx.ui.indicator.show({
    id: 'clipboard-ocr-success', title: 'Copied to clipboard',
    status: 'success', durationMs: 2500,
  })
}

const brokenUrl = 'https://mcp.sentry.dev/oauth/authorize? response_type=code&client_id=https%3A%2F%2Fopencode. ai%2Foauth%2Fopencode%2Fclient. json&code_challenge=IMRxTE_00HxNngLBqLPr5- xL15Vz9cW59JrvDvcZoH8&code_challenge_method=S256&redirec t_uri=http%3A%2F%2F127.0.0. 1%3A38305%2Fcallback&state=qA_yAEAkOrPZNSHLjun7oxiW7Gyzv J- Ji11wDN1WoPo&scope=org%3Aread+project%3Awrite+team%3Awri te+event%3Awrite+alerts%3Awrite&resource=https%3A%2F%2Fm cp.sentry.dev%2Fmcp'
const continuousUrl = 'https://mcp.sentry.dev/oauth/authorize?response_type=code&client_id=https%3A%2F%2Fopencode.ai%2Foauth%2Fopencode%2Fclient.json&code_challenge=IMRxTE_00HxNngLBqLPr5-xL15Vz9cW59JrvDvcZoH8&code_challenge_method=S256&redirect_uri=http%3A%2F%2F127.0.0.1%3A38305%2Fcallback&state=qA_yAEAkOrPZNSHLjun7oxiW7GyzvJ-Ji11wDN1WoPo&scope=org%3Aread+project%3Awrite+team%3Awrite+event%3Awrite+alerts%3Awrite&resource=https%3A%2F%2Fmcp.sentry.dev%2Fmcp'
for (const [input, expected] of [
  ['one\ntwo', 'one two'], ['one\n\ntwo', 'one\n\ntwo'],
  ['one\r\n  two\r\n \r\nthree', 'one two\n\nthree'],
  ['  one\n\n\n two  ', 'one\n\ntwo'], ['', ''],
  [brokenUrl, continuousUrl], [brokenUrl.replace(/ /g, '\n'), continuousUrl],
  ['https://example.com/auth?\ncode=abc-\ndef&redirec\nt_uri=http%3A%2F%2Flocalhost&scope=a+b', 'https://example.com/auth?code=abc-def&redirect_uri=http%3A%2F%2Flocalhost&scope=a+b'],
  ['Before\ntext\n\n' + brokenUrl + '\n\nAfter\ntext', 'Before text\n\n' + continuousUrl + '\n\nAfter text'],
  ['Visit https://example.com for more\ninformation.', 'Visit https://example.com for more information.'],
  ['https://example.com\nRead more here.', 'https://example.com Read more here.'],
  ['https://example.com/docs/\npage.html', 'https://example.com/docs/page.html'],
]) {
  if (unwrapLines(input) !== expected) throw new Error('OCR paragraph/URL formatting check failed.')
}
for (const [value, expected] of [
  ['/tmp/image.png', '/tmp/image.png'], [{ type: 'text', text: '/tmp/image.png' }, '/tmp/image.png'],
  [null, ''], [undefined, ''], [42, ''], [{ type: 'empty' }, ''],
] as Array<[unknown, string]>) {
  if (clipboardText(value) !== expected) throw new Error('OCR clipboard text conversion check failed.')
}
const sample = 'data:image/png;base64,TEST'
if (imageInput({ toDataURL: () => sample, isEmpty: () => false }) !== sample ||
    imageInput({ type: 'image', imageDataUrl: sample }) !== sample ||
    imageInput(sample) !== sample || imageInput(null) !== null ||
    imageInput({ toDataURL: () => sample, isEmpty: () => true }) !== null) {
  throw new Error('OCR clipboard image conversion check failed.')
}

export default {
  id: 'local.ocr-clipboard-image',
  title: 'OCR Clipboard Image',
  subtitle: 'Copy image text, repairing wrapped URLs and preserving paragraphs',
  capabilities: ['ocr', 'clipboard.history', 'desktop.files'],
  commands: [{
    id: 'copy-text', title: 'OCR Image in Clipboard',
    subtitle: 'Automatically use the clipboard image, copied file, or image path',
    aliases: ['Copy Text from Clipboard Image', 'Clipboard OCR'],
    icon: 'scan-text',
    async run(ctx) {
      if (!ctx.system.capabilities.has('ocr') || !ctx.ocr) throw new Error('Image text recognition is not supported on this system.')
      const clipboard = ctx.desktop.clipboard
      if (!clipboard) throw new Error('Clipboard access is unavailable.')
      // Some host versions return promises despite the synchronous API types.
      let input = imageInput(await clipboard.readImage())
      if (!input) {
        const content = await clipboard.read({ formats: ['image', 'files'] })
        if (content.type === 'image') input = imageInput(content)
        else if (content.type === 'files') input = content.paths[0] || null
      }
      if (!input) {
        const path = clipboardText(await clipboard.readText()).trim().replace(/^(['"])(.*)\1$/, '$2')
        if (/^(\/|~\/|file:\/\/)/.test(path)) input = path
      }
      if (input) {
        await recognizeAndCopy(ctx, input)
        return ctx.navigation.run(ctx.actions.pop('Done', { dismissAfterRun: 'auto' }))
      }
      return ctx.navigation.run(ctx.input.prompt({
        title: 'OCR Image in Clipboard',
        message: 'No image or file path in the clipboard. Choose an image instead.',
        fields: [{ id: 'image', label: 'Image file', type: 'file', required: true,
          extensions: ['png', 'jpg', 'jpeg', 'tiff', 'tif', 'heic', 'webp', 'bmp', 'gif'] }],
        action: ctx.actions.run('Copy Image Text', async (ctx, action) => {
          const value = action.formValues?.image
          const path = Array.isArray(value) ? value[0] : typeof value === 'string' ? value : undefined
          if (!path) throw new Error('Choose an image file first.')
          await recognizeAndCopy(ctx, path)
          return ctx.navigation.run(ctx.actions.pop('Done', { dismissAfterRun: 'auto' }))
        }),
      }))
    },
  }],
} satisfies NevermindExtension
