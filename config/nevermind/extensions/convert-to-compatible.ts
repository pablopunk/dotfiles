import type { NevermindExtension, ExtensionActionResult, ExtensionContext } from './nevermind-extension-api'

const IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'heic', 'heif', 'tiff', 'tif', 'webp', 'bmp', 'gif', 'avif']
const VIDEO_EXTENSIONS = ['mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v', 'flv', 'wmv', 'ts']

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

function isSameFormat(sourceExt: string, targetExt: string): boolean {
  if (sourceExt === targetExt) return true
  if ((sourceExt === 'jpg' || sourceExt === 'jpeg') && targetExt === 'jpg') return true
  return false
}

async function pathExists(ctx: ExtensionContext, filePath: string): Promise<boolean> {
  const result = await ctx.desktop.shell?.exec('/usr/bin/test', ['-e', filePath])
  return result?.exitCode === 0
}

async function uniqueOutputPath(ctx: ExtensionContext, sourcePath: string, outputExtension: string): Promise<string> {
  const stem = withoutExtension(sourcePath)
  let candidate = `${stem}-compatible.${outputExtension}`
  let suffix = 2
  while (await pathExists(ctx, candidate)) {
    candidate = `${stem}-compatible-${suffix}.${outputExtension}`
    suffix++
  }
  return candidate
}

async function removeIfPresent(ctx: ExtensionContext, filePath: string): Promise<void> {
  await ctx.desktop.shell?.exec('/bin/rm', ['-f', filePath])
}

async function selectedMedia(ctx: ExtensionContext): Promise<string[]> {
  const paths = await ctx.desktop.selection.files()
  return (paths || []).filter((filePath) => {
    const ext = extensionOf(filePath)
    return IMAGE_EXTENSIONS.includes(ext) || VIDEO_EXTENSIONS.includes(ext)
  })
}

export default {
  id: 'convert-to-compatible',
  title: 'Convert to Compatible Format',
  capabilities: ['desktop.files', 'system'],
  commands: [
    {
      id: 'convert-media-compatible',
      title: 'Convert to Compatible Format',
      subtitle: 'Convert selected images to JPG and videos to MP4 with compression',
      icon: 'arrow-right-left',
      async run(ctx): Promise<ExtensionActionResult> {
        const targetPaths = await selectedMedia(ctx)

        if (targetPaths.length === 0) {
          return ctx.ui.error('No Media Selected', 'Select one or more images or videos in Finder first.')
        }

        return ctx.ui.list({
          title: 'Convert to Compatible Format',
          subtitle: `${targetPaths.length} selected · images → JPG, videos → MP4`,
          items: targetPaths.map((filePath) => {
            const ext = extensionOf(filePath)
            const isVideo = VIDEO_EXTENSIONS.includes(ext)
            const targetExt = isVideo ? 'mp4' : 'jpg'
            return {
              id: filePath,
              title: basename(filePath),
              subtitle: `${ext.toUpperCase()} → ${targetExt.toUpperCase()} (compressed)`,
              icon: isVideo ? 'video' : 'image',
              primaryAction: ctx.actions.ref('batch-convert'),
              actions: [
                ctx.actions.ref('batch-convert'),
                ctx.actions.revealPath(filePath, 'Reveal in Finder'),
                ctx.actions.quickLook(filePath, 'Quick Look'),
              ],
            }
          }),
          actions: [ctx.actions.ref('batch-convert')],
        })
      },
    },
  ],
  actions(ctx) {
    return [
      ctx.action({
        id: 'batch-convert',
        title: 'Convert & Compress All',
        icon: 'play',
        placement: ['hidden'],
        async run(ctx) {
          const targetPaths = await selectedMedia(ctx)
          if (targetPaths.length === 0) {
            return ctx.ui.error('Selection Changed', 'The selected media files are no longer available in Finder.')
          }

          const hasVideos = targetPaths.some((path) => VIDEO_EXTENSIONS.includes(extensionOf(path)))
          const ffmpegCheck = hasVideos ? await ctx.desktop.shell?.which('ffmpeg') : null
          if (hasVideos && (!ffmpegCheck || ffmpegCheck.exitCode !== 0)) {
            return ctx.ui.error('FFmpeg Missing', 'Video conversion requires FFmpeg. Install it with Homebrew: brew install ffmpeg')
          }

          const indicatorId = 'convert-compatible-progress'
          ctx.ui.indicator.show({
            id: indicatorId,
            title: 'Converting media',
            subtitle: `Preparing 1 of ${targetPaths.length}`,
            status: 'loading',
            value: 0,
            total: targetPaths.length,
          })

          const saved: Array<{ source: string; output: string; before: number; after: number; targetExt: string }> = []
          const skipped: Array<{ source: string; reason: string }> = []
          const errors: Array<{ source: string; reason: string }> = []

          try {
            for (let index = 0; index < targetPaths.length; index++) {
              const sourcePath = targetPaths[index]
              const fileName = basename(sourcePath)
              const sourceExt = extensionOf(sourcePath)
              const isVideo = VIDEO_EXTENSIONS.includes(sourceExt)
              const outputExt = isVideo ? 'mp4' : 'jpg'
              const token = `${Date.now()}-${index}-${Math.random().toString(36).slice(2)}`
              const temporaryPath = `${withoutExtension(sourcePath)}.nvm-convert-${token}.${outputExt}`

              ctx.ui.indicator.update({
                id: indicatorId,
                title: `Converting ${fileName}`,
                subtitle: `${index + 1} of ${targetPaths.length} (${outputExt.toUpperCase()})`,
                status: 'loading',
                value: index,
                total: targetPaths.length,
              })

              try {
                const sourceMetadata = await ctx.desktop.files?.metadata(sourcePath)
                const sourceSize = sourceMetadata?.size
                if (typeof sourceSize !== 'number') throw new Error('Could not read the original file size')

                let result
                if (isVideo) {
                  // MP4 with H.264 + AAC + yuv420p is the most universally compatible video format across all OSes, browsers, and devices
                  result = await ctx.desktop.shell?.exec('ffmpeg', [
                    '-hide_banner', '-loglevel', 'error', '-i', sourcePath,
                    '-map_metadata', '-1',
                    '-c:v', 'libx264', '-crf', '23', '-preset', 'fast',
                    '-pix_fmt', 'yuv420p',
                    '-vf', 'scale=1920:1920:force_original_aspect_ratio=decrease:force_divisible_by=2',
                    '-c:a', 'aac', '-b:a', '128k',
                    '-movflags', '+faststart',
                    temporaryPath, '-y',
                  ])
                } else {
                  // JPEG with sips (built-in macOS tool), capped to 2048px and quality 80
                  result = await ctx.desktop.shell?.exec('sips', [
                    '-s', 'format', 'jpeg',
                    '-s', 'formatOptions', '80',
                    '-Z', '2048',
                    sourcePath,
                    '--out', temporaryPath,
                  ])

                  // Fallback to ffmpeg for image formats sips might not decode (e.g. some webp/avif builds)
                  if (!result || result.exitCode !== 0) {
                    const fallbackCheck = await ctx.desktop.shell?.which('ffmpeg')
                    if (fallbackCheck?.exitCode === 0) {
                      result = await ctx.desktop.shell?.exec('ffmpeg', [
                        '-hide_banner', '-loglevel', 'error',
                        '-i', sourcePath,
                        '-vframes', '1',
                        '-vf', 'scale=2048:2048:force_original_aspect_ratio=decrease:force_divisible_by=2',
                        '-q:v', '3',
                        temporaryPath, '-y',
                      ])
                    }
                  }
                }

                if (!result || result.exitCode !== 0) {
                  throw new Error(result?.stderr.trim() || 'Conversion failed')
                }

                const candidateMetadata = await ctx.desktop.files?.metadata(temporaryPath)
                const candidateSize = candidateMetadata?.size
                if (typeof candidateSize !== 'number') throw new Error('Could not read the converted file size')

                // If already in the target format and not smaller, skip creating redundant file
                if (isSameFormat(sourceExt, outputExt) && candidateSize >= sourceSize) {
                  await removeIfPresent(ctx, temporaryPath)
                  skipped.push({
                    source: sourcePath,
                    reason: `Already optimal ${outputExt.toUpperCase()} (${formatBytes(sourceSize)}; candidate was ${formatBytes(candidateSize)})`,
                  })
                } else {
                  const outputPath = await uniqueOutputPath(ctx, sourcePath, outputExt)
                  const moveResult = await ctx.desktop.shell?.exec('/bin/mv', [temporaryPath, outputPath])
                  if (!moveResult || moveResult.exitCode !== 0) {
                    throw new Error(moveResult?.stderr.trim() || 'Could not save the converted file')
                  }
                  saved.push({
                    source: sourcePath,
                    output: outputPath,
                    before: sourceSize,
                    after: candidateSize,
                    targetExt: outputExt.toUpperCase(),
                  })
                }
              } catch (error) {
                await removeIfPresent(ctx, temporaryPath)
                errors.push({ source: sourcePath, reason: error instanceof Error ? error.message : String(error) })
              }

              ctx.ui.indicator.update({
                id: indicatorId,
                title: `Converted ${index + 1} of ${targetPaths.length}`,
                subtitle: basename(sourcePath),
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
              const savedPercent = item.before > item.after
                ? Math.round((1 - item.after / item.before) * 100)
                : 0
              const subtitle = savedPercent > 0
                ? `${formatBytes(item.before)} → ${formatBytes(item.after)} · saved ${savedPercent}% (${item.targetExt})`
                : `${formatBytes(item.before)} → ${formatBytes(item.after)} · converted to ${item.targetExt}`

              return {
                id: `saved:${item.output}`,
                title: basename(item.output),
                subtitle,
                icon: 'circle-check',
                appearance: { foreground: 'green' as const },
                primaryAction: ctx.actions.revealPath(item.output),
                actions: [
                  ctx.actions.openPath(item.output, 'Open'),
                  ctx.actions.quickLook(item.output, 'Quick Look'),
                  ctx.actions.revealPath(item.output, 'Reveal in Finder'),
                ],
              }
            }),
            ...skipped.map((item) => ({
              id: `skipped:${item.source}`,
              title: basename(item.source),
              subtitle: `Skipped · ${item.reason}`,
              icon: 'shield-check',
              appearance: { foreground: 'yellow' as const },
              primaryAction: ctx.actions.revealPath(item.source),
            })),
            ...errors.map((item) => ({
              id: `error:${item.source}`,
              title: basename(item.source),
              subtitle: `Failed · ${item.reason}`,
              icon: 'circle-x',
              appearance: { foreground: 'red' as const },
              primaryAction: ctx.actions.revealPath(item.source),
            })),
          ]

          const summary = saved.length > 0
            ? `${saved.length} file${saved.length === 1 ? '' : 's'} converted${netSaved > 0 ? ` · ${formatBytes(netSaved)} saved` : ''}${skipped.length ? ` · ${skipped.length} skipped` : ''}`
            : `No conversions needed${skipped.length ? ` · ${skipped.length} skipped` : ''}${errors.length ? ` · ${errors.length} failed` : ''}`

          return ctx.navigation.replace(ctx.ui.list({
            title: 'Conversion Results',
            subtitle: summary,
            items,
            emptyView: { title: 'No files converted', subtitle: 'No output files were created.' },
          }))
        },
      }),
    ]
  },
} satisfies NevermindExtension
