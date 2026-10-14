import type { NevermindExtension, ExtensionActionResult, ExtensionContext } from './nevermind-extension-api'

const IMAGE_EXTENSIONS = ['jpg', 'jpeg', 'png', 'heic', 'tiff', 'tif', 'webp']
const VIDEO_EXTENSIONS = ['mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v']

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
  let candidate = `${stem}-compressed.${outputExtension}`
  let suffix = 2
  while (await pathExists(ctx, candidate)) {
    candidate = `${stem}-compressed-${suffix}.${outputExtension}`
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
  id: 'media-compressor',
  title: 'Media Compressor',
  capabilities: ['desktop.files', 'system'],
  commands: [
    {
      id: 'compress-media-files',
      title: 'Compress Selected Media',
      subtitle: 'Keep the result only when it is actually smaller',
      icon: 'file-down',
      async run(ctx): Promise<ExtensionActionResult> {
        const targetPaths = await selectedMedia(ctx)

        if (targetPaths.length === 0) {
          return ctx.ui.error('No Media Selected', 'Select one or more supported images or videos in Finder first.')
        }

        return ctx.ui.list({
          title: 'Compress Media',
          subtitle: `${targetPaths.length} selected · larger results are discarded`,
          items: targetPaths.map((filePath) => {
            const isVideo = VIDEO_EXTENSIONS.includes(extensionOf(filePath))
            return {
              id: filePath,
              title: basename(filePath),
              subtitle: isVideo ? 'Video' : 'Image',
              icon: isVideo ? 'video' : 'image',
              primaryAction: ctx.actions.ref('batch-compress'),
            }
          }),
          actions: [ctx.actions.ref('batch-compress')],
        })
      },
    },
  ],
  actions(ctx) {
    return [
      ctx.action({
        id: 'batch-compress',
        title: 'Compress All',
        icon: 'play',
        placement: ['hidden'],
        async run(ctx) {
          const targetPaths = await selectedMedia(ctx)
          if (targetPaths.length === 0) {
            return ctx.ui.error('Selection Changed', 'The selected media files are no longer available.')
          }

          const hasVideos = targetPaths.some((path) => VIDEO_EXTENSIONS.includes(extensionOf(path)))
          const ffmpegCheck = hasVideos ? await ctx.desktop.shell?.which('ffmpeg') : null
          if (hasVideos && (!ffmpegCheck || ffmpegCheck.exitCode !== 0)) {
            return ctx.ui.error('FFmpeg Missing', 'Video compression requires FFmpeg. Install it with Homebrew: brew install ffmpeg')
          }

          const pngquantCheck = targetPaths.some((path) => extensionOf(path) === 'png')
            ? await ctx.desktop.shell?.which('pngquant')
            : null
          const hasPngquant = pngquantCheck?.exitCode === 0

          const indicatorId = 'media-compressor-progress'
          ctx.ui.indicator.show({
            id: indicatorId,
            title: 'Compressing media',
            subtitle: `Preparing 1 of ${targetPaths.length}`,
            status: 'loading',
            value: 0,
            total: targetPaths.length,
          })

          const saved: Array<{ source: string; output: string; before: number; after: number }> = []
          const skipped: Array<{ source: string; reason: string }> = []
          const errors: Array<{ source: string; reason: string }> = []

          try {
            for (let index = 0; index < targetPaths.length; index++) {
              const sourcePath = targetPaths[index]
              const fileName = basename(sourcePath)
              const sourceExt = extensionOf(sourcePath)
              const isVideo = VIDEO_EXTENSIONS.includes(sourceExt)
              const outputExt = isVideo || sourceExt === 'png' ? sourceExt : 'jpg'
              const token = `${Date.now()}-${index}-${Math.random().toString(36).slice(2)}`
              const temporaryPath = `${withoutExtension(sourcePath)}.nvm-compress-${token}.${outputExt}`

              ctx.ui.indicator.update({
                id: indicatorId,
                title: `Compressing ${fileName}`,
                subtitle: `${index + 1} of ${targetPaths.length}`,
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
                  result = await ctx.desktop.shell?.exec('ffmpeg', [
                    '-hide_banner', '-loglevel', 'error', '-i', sourcePath,
                    '-map_metadata', '-1',
                    '-vcodec', 'libx265', '-crf', '28', '-preset', 'fast',
                    '-vf', 'scale=1920:1920:force_original_aspect_ratio=decrease:force_divisible_by=2',
                    '-acodec', 'aac', '-b:a', '128k',
                    '-movflags', '+faststart', temporaryPath, '-y',
                  ])
                } else if (sourceExt === 'png' && hasPngquant) {
                  result = await ctx.desktop.shell?.exec('pngquant', [
                    '--quality', '55-85', '--speed', '1', '--strip', '--force',
                    '--output', temporaryPath, '--', sourcePath,
                  ])
                } else {
                  const format = sourceExt === 'png' ? 'png' : 'jpeg'
                  const args = ['-s', 'format', format]
                  if (format === 'jpeg') args.push('-s', 'formatOptions', '75')
                  args.push('-Z', '2048', sourcePath, '--out', temporaryPath)
                  result = await ctx.desktop.shell?.exec('sips', args)
                }

                if (!result || result.exitCode !== 0) {
                  throw new Error(result?.stderr.trim() || 'The encoder failed')
                }

                const candidateMetadata = await ctx.desktop.files?.metadata(temporaryPath)
                const candidateSize = candidateMetadata?.size
                if (typeof candidateSize !== 'number') throw new Error('Could not read the compressed file size')

                // The core guarantee: never publish an output unless it is strictly smaller.
                if (candidateSize >= sourceSize) {
                  await removeIfPresent(ctx, temporaryPath)
                  skipped.push({
                    source: sourcePath,
                    reason: `Already efficient (${formatBytes(sourceSize)}; candidate was ${formatBytes(candidateSize)})`,
                  })
                } else {
                  const outputPath = await uniqueOutputPath(ctx, sourcePath, outputExt)
                  const moveResult = await ctx.desktop.shell?.exec('/bin/mv', [temporaryPath, outputPath])
                  if (!moveResult || moveResult.exitCode !== 0) {
                    throw new Error(moveResult?.stderr.trim() || 'Could not save the compressed file')
                  }
                  saved.push({ source: sourcePath, output: outputPath, before: sourceSize, after: candidateSize })
                }
              } catch (error) {
                await removeIfPresent(ctx, temporaryPath)
                errors.push({ source: sourcePath, reason: error instanceof Error ? error.message : String(error) })
              }

              ctx.ui.indicator.update({
                id: indicatorId,
                title: `Compressed ${index + 1} of ${targetPaths.length}`,
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
          const items = [
            ...saved.map((item) => ({
              id: `saved:${item.output}`,
              title: basename(item.output),
              subtitle: `${formatBytes(item.before)} → ${formatBytes(item.after)} · saved ${Math.round((1 - item.after / item.before) * 100)}%`,
              icon: 'circle-check',
              appearance: { foreground: 'green' as const },
              primaryAction: ctx.actions.revealPath(item.output),
              actions: [ctx.actions.openPath(item.output), ctx.actions.quickLook(item.output)],
            })),
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
            ? `${saved.length} smaller output${saved.length === 1 ? '' : 's'} · ${formatBytes(totalBefore - totalAfter)} saved · ${skipped.length} skipped`
            : `No smaller output was possible · ${skipped.length} skipped${errors.length ? ` · ${errors.length} failed` : ''}`

          return ctx.navigation.replace(ctx.ui.list({
            title: 'Compression Results',
            subtitle: summary,
            items,
            emptyView: { title: 'Nothing to compress', subtitle: 'No output files were created.' },
          }))
        },
      }),
    ]
  },
} satisfies NevermindExtension
