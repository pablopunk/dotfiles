import type { NevermindExtension } from './nevermind-extension-api'

// Resolve home directory dynamically without triggering compiler warnings about Node.js types
const home = (globalThis as any).process?.env?.HOME || '/Users/unknown'
const ROOTS = [
  `${home}/Desktop`,
  `${home}/Downloads`,
  `${home}/Documents/CleanShot X`,
]

// Module-level state persists in the active extension process memory.
let lastScanTime = 0
let isScanning = false

export default {
  id: 'screenshots',
  title: 'Screenshots',
  permissions: ['desktop.files'],
  commands: [
    {
      id: 'screenshots.grid',
      title: 'Screenshots',
      subtitle: 'Recent screenshots & screen recordings',
      icon: 'grid',
      aliases: ['screen shots', 'screen recordings', 'cleanshot'],
      // Configure declarative file watcher triggers so the host automatically
      // wakes up this command in the background whenever a screenshot is taken.
      // We resolve the roots to absolute paths using the global process context because
      // host-level file watchers (like Chokidar) do not expand '~' automatically.
      triggers: [
        {
          type: 'files.changed',
          roots: ROOTS,
          debounceMs: 500,
          kind: 'media',
        },
      ],
      async run(ctx) {
        const RESULT_LIMIT = 80
        const CACHE_KEY = 'screenshots-files-v2'

        const isVideoFile = (file: any) => {
          if (file.kind === 'video') return true
          const ext = (file.extension || file.name.split('.').pop() || '').toLowerCase()
          return ['mp4', 'mov', 'm4v', 'webm', 'mkv', 'avi'].includes(ext)
        }

        const cacheableFile = (file: any) => ({
          path: file.path,
          name: file.name,
          displayPath: file.displayPath,
          extension: file.extension,
          kind: file.kind,
          mtimeMs: file.mtimeMs,
          birthtimeMs: file.birthtimeMs,
          dateAddedMs: file.dateAddedMs,
          size: file.size,
        })

        const hydrateFile = (innerCtx: any, file: any) => {
          const fileUrl = innerCtx.desktop.files.toFileUrl(file.path)
          const thumbnailUrl = innerCtx.desktop.files.thumbnail(file.path)
          const fileIsVideo = isVideoFile(file)
          return {
            ...file,
            url: thumbnailUrl || fileUrl,
            fileUrl,
            videoUrl: fileIsVideo ? fileUrl : null,
            thumbnailUrl,
          }
        }

        const buildPreviewView = (activeCtx: any, files: any[], index: number) => {
          const file = files[index]
          if (!file) return null
          const nextIndex = (index + 1) % files.length
          const prevIndex = (index - 1 + files.length) % files.length
          const navigationActions = files.length > 1 ? [
            activeCtx.actions.run('Next', async (innerCtx: any) => innerCtx.navigation.replace(buildPreviewView(innerCtx, files, nextIndex)), { shortcut: 'Right' }),
            activeCtx.actions.run('Previous', async (innerCtx: any) => innerCtx.navigation.replace(buildPreviewView(innerCtx, files, prevIndex)), { shortcut: 'Left' }),
          ] : []

          const safeVideoUrl = file.videoUrl || file.url || (activeCtx.desktop.files ? activeCtx.desktop.files.toFileUrl(file.path) : '')
          const safeImageUrl = file.fileUrl || file.url || (activeCtx.desktop.files ? activeCtx.desktop.files.toFileUrl(file.path) : '')
          const fileIsVideo = isVideoFile(file)

          const adjustedFile = {
            ...file,
            kind: fileIsVideo ? 'video' : 'image',
            videoUrl: fileIsVideo ? safeVideoUrl : undefined,
            url: safeImageUrl,
          }

          return activeCtx.ui.preview(adjustedFile, {
            title: `${file.name} (${index + 1}/${files.length})`,
            size: 'large',
            actionPanelVisibility: 'hidden',
            video: fileIsVideo ? safeVideoUrl : undefined,
            videoUrl: fileIsVideo ? safeVideoUrl : undefined,
            image: safeImageUrl,
            actions: [
              ...navigationActions,
              !fileIsVideo ? activeCtx.actions.copyImage(file.path) : activeCtx.actions.copyText(file.path, 'Copy'),
              activeCtx.actions.copyText(file.path, 'Copy Path'),
              activeCtx.actions.quickLook(file.path),
              activeCtx.actions.revealPath(file.path),
            ].filter(Boolean),
          })
        }

        const mapFileToItem = (files: any[], file: any, index: number) => {
          // Bind Cmd+y as the shortcut for the Preview action so it triggers instantly when an item is selected!
          const previewAction = ctx.actions.push('Preview', buildPreviewView(ctx, files, index), { shortcut: 'Cmd+y' })
          const fallbackFileUrl = ctx.desktop.files ? ctx.desktop.files.toFileUrl(file.path) : ''
          const safeVideoUrl = file.videoUrl || file.fileUrl || fallbackFileUrl
          const tileImageUrl = file.thumbnailUrl || file.url || fallbackFileUrl
          const fileIsVideo = isVideoFile(file)

          return {
            id: file.path,
            title: file.name,
            subtitle: file.displayPath,
            ...(fileIsVideo
              ? { video: safeVideoUrl, videoUrl: safeVideoUrl, image: tileImageUrl }
              : { image: tileImageUrl }),
            primaryAction: previewAction,
            actions: [
              previewAction,
              !fileIsVideo ? ctx.actions.copyImage(file.path) : ctx.actions.copyText(file.path, 'Copy'),
              ctx.actions.copyText(file.path, 'Copy Path'),
              ctx.actions.quickLook(file.path),
              ctx.actions.revealPath(file.path),
              ctx.actions.openPath(file.path),
              ctx.actions.run('Open with…', async (innerCtx: any) => {
                const apps = await innerCtx.desktop.files.openWithApps(file.path)
                return innerCtx.ui.list({
                  title: 'Open with…',
                  items: apps.map((app: any) => ({
                    id: app.path || app.name,
                    title: app.name || 'Unknown App',
                    primaryAction: innerCtx.actions.openWith(file.path, app),
                  })),
                })
              }),
            ],
          }
        }

        if (!ctx.desktop?.files) throw new Error('Missing desktop.files permission or capability.')

        // 1. Load cached files first to ensure instant, non-blocking paint
        let filesData: any[] = []
        try {
          const cached = await ctx.storage.get<any[]>(CACHE_KEY)
          if (cached && Array.isArray(cached)) {
            filesData = cached
          }
        } catch (e) {
          ctx.logs.error('Failed to read screenshots cache', e)
        }

        // 2. Determine if we should trigger a directory scan.
        // We scan if:
        // - This run is explicitly woken up by a file change trigger or view refresh.
        // - The cache is completely empty.
        // - We haven't scanned in the last 5 seconds (rate-limiting).
        const isTriggerOrRefresh = !!ctx.launch
        const now = Date.now()
        const shouldScan = isTriggerOrRefresh || filesData.length === 0 || (!isScanning && now - lastScanTime > 5000)

        if (shouldScan) {
          if (isTriggerOrRefresh) {
            // Background / Host-owned runs are safe to execute synchronously to guarantee fresh data
            try {
              ctx.logs.info('Executing synchronous scan for file trigger/refresh...', { trigger: ctx.launch?.trigger })
              const freshFiles: any[] = []
              for (const root of ROOTS) {
                try {
                  const rootFiles = await ctx.desktop.files.findMedia([root], {
                    sortBy: 'added',
                    depth: 0,
                    limit: RESULT_LIMIT,
                  })
                  if (Array.isArray(rootFiles)) {
                    freshFiles.push(...rootFiles)
                  }
                } catch (e) {}
              }

              freshFiles.sort((a: any, b: any) => {
                const timeA = Math.max(a.dateAddedMs || 0, a.mtimeMs || 0, a.birthtimeMs || 0)
                const timeB = Math.max(b.dateAddedMs || 0, b.mtimeMs || 0, b.birthtimeMs || 0)
                return timeB - timeA
              })

              filesData = freshFiles.slice(0, RESULT_LIMIT)
              await ctx.storage.set(CACHE_KEY, filesData.map(cacheableFile))
              
              // Invalidate current UI so the changes reflect on screen live!
              ctx.views.invalidate()
            } catch (err) {
              ctx.logs.error('Failed in background synchronous scan', err)
            }
          } else {
            // For active user opens, we kick off scanning asynchronously so the cached paint is 100% instant!
            isScanning = true
            lastScanTime = now
            ;(async () => {
              try {
                ctx.logs.info('Starting non-blocking background screenshots scan...')
                const freshFiles: any[] = []
                for (const root of ROOTS) {
                  try {
                    const rootFiles = await ctx.desktop.files.findMedia([root], {
                      sortBy: 'added',
                      depth: 0,
                      limit: RESULT_LIMIT,
                    })
                    if (Array.isArray(rootFiles)) {
                      freshFiles.push(...rootFiles)
                    }
                  } catch (e) {}
                }

                freshFiles.sort((a: any, b: any) => {
                  const timeA = Math.max(a.dateAddedMs || 0, a.mtimeMs || 0, a.birthtimeMs || 0)
                  const timeB = Math.max(b.dateAddedMs || 0, b.mtimeMs || 0, b.birthtimeMs || 0)
                  return timeB - timeA
                })

                const sliced = freshFiles.slice(0, RESULT_LIMIT)
                await ctx.storage.set(CACHE_KEY, sliced.map(cacheableFile))
                ctx.logs.info('Background scan completed. Cache updated.', { count: sliced.length })
                ctx.views.invalidate()
              } catch (err) {
                ctx.logs.error('Failed in background scan', err)
              } finally {
                isScanning = false
              }
            })()
          }
        }

        const hydrated = filesData.map((f: any) => hydrateFile(ctx, f))
        const items = hydrated.map((f: any, i: number) => mapFileToItem(hydrated, f, i))

        return ctx.ui.grid({
          id: 'screenshots.grid',
          title: 'Screenshots',
          layout: 'wide',
          size: 'large',
          isLoading: filesData.length === 0,
          emptyView: { title: 'No screenshots', subtitle: 'No recent screenshots or screen recordings found.' },
          items,
        })
      },
    },
  ],
} satisfies NevermindExtension
