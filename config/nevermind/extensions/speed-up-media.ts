import type { NevermindExtension, ExtensionActionResult, ExtensionContext } from './nevermind-extension-api'

/**
 * Speed Up Media extension
 * Allows users to speed up videos and GIFs selected in Finder.
 * Uses FFmpeg with x265 encoding to ensure high quality and smaller file sizes.
 */

const VIDEO_EXTENSIONS = ['mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v']
const GIF_EXTENSIONS = ['gif']

export default {
  id: 'speed-up-media',
  title: 'Speed Up Media',
  permissions: ['desktop.files', 'system'],
  commands: [
    {
      id: 'speed-up-files',
      title: 'Speed Up Selected Media',
      subtitle: 'Change playback speed for videos and GIFs',
      icon: 'fast-forward',
      async run(ctx): Promise<ExtensionActionResult> {
        const filePaths = await ctx.desktop.selection.files()
        
        if (!filePaths || filePaths.length === 0) {
          return ctx.ui.error('No Files Selected', 'Select one or more videos or GIFs in Finder first.')
        }

        const targetPaths = filePaths.filter(f => {
          const ext = f.split('.').pop()?.toLowerCase() || ''
          return VIDEO_EXTENSIONS.includes(ext) || GIF_EXTENSIONS.includes(ext)
        })

        if (targetPaths.length === 0) {
          return ctx.ui.error('No Media Selected', 'Please select supported video files or GIFs.')
        }

        const speeds = [
          { label: '1.3x', value: 1.3 },
          { label: '1.5x', value: 1.5 },
          { label: '2.0x', value: 2.0 },
        ]

        return ctx.ui.list({
          title: 'Select Speed',
          subtitle: `${targetPaths.length} items selected`,
          items: speeds.map(speed => ({
            id: `speed-${speed.value}`,
            title: `Speed up by ${speed.label}`,
            icon: 'zap',
            primaryAction: ctx.actions.run(`Apply ${speed.label}`, async (ctx) => {
              // Check for FFmpeg
              const ffmpegCheck = await ctx.desktop.shell?.which('ffmpeg')
              if (!ffmpegCheck || ffmpegCheck.exitCode !== 0) {
                return ctx.ui.error(
                  'FFmpeg Missing', 
                  'Speeding up media requires FFmpeg. Install it via Homebrew: "brew install ffmpeg"'
                )
              }

              let successCount = 0
              let errorCount = 0
              const errors: string[] = []

              for (const path of targetPaths) {
                const fileExt = path.split('.').pop()?.toLowerCase() || ''
                const dotIndex = path.lastIndexOf('.')
                const pathWithoutExt = dotIndex !== -1 ? path.substring(0, dotIndex) : path
                const outPath = `${pathWithoutExt}-${speed.label.replace('.', '_')}.${fileExt}`
                
                try {
                  let result
                  if (fileExt === 'gif') {
                    // GIFs don't have audio
                    result = await ctx.desktop.shell?.exec('ffmpeg', [
                      '-i', path,
                      '-vf', `setpts=${(1 / speed.value).toFixed(4)}*PTS`,
                      outPath,
                      '-y'
                    ])
                  } else {
                    /**
                     * Video Speed & Compression Optimization:
                     * 1. Check for audio stream presence.
                     * 2. Apply speed filters (setpts for video, atempo for audio).
                     * 3. Apply x265 compression (CRF 28) similar to media-compressor.
                     */
                    const probe = await ctx.desktop.shell?.exec('ffprobe', [
                      '-show_streams', '-select_streams', 'a', '-loglevel', 'error', path
                    ])
                    const hasAudio = probe?.stdout && probe.stdout.trim().length > 0

                    const commonArgs = [
                      '-i', path,
                      '-vcodec', 'libx265',
                      '-crf', '28', // Same as media-compressor for significant size reduction
                      '-preset', 'fast',
                      '-acodec', 'aac',
                      '-b:a', '128k',
                      '-movflags', '+faststart',
                      outPath,
                      '-y'
                    ]

                    if (hasAudio) {
                      result = await ctx.desktop.shell?.exec('ffmpeg', [
                        '-i', path,
                        '-filter_complex', `[0:v]setpts=${(1 / speed.value).toFixed(4)}*PTS[v];[0:a]atempo=${speed.value}[a]`,
                        '-map', '[v]',
                        '-map', '[a]',
                        ...commonArgs.slice(2) // Skip the -i path since filter_complex handles inputs
                      ])
                    } else {
                      result = await ctx.desktop.shell?.exec('ffmpeg', [
                        '-i', path,
                        '-vf', `setpts=${(1 / speed.value).toFixed(4)}*PTS`,
                        ...commonArgs.slice(2)
                      ])
                    }
                  }

                  if (result?.exitCode === 0) {
                    successCount++
                  } else {
                    errorCount++
                    errors.push(`${path.split('/').pop()}: ${result?.stderr || 'Unknown error'}`)
                  }
                } catch (err) {
                  errorCount++
                  errors.push(`${path.split('/').pop()}: ${err instanceof Error ? err.message : String(err)}`)
                }
              }

              if (errorCount > 0) {
                return ctx.ui.error('Results', `${successCount} succeeded, ${errorCount} failed.\n\n${errors.join('\n')}`)
              }

              return ctx.ui.toast({ message: `Successfully sped up and compressed ${successCount} files!` })
            })
          }))
        })
      },
    },
  ],
} satisfies NevermindExtension
