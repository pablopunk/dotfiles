import type { NevermindExtension, ExtensionActionResult, ExtensionContext } from './nevermind-extension-api'

const IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'heic', 'heif', 'tiff', 'tif', 'webp', 'bmp', 'avif', 'gif']

function extensionOf(filePath: string): string {
  return filePath.split('.').pop()?.toLowerCase() || ''
}

function basename(filePath: string): string {
  return filePath.split('/').pop() || 'File'
}

function withoutExtension(filePath: string): string {
  const slash = filePath.lastIndexOf('/')
  const dot = filePath.lastIndexOf('.')
  return dot > slash ? filePath.slice(0, dot) : filePath
}

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

async function pathExists(ctx: ExtensionContext, filePath: string): Promise<boolean> {
  const result = await ctx.desktop.shell?.exec('/usr/bin/test', ['-e', filePath])
  return result?.exitCode === 0
}

async function uniqueOutputPath(ctx: ExtensionContext, sourcePath: string, outputExtension: string): Promise<string> {
  const stem = withoutExtension(sourcePath)
  let candidate = `${stem}-half.${outputExtension}`
  let suffix = 2
  while (await pathExists(ctx, candidate)) {
    candidate = `${stem}-half-${suffix}.${outputExtension}`
    suffix++
  }
  return candidate
}

async function removeIfPresent(ctx: ExtensionContext, filePath: string): Promise<void> {
  await ctx.desktop.shell?.exec('/bin/rm', ['-f', filePath])
}

async function selectedImages(ctx: ExtensionContext): Promise<string[]> {
  const paths = await ctx.desktop.selection.files()
  return (paths || []).filter((filePath) => {
    const ext = extensionOf(filePath)
    return IMAGE_EXTENSIONS.includes(ext)
  })
}

async function getImageDimensions(ctx: ExtensionContext, filePath: string): Promise<{ width: number; height: number } | null> {
  try {
    const meta = await ctx.desktop.files?.metadata(filePath)
    if (meta?.width && meta?.height) {
      return { width: meta.width, height: meta.height }
    }
  } catch {
    // Ignore and try shell fallback
  }

  const sipsResult = await ctx.desktop.shell?.exec('sips', ['-g', 'pixelWidth', '-g', 'pixelHeight', filePath])
  if (sipsResult && sipsResult.exitCode === 0) {
    const widthMatch = sipsResult.stdout.match(/pixelWidth:\s*(\d+)/)
    const heightMatch = sipsResult.stdout.match(/pixelHeight:\s*(\d+)/)
    if (widthMatch && heightMatch) {
      return {
        width: parseInt(widthMatch[1], 10),
        height: parseInt(heightMatch[1], 10),
      }
    }
  }

  const ffprobeCheck = await ctx.desktop.shell?.which('ffprobe')
  if (ffprobeCheck?.exitCode === 0) {
    const probe = await ctx.desktop.shell?.exec('ffprobe', [
      '-v', 'error',
      '-select_streams', 'v:0',
      '-show_entries', 'stream=width,height',
      '-of', 'csv=s=x:p=0',
      filePath,
    ])
    if (probe && probe.exitCode === 0) {
      const parts = probe.stdout.trim().split('x')
      if (parts.length === 2) {
        const w = parseInt(parts[0], 10)
        const h = parseInt(parts[1], 10)
        if (!isNaN(w) && !isNaN(h)) {
          return { width: w, height: h }
        }
      }
    }
  }

  return null
}

export default {
  id: 'resize-image-half',
  title: 'Resize Image to Half',
  capabilities: ['desktop.files', 'system'],
  commands: [
    {
      id: 'resize-image-to-half',
      title: 'Resize Image to Half (50%)',
      subtitle: 'Scale selected Finder images down to 50% and compress',
      icon: 'shrink',
      aliases: ['resize half', '50%', 'half size', 'compress half', 'scale 50'],
      async run(ctx): Promise<ExtensionActionResult> {
        const targetPaths = await selectedImages(ctx)

        if (targetPaths.length === 0) {
          return ctx.ui.error('No Images Selected', 'Select one or more image files in Finder first.')
        }

        const itemsWithDetails = await Promise.all(
          targetPaths.map(async (filePath) => {
            const dims = await getImageDimensions(ctx, filePath)
            const meta = await ctx.desktop.files?.metadata(filePath).catch(() => null)
            const sizeStr = meta?.size ? ` · ${formatBytes(meta.size)}` : ''
            const dimsStr = dims
              ? `${dims.width} × ${dims.height} → ${Math.max(1, Math.round(dims.width * 0.5))} × ${Math.max(1, Math.round(dims.height * 0.5))}`
              : 'Scale to 50%'

            return {
              id: filePath,
              title: basename(filePath),
              subtitle: `${dimsStr}${sizeStr}`,
              image: ctx.desktop.files?.toFileUrl(filePath),
              icon: 'image',
              primaryAction: ctx.actions.ref('batch-resize-half'),
              actions: [
                ctx.actions.ref('batch-resize-half'),
                ctx.actions.quickLook(filePath, 'Quick Look'),
                ctx.actions.revealPath(filePath, 'Reveal in Finder'),
              ],
            }
          }),
        )

        return ctx.ui.list({
          title: 'Resize to Half (50%)',
          subtitle: `${targetPaths.length} image${targetPaths.length === 1 ? '' : 's'} selected · Enter to resize & compress`,
          items: itemsWithDetails,
          actions: [ctx.actions.ref('batch-resize-half')],
        })
      },
    },
  ],
  actions(ctx) {
    return [
      ctx.action({
        id: 'batch-resize-half',
        title: 'Resize & Compress (50%)',
        icon: 'play',
        placement: ['hidden'],
        async run(ctx) {
          const targetPaths = await selectedImages(ctx)
          if (targetPaths.length === 0) {
            return ctx.ui.error('Selection Changed', 'The selected image files are no longer available in Finder.')
          }

          const pngquantCheck = targetPaths.some((p) => extensionOf(p) === 'png')
            ? await ctx.desktop.shell?.which('pngquant')
            : null
          const hasPngquant = pngquantCheck?.exitCode === 0

          const indicatorId = 'resize-half-progress'
          ctx.ui.indicator.show({
            id: indicatorId,
            title: 'Resizing images to 50%',
            subtitle: `Processing 1 of ${targetPaths.length}`,
            status: 'loading',
            value: 0,
            total: targetPaths.length,
          })

          const saved: Array<{
            source: string
            output: string
            before: number
            after: number
            origDims: string
            newDims: string
          }> = []
          const errors: Array<{ source: string; reason: string }> = []

          try {
            for (let index = 0; index < targetPaths.length; index++) {
              const sourcePath = targetPaths[index]
              const fileName = basename(sourcePath)
              const sourceExt = extensionOf(sourcePath)
              const outputExt = sourceExt === 'jpeg' ? 'jpg' : sourceExt
              const token = `${Date.now()}-${index}-${Math.random().toString(36).slice(2)}`
              const temporaryPath = `${withoutExtension(sourcePath)}.nvm-half-${token}.${outputExt}`

              ctx.ui.indicator.update({
                id: indicatorId,
                title: `Resizing ${fileName}`,
                subtitle: `${index + 1} of ${targetPaths.length}`,
                status: 'loading',
                value: index,
                total: targetPaths.length,
              })

              try {
                const sourceMetadata = await ctx.desktop.files?.metadata(sourcePath)
                const sourceSize = sourceMetadata?.size
                if (typeof sourceSize !== 'number') {
                  throw new Error('Could not read original file size')
                }

                const dims = await getImageDimensions(ctx, sourcePath)
                const targetWidth = dims?.width ? Math.max(1, Math.round(dims.width * 0.5)) : null
                const origDimsStr = dims ? `${dims.width} × ${dims.height}` : 'Original'

                let result
                if (targetWidth) {
                  const sipsArgs = ['--resampleWidth', String(targetWidth)]
                  if (sourceExt === 'jpg' || sourceExt === 'jpeg') {
                    sipsArgs.push('-s', 'format', 'jpeg', '-s', 'formatOptions', '80')
                  }
                  sipsArgs.push(sourcePath, '--out', temporaryPath)
                  result = await ctx.desktop.shell?.exec('sips', sipsArgs)
                }

                // Fallback to ffmpeg if sips failed or dimensions couldn't be resolved with sips
                if (!result || result.exitCode !== 0) {
                  const ffmpegCheck = await ctx.desktop.shell?.which('ffmpeg')
                  if (ffmpegCheck?.exitCode === 0) {
                    const vfFilter = targetWidth
                      ? `scale=${targetWidth}:-2`
                      : 'scale=iw*0.5:ih*0.5'
                    result = await ctx.desktop.shell?.exec('ffmpeg', [
                      '-hide_banner', '-loglevel', 'error',
                      '-i', sourcePath,
                      '-vframes', '1',
                      '-vf', vfFilter,
                      temporaryPath, '-y',
                    ])
                  }
                }

                if (!result || result.exitCode !== 0) {
                  throw new Error(result?.stderr.trim() || 'Resizing failed')
                }

                // Optimize PNG with pngquant if available
                if (outputExt === 'png' && hasPngquant) {
                  const quantizedTemp = `${temporaryPath}.opt.png`
                  const quantResult = await ctx.desktop.shell?.exec('pngquant', [
                    '--quality', '65-85', '--speed', '1', '--strip', '--force',
                    '--output', quantizedTemp, '--', temporaryPath,
                  ])
                  if (quantResult?.exitCode === 0) {
                    await ctx.desktop.shell?.exec('/bin/mv', [quantizedTemp, temporaryPath])
                  } else {
                    await removeIfPresent(ctx, quantizedTemp)
                  }
                }

                const candidateMetadata = await ctx.desktop.files?.metadata(temporaryPath)
                const candidateSize = candidateMetadata?.size
                if (typeof candidateSize !== 'number') {
                  throw new Error('Could not read resized file size')
                }

                const outputPath = await uniqueOutputPath(ctx, sourcePath, outputExt)
                const moveResult = await ctx.desktop.shell?.exec('/bin/mv', [temporaryPath, outputPath])
                if (!moveResult || moveResult.exitCode !== 0) {
                  throw new Error(moveResult?.stderr.trim() || 'Could not save the resized file')
                }

                const newDims = await getImageDimensions(ctx, outputPath)
                const newDimsStr = newDims ? `${newDims.width} × ${newDims.height}` : '50%'

                saved.push({
                  source: sourcePath,
                  output: outputPath,
                  before: sourceSize,
                  after: candidateSize,
                  origDims: origDimsStr,
                  newDims: newDimsStr,
                })
              } catch (error) {
                await removeIfPresent(ctx, temporaryPath)
                errors.push({
                  source: sourcePath,
                  reason: error instanceof Error ? error.message : String(error),
                })
              }

              ctx.ui.indicator.update({
                id: indicatorId,
                title: `Resized ${index + 1} of ${targetPaths.length}`,
                subtitle: fileName,
                status: 'loading',
                value: index + 1,
                total: targetPaths.length,
              })
            }
          } finally {
            ctx.ui.indicator.hide(indicatorId)
          }

          const totalBefore = saved.reduce((sum, item) => sum + item.before, 0)
          const totalAfter = saved.reduce((sum, item) => sum + item.after, 0)
          const netSaved = totalBefore - totalAfter

          const items = [
            ...saved.map((item) => {
              const percentSaved = item.before > item.after
                ? Math.round((1 - item.after / item.before) * 100)
                : 0
              const sizeReduction = percentSaved > 0
                ? `${formatBytes(item.before)} → ${formatBytes(item.after)} · saved ${percentSaved}%`
                : `${formatBytes(item.before)} → ${formatBytes(item.after)}`

              return {
                id: `saved:${item.output}`,
                title: basename(item.output),
                subtitle: `${item.origDims} → ${item.newDims} · ${sizeReduction}`,
                image: ctx.desktop.files?.toFileUrl(item.output),
                icon: 'circle-check',
                appearance: { foreground: 'green' as const },
                primaryAction: ctx.actions.revealPath(item.output, 'Reveal in Finder'),
                actions: [
                  ctx.actions.revealPath(item.output, 'Reveal in Finder'),
                  ctx.actions.openPath(item.output, 'Open'),
                  ctx.actions.quickLook(item.output, 'Quick Look'),
                  ctx.actions.copyText(item.output, 'Copy Output Path'),
                ],
              }
            }),
            ...errors.map((item) => ({
              id: `error:${item.source}`,
              title: basename(item.source),
              subtitle: `Failed · ${item.reason}`,
              icon: 'circle-x',
              appearance: { foreground: 'red' as const },
              primaryAction: ctx.actions.revealPath(item.source, 'Reveal in Finder'),
            })),
          ]

          const summary = saved.length > 0
            ? `${saved.length} image${saved.length === 1 ? '' : 's'} resized to 50%${netSaved > 0 ? ` · ${formatBytes(netSaved)} saved` : ''}${errors.length ? ` · ${errors.length} failed` : ''}`
            : `Resizing failed${errors.length ? ` · ${errors.length} error${errors.length === 1 ? '' : 's'}` : ''}`

          return ctx.navigation.replace(
            ctx.ui.list({
              title: 'Resize Results',
              subtitle: summary,
              items,
              emptyView: { title: 'No files resized', subtitle: 'No output images were created.' },
            }),
          )
        },
      }),
    ]
  },
} satisfies NevermindExtension
