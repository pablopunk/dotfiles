import type { NevermindExtension, ExtensionContext, ExtensionActionResult, ExtensionItem } from './nevermind-extension-api'

// Processing copied from media-compressor.ts, convert-to-compatible.ts,
// resize-image-half.ts and speed-up-media.ts. Shared helpers are consolidated;
// this extension does not import or depend on those extensions being enabled.
const COMPRESS_IMAGES = ['jpg', 'jpeg', 'png', 'heic', 'tiff', 'tif', 'webp']
const IMAGES = ['jpg', 'jpeg', 'png', 'heic', 'heif', 'tiff', 'tif', 'webp', 'bmp', 'gif', 'avif']
const VIDEOS = ['mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v']
const CONVERT_VIDEOS = [...VIDEOS, 'flv', 'wmv', 'ts']
const SPEEDS = [{ label: '1.3x', value: 1.3 }, { label: '1.5x', value: 1.5 }, { label: '2.0x', value: 2 }]
type Operation = 'compress' | 'convert' | 'half'
type Saved = { source: string; output: string; before: number; after: number; targetExt?: string; origDims?: string; newDims?: string }
type Failure = { source: string; reason: string }

function extensionOf(path: string): string { return path.split('.').pop()?.toLowerCase() || '' }
function basename(path: string): string { return path.split('/').pop() || 'File' }
function withoutExtension(path: string): string {
  const dot = path.lastIndexOf('.')
  return dot > path.lastIndexOf('/') ? path.slice(0, dot) : path
}
function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}
function isSameFormat(source: string, target: string): boolean {
  return source === target || ((source === 'jpeg' || source === 'jpg') && target === 'jpg')
}
function shell(ctx: ExtensionContext) {
  if (!ctx.desktop.shell) throw new Error('Media Actions requires the desktop shell API.')
  return ctx.desktop.shell
}
function files(ctx: ExtensionContext) {
  if (!ctx.desktop.files) throw new Error('Media Actions requires the desktop files API.')
  return ctx.desktop.files
}
async function pathExists(ctx: ExtensionContext, path: string): Promise<boolean> {
  const result = await shell(ctx).exec('/usr/bin/test', ['-e', path])
  if (result.exitCode !== 0 && result.exitCode !== 1) throw new Error(result.stderr.trim() || 'Could not check the output path.')
  return result.exitCode === 0
}
async function uniqueOutputPath(ctx: ExtensionContext, source: string, suffix: string, ext: string): Promise<string> {
  const stem = withoutExtension(source)
  let candidate = `${stem}-${suffix}.${ext}`
  let n = 2
  while (await pathExists(ctx, candidate)) candidate = `${stem}-${suffix}-${n++}.${ext}`
  return candidate
}
async function removeIfPresent(ctx: ExtensionContext, path: string): Promise<void> {
  const result = await shell(ctx).exec('/bin/rm', ['-f', path])
  if (result.exitCode !== 0) throw new Error(result.stderr.trim() || 'Could not remove a temporary media file.')
}
async function move(ctx: ExtensionContext, source: string, target: string): Promise<void> {
  const result = await shell(ctx).exec('/bin/mv', ['-n', source, target])
  if (result.exitCode !== 0 || await pathExists(ctx, source)) throw new Error(result.stderr.trim() || 'Could not save output without overwriting an existing file.')
}
function supported(path: string, operation: Operation | 'speed'): boolean {
  const ext = extensionOf(path)
  if (operation === 'half') return IMAGES.includes(ext)
  if (operation === 'speed') return VIDEOS.includes(ext) || ext === 'gif'
  if (operation === 'compress') return COMPRESS_IMAGES.includes(ext) || VIDEOS.includes(ext)
  return IMAGES.includes(ext) || CONVERT_VIDEOS.includes(ext)
}
async function selected(ctx: ExtensionContext, operation: Operation | 'speed', supplied?: string[]): Promise<string[]> {
  const paths = supplied ?? await ctx.desktop.selection.files()
  return [...new Set(paths || [])].filter(path => supported(path, operation))
}
async function dimensions(ctx: ExtensionContext, path: string): Promise<{ width: number; height: number } | null> {
  try {
    const meta = await files(ctx).metadata(path)
    if (meta.width && meta.height) return { width: meta.width, height: meta.height }
  } catch { /* Recover using sips, then ffprobe as in the original. */ }
  const result = await shell(ctx).exec('sips', ['-g', 'pixelWidth', '-g', 'pixelHeight', path])
  if (result.exitCode === 0) {
    const width = result.stdout.match(/pixelWidth:\s*(\d+)/)
    const height = result.stdout.match(/pixelHeight:\s*(\d+)/)
    if (width && height) return { width: Number(width[1]), height: Number(height[1]) }
  }
  if ((await shell(ctx).which('ffprobe')).exitCode === 0) {
    const probe = await shell(ctx).exec('ffprobe', ['-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=width,height', '-of', 'csv=s=x:p=0', path])
    const [width, height] = probe.stdout.trim().split('x').map(Number)
    if (probe.exitCode === 0 && width > 0 && height > 0) return { width, height }
  }
  return null
}
const TITLES: Record<Operation, string> = { compress: 'Compress Media', convert: 'Convert to Compatible Format', half: 'Resize to Half (50%)' }
const BATCH: Record<Operation, string> = { compress: 'batch-compress', convert: 'batch-convert', half: 'batch-resize-half' }

async function previewOperation(ctx: ExtensionContext, operation: Operation, supplied?: string[]): Promise<ExtensionActionResult> {
  const paths = await selected(ctx, operation, supplied)
  if (!paths.length) return ctx.ui.error(operation === 'half' ? 'No Images Selected' : 'No Media Selected', 'Select supported files in Finder, then reopen Media Actions.')
  // Keep the original Finder selection through nested views and batch confirmation.
  ctx.state[`selection:${operation}`] = paths
  const items: ExtensionItem[] = await Promise.all(paths.map(async path => {
    const ext = extensionOf(path)
    const isVideo = (operation === 'convert' ? CONVERT_VIDEOS : VIDEOS).includes(ext)
    let subtitle = isVideo ? 'Video' : 'Image'
    if (operation === 'convert') subtitle = `${ext.toUpperCase()} → ${isVideo ? 'MP4' : 'JPG'} (compressed)`
    if (operation === 'half') {
      const dims = await dimensions(ctx, path)
      const meta = await files(ctx).metadata(path).catch(() => null)
      subtitle = dims ? `${dims.width} × ${dims.height} → ${Math.max(1, Math.round(dims.width * 0.5))} × ${Math.max(1, Math.round(dims.height * 0.5))}` : 'Scale to 50%'
      if (meta?.size) subtitle += ` · ${formatBytes(meta.size)}`
    }
    return {
      id: path, title: basename(path), subtitle, icon: isVideo ? 'video' : 'image',
      image: operation === 'half' ? files(ctx).toFileUrl(path) : undefined,
      primaryAction: ctx.actions.ref(BATCH[operation]),
      actions: [ctx.actions.quickLook(path, 'Quick Look'), ctx.actions.revealPath(path)],
    }
  }))
  return ctx.navigation.push(ctx.ui.list({
    title: TITLES[operation], subtitle: `${paths.length} selected · ${operation === 'compress' ? 'larger results are discarded' : operation === 'convert' ? 'images → JPG, videos → MP4' : 'Enter to resize & compress'}`,
    items, actions: [ctx.actions.ref(BATCH[operation])],
  }))
}

async function processBatch(ctx: ExtensionContext, operation: Operation): Promise<ExtensionActionResult> {
  const remembered = ctx.state[`selection:${operation}`] as string[] | undefined
  const paths = await selected(ctx, operation, remembered)
  if (!paths.length) return ctx.ui.error('No Media Selected', 'Select supported files in Finder first.')
  const videoExtensions = operation === 'convert' ? CONVERT_VIDEOS : VIDEOS
  const hasVideos = operation !== 'half' && paths.some(path => videoExtensions.includes(extensionOf(path)))
  if (hasVideos && (await shell(ctx).which('ffmpeg')).exitCode !== 0) {
    return ctx.ui.error('FFmpeg Missing', 'Video processing requires FFmpeg. Install it with Homebrew: brew install ffmpeg')
  }
  const hasPngquant = operation !== 'convert' && paths.some(path => extensionOf(path) === 'png') && (await shell(ctx).which('pngquant')).exitCode === 0
  const indicatorId = `media-actions-${operation}`
  const verb = operation === 'compress' ? 'Compressing' : operation === 'convert' ? 'Converting' : 'Resizing'
  ctx.ui.indicator.show({ id: indicatorId, title: TITLES[operation], status: 'loading', value: 0, total: paths.length })
  const saved: Saved[] = []
  const skipped: Failure[] = []
  const errors: Failure[] = []
  try {
    for (let index = 0; index < paths.length; index++) {
      const source = paths[index]
      const ext = extensionOf(source)
      const isVideo = operation !== 'half' && videoExtensions.includes(ext)
      const outputExt = operation === 'convert' ? (isVideo ? 'mp4' : 'jpg') : operation === 'half' ? (ext === 'jpeg' ? 'jpg' : ext) : (isVideo || ext === 'png' ? ext : 'jpg')
      const token = `${Date.now()}-${index}-${Math.random().toString(36).slice(2)}`
      const temp = `${withoutExtension(source)}.nvm-${operation}-${token}.${outputExt}`
      const quantizedTemp = `${temp}.opt.png`
      ctx.ui.indicator.update({ id: indicatorId, title: `${verb} ${basename(source)}`, subtitle: `${index + 1} of ${paths.length}`, status: 'loading', value: index, total: paths.length })
      try {
        const before = (await files(ctx).metadata(source)).size
        if (typeof before !== 'number') throw new Error('Could not read the original file size')
        let result
        let origDims: string | undefined
        if (operation === 'half') {
          const dims = await dimensions(ctx, source)
          const targetWidth = dims?.width ? Math.max(1, Math.round(dims.width * 0.5)) : null
          origDims = dims ? `${dims.width} × ${dims.height}` : 'Original'
          if (targetWidth) {
            const args = ['--resampleWidth', String(targetWidth)]
            if (ext === 'jpg' || ext === 'jpeg') args.push('-s', 'format', 'jpeg', '-s', 'formatOptions', '80')
            args.push(source, '--out', temp)
            result = await shell(ctx).exec('sips', args)
          }
          if (!result || result.exitCode !== 0) {
            if ((await shell(ctx).which('ffmpeg')).exitCode === 0) {
              result = await shell(ctx).exec('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-i', source, '-vframes', '1', '-vf', targetWidth ? `scale=${targetWidth}:-2` : 'scale=iw*0.5:ih*0.5', temp, '-y'])
            }
          }
          if (!result || result.exitCode !== 0) throw new Error(result?.stderr.trim() || 'Resizing failed')
          if (outputExt === 'png' && hasPngquant) {
            const quant = await shell(ctx).exec('pngquant', ['--quality', '65-85', '--speed', '1', '--strip', '--force', '--output', quantizedTemp, '--', temp])
            if (quant.exitCode === 0) {
              const replace = await shell(ctx).exec('/bin/mv', [quantizedTemp, temp])
              if (replace.exitCode !== 0) throw new Error(replace.stderr.trim() || 'Could not save PNG optimization')
            } else await removeIfPresent(ctx, quantizedTemp)
          }
        } else if (isVideo) {
          // Original compressor: x265/CRF28. Compatible conversion: H.264/CRF23/yuv420p.
          const codecArgs = operation === 'convert' ? ['-c:v', 'libx264', '-crf', '23', '-preset', 'fast', '-pix_fmt', 'yuv420p'] : ['-vcodec', 'libx265', '-crf', '28', '-preset', 'fast']
          result = await shell(ctx).exec('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-i', source, '-map_metadata', '-1', ...codecArgs, '-vf', 'scale=1920:1920:force_original_aspect_ratio=decrease:force_divisible_by=2', '-c:a', 'aac', '-b:a', '128k', '-movflags', '+faststart', temp, '-y'])
        } else if (operation === 'compress' && ext === 'png' && hasPngquant) {
          result = await shell(ctx).exec('pngquant', ['--quality', '55-85', '--speed', '1', '--strip', '--force', '--output', temp, '--', source])
        } else {
          const format = operation === 'compress' && ext === 'png' ? 'png' : 'jpeg'
          const args = ['-s', 'format', format]
          if (format === 'jpeg') args.push('-s', 'formatOptions', operation === 'convert' ? '80' : '75')
          args.push('-Z', '2048', source, '--out', temp)
          result = await shell(ctx).exec('sips', args)
          if (operation === 'convert' && result.exitCode !== 0 && (await shell(ctx).which('ffmpeg')).exitCode === 0) {
            result = await shell(ctx).exec('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-i', source, '-vframes', '1', '-vf', 'scale=2048:2048:force_original_aspect_ratio=decrease:force_divisible_by=2', '-q:v', '3', temp, '-y'])
          }
        }
        if (!result || result.exitCode !== 0) throw new Error(result?.stderr.trim() || 'The encoder failed')
        const after = (await files(ctx).metadata(temp)).size
        if (typeof after !== 'number') throw new Error('Could not read the output file size')
        const mustBeSmaller = operation === 'compress' || (operation === 'convert' && isSameFormat(ext, outputExt))
        if (mustBeSmaller && after >= before) {
          await removeIfPresent(ctx, temp)
          skipped.push({ source, reason: `Already efficient (${formatBytes(before)}; candidate was ${formatBytes(after)})` })
        } else {
          const suffix = operation === 'compress' ? 'compressed' : operation === 'convert' ? 'compatible' : 'half'
          const output = await uniqueOutputPath(ctx, source, suffix, outputExt)
          await move(ctx, temp, output)
          const newDims = operation === 'half' ? await dimensions(ctx, output) : null
          saved.push({ source, output, before, after, targetExt: outputExt.toUpperCase(), origDims, newDims: newDims ? `${newDims.width} × ${newDims.height}` : '50%' })
        }
      } catch (error) {
        // Per-file failures are recoverable: continue the batch and show each error.
        let reason = error instanceof Error ? error.message : String(error)
        for (const temporaryPath of [temp, quantizedTemp]) {
          try { await removeIfPresent(ctx, temporaryPath) } catch (cleanupError) { reason += ` · Cleanup: ${cleanupError instanceof Error ? cleanupError.message : String(cleanupError)}` }
        }
        errors.push({ source, reason })
      }
      ctx.ui.indicator.update({ id: indicatorId, title: `${index + 1} of ${paths.length} processed`, subtitle: basename(source), status: 'loading', value: index + 1, total: paths.length })
    }
  } finally { ctx.ui.indicator.hide(indicatorId) }
  const before = saved.reduce((sum, item) => sum + item.before, 0)
  const after = saved.reduce((sum, item) => sum + item.after, 0)
  const items: ExtensionItem[] = [
    ...saved.map(item => {
      const percent = item.before > item.after ? Math.round((1 - item.after / item.before) * 100) : 0
      const sizes = `${formatBytes(item.before)} → ${formatBytes(item.after)}${percent ? ` · saved ${percent}%` : ''}`
      return {
        id: `saved:${item.output}`, title: basename(item.output),
        subtitle: operation === 'half' ? `${item.origDims} → ${item.newDims} · ${sizes}` : `${sizes}${operation === 'convert' ? ` · ${item.targetExt}` : ''}`,
        icon: 'circle-check', image: operation === 'half' ? files(ctx).toFileUrl(item.output) : undefined,
        appearance: { foreground: 'green' as const }, primaryAction: ctx.actions.revealPath(item.output),
        actions: [ctx.actions.openPath(item.output, 'Open'), ctx.actions.quickLook(item.output, 'Quick Look'), ctx.actions.copyText(item.output, 'Copy Output Path')],
      }
    }),
    ...skipped.map(item => ({ id: `skipped:${item.source}`, title: basename(item.source), subtitle: `Skipped · ${item.reason}`, icon: 'shield-check', appearance: { foreground: 'yellow' as const }, primaryAction: ctx.actions.revealPath(item.source) })),
    ...errors.map(item => ({ id: `error:${item.source}`, title: basename(item.source), subtitle: `Failed · ${item.reason}`, icon: 'circle-x', appearance: { foreground: 'red' as const }, primaryAction: ctx.actions.revealPath(item.source) })),
  ]
  return ctx.navigation.replace(ctx.ui.list({
    title: operation === 'compress' ? 'Compression Results' : operation === 'convert' ? 'Conversion Results' : 'Resize Results',
    subtitle: `${saved.length} saved${before > after ? ` · ${formatBytes(before - after)} saved` : ''}${skipped.length ? ` · ${skipped.length} skipped` : ''}${errors.length ? ` · ${errors.length} failed` : ''}`,
    items, emptyView: { title: 'No output files created' },
  }))
}

async function speedMenu(ctx: ExtensionContext, supplied?: string[]): Promise<ExtensionActionResult> {
  const paths = await selected(ctx, 'speed', supplied)
  if (!paths.length) return ctx.ui.error('No Media Selected', 'Select one or more supported videos or GIFs in Finder first.')
  ctx.state['selection:speed'] = paths
  return ctx.navigation.push(ctx.ui.list({
    title: 'Select Speed', subtitle: `${paths.length} selected · videos and GIFs`,
    items: SPEEDS.map(speed => ({ id: `speed-${speed.value}`, title: `Speed up by ${speed.label}`, icon: 'zap', primaryAction: ctx.actions.ref(`speed-${speed.value}`, undefined, { useCapturedSelection: true }) })),
  }))
}
async function processSpeed(ctx: ExtensionContext, speed: { label: string; value: number }, captured: boolean): Promise<ExtensionActionResult> {
  const paths = await selected(ctx, 'speed', captured ? ctx.state['selection:speed'] as string[] | undefined : undefined)
  if (!paths.length) return ctx.ui.error('No Media Selected', 'Select videos or GIFs in Finder first.')
  if ((await shell(ctx).which('ffmpeg')).exitCode !== 0) return ctx.ui.error('FFmpeg Missing', 'Speeding up media requires FFmpeg. Install it with Homebrew: brew install ffmpeg')
  if (paths.some(path => extensionOf(path) !== 'gif') && (await shell(ctx).which('ffprobe')).exitCode !== 0) return ctx.ui.error('FFprobe Missing', 'Audio detection requires ffprobe, included with FFmpeg.')
  const indicatorId = 'media-actions-speed'
  const items: ExtensionItem[] = []
  let successes = 0
  ctx.ui.indicator.show({ id: indicatorId, title: `Speeding up by ${speed.label}`, status: 'loading', value: 0, total: paths.length })
  try {
    for (let i = 0; i < paths.length; i++) {
      const source = paths[i]
      const ext = extensionOf(source)
      const temp = `${withoutExtension(source)}.nvm-speed-${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`
      try {
        let result
        const pts = `setpts=${(1 / speed.value).toFixed(4)}*PTS`
        if (ext === 'gif') {
          result = await shell(ctx).exec('ffmpeg', ['-i', source, '-vf', pts, temp, '-y'])
        } else {
          const probe = await shell(ctx).exec('ffprobe', ['-show_streams', '-select_streams', 'a', '-loglevel', 'error', source])
          if (probe.exitCode !== 0) throw new Error(probe.stderr.trim() || 'Could not detect audio streams')
          const hasAudio = probe.stdout.trim().length > 0
          const filters = hasAudio ? ['-filter_complex', `[0:v]${pts}[v];[0:a]atempo=${speed.value}[a]`, '-map', '[v]', '-map', '[a]'] : ['-vf', pts]
          result = await shell(ctx).exec('ffmpeg', ['-i', source, ...filters, '-vcodec', 'libx265', '-crf', '28', '-preset', 'fast', '-acodec', 'aac', '-b:a', '128k', '-movflags', '+faststart', temp, '-y'])
        }
        if (result.exitCode !== 0) throw new Error(result.stderr.trim() || 'Speed conversion failed')
        const output = await uniqueOutputPath(ctx, source, speed.label.replace('.', '_'), ext)
        await move(ctx, temp, output)
        successes++
        items.push({ id: output, title: basename(output), subtitle: `Sped up by ${speed.label}${ext === 'gif' ? '' : ' · compressed with x265'}`, icon: 'circle-check', appearance: { foreground: 'green' }, primaryAction: ctx.actions.revealPath(output), actions: [ctx.actions.openPath(output), ctx.actions.quickLook(output), ctx.actions.copyText(output, 'Copy Output Path')] })
      } catch (error) {
        let reason = error instanceof Error ? error.message : String(error)
        try { await removeIfPresent(ctx, temp) } catch (cleanupError) { reason += ` · Cleanup: ${cleanupError instanceof Error ? cleanupError.message : String(cleanupError)}` }
        items.push({ id: `error:${source}`, title: basename(source), subtitle: `Failed · ${reason}`, icon: 'circle-x', appearance: { foreground: 'red' }, primaryAction: ctx.actions.revealPath(source) })
      }
      ctx.ui.indicator.update({ id: indicatorId, title: `Speeding up by ${speed.label}`, subtitle: `${i + 1} of ${paths.length}`, status: 'loading', value: i + 1, total: paths.length })
    }
  } finally { ctx.ui.indicator.hide(indicatorId) }
  return ctx.navigation.replace(ctx.ui.list({ title: 'Speed-Up Results', subtitle: `${successes} succeeded · ${paths.length - successes} failed`, items }))
}

export default {
  id: 'local.media-actions', title: 'Media Actions',
  subtitle: 'Compress, convert, resize, and speed up selected Finder media',
  capabilities: ['desktop.files', 'system'],
  commands: [{
    id: 'media-actions', title: 'Media Actions', icon: 'clapperboard',
    aliases: ['media tools', 'media utilities'],
    subtitle: 'All media actions in one list',
    async run(ctx) {
      const paths = [...new Set(await ctx.desktop.selection.files() || [])]
      ctx.state['hubSelection'] = paths
      const count = (operation: Operation | 'speed') => paths.filter(path => supported(path, operation)).length
      return ctx.ui.list({
        title: 'Media Actions', subtitle: paths.length ? `${paths.length} Finder file${paths.length === 1 ? '' : 's'} selected · originals are preserved` : 'Select files in Finder before running an action',
        searchBarPlaceholder: 'Filter media actions…',
        items: [
          { id: 'compress', title: 'Compress Media', subtitle: 'Keep output only when smaller · images and videos', icon: 'file-down', accessories: [{ text: `${count('compress')} supported` }], primaryAction: ctx.actions.ref('open-compress', undefined, { useCapturedSelection: true }) },
          { id: 'convert', title: 'Convert to Compatible Format', subtitle: 'Images → JPG · videos → H.264 MP4 · with compression', icon: 'arrow-right-left', accessories: [{ text: `${count('convert')} supported` }], primaryAction: ctx.actions.ref('open-convert', undefined, { useCapturedSelection: true }) },
          { id: 'half', title: 'Resize Images to Half (50%)', subtitle: 'Half-size dimensions · compress JPG and optimize PNG', icon: 'shrink', accessories: [{ text: `${count('half')} supported` }], primaryAction: ctx.actions.ref('open-half', undefined, { useCapturedSelection: true }) },
          { id: 'speed', title: 'Speed Up Media', subtitle: '1.3x, 1.5x, or 2.0x · videos and GIFs', icon: 'fast-forward', accessories: [{ text: `${count('speed')} supported` }], primaryAction: ctx.actions.ref('open-speed', undefined, { useCapturedSelection: true }) },
        ],
      })
    },
  }],
  actions(ctx) {
    return [
      ...(['compress', 'convert', 'half'] as const).map(operation => ctx.action({
        id: `open-${operation}`, title: TITLES[operation], icon: operation === 'compress' ? 'file-down' : operation === 'convert' ? 'arrow-right-left' : 'shrink', placement: ['hidden'],
        run: (ctx, action) => previewOperation(ctx, operation, action.useCapturedSelection ? ctx.state['hubSelection'] as string[] | undefined : undefined),
      })),
      ctx.action({ id: 'open-speed', title: 'Speed Up Media', icon: 'fast-forward', placement: ['hidden'], run: (ctx, action) => speedMenu(ctx, action.useCapturedSelection ? ctx.state['hubSelection'] as string[] | undefined : undefined) }),
      ...(['compress', 'convert', 'half'] as const).map(operation => ctx.action({
        id: BATCH[operation], title: operation === 'compress' ? 'Compress All' : operation === 'convert' ? 'Convert & Compress All' : 'Resize & Compress (50%)', icon: 'play', placement: ['hidden'],
        run: ctx => processBatch(ctx, operation),
      })),
      ...SPEEDS.map(speed => ctx.action({
        id: `speed-${speed.value}`, title: `Speed Up Media ${speed.label}`, subtitle: 'Selected Finder videos and GIFs', icon: 'fast-forward',
        run: (ctx, action) => processSpeed(ctx, speed, action.useCapturedSelection === true),
      })),
    ]
  },
} satisfies NevermindExtension
