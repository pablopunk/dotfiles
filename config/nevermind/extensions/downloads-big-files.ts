import type { ExtensionContext, ExtensionItem, NevermindExtension } from './nevermind-extension-api'

const CACHE_KEY = 'downloads-big-files-v1'

function formatBytes(size?: number): string {
  if (typeof size !== 'number' || Number.isNaN(size)) return '—'
  if (size < 1024) return `${size} B`
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  let value = size
  let unit = 0
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024
    unit += 1
  }
  const rounded = value >= 100 ? Math.round(value) : Math.round(value * 10) / 10
  return `${rounded} ${units[unit]}`
}

async function moveToTrash(ctx: ExtensionContext, path: string): Promise<void> {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('Shell access is unavailable, so the file cannot be moved to Trash.')
  const escaped = path.replace(/\\/g, '\\\\').replace(/"/g, '\\"')
  const result = await shell.appleScript(`tell application "Finder" to delete POSIX file "${escaped}"`)
  if (result.exitCode !== 0) {
    const detail = (result.stderr || result.stdout || '').trim()
    throw new Error(detail ? `Could not move to Trash: ${detail}` : 'Could not move to Trash.')
  }
}

function deleteAction(ctx: ExtensionContext, file: { path: string; name: string; label: string }) {
  return ctx.actions.run(
    'Move to Trash',
    async (innerCtx) => {
      await moveToTrash(innerCtx, file.path)
      try {
        innerCtx.cache.invalidate(CACHE_KEY)
      } catch {
        // ignore cache errors, patch still removes the row
      }
      try {
        innerCtx.views.invalidate()
      } catch {
        // ignore, patch still removes the row
      }
      return { patch: { removeItemIds: [file.path] } }
    },
    {
      style: 'destructive',
      requiresConfirmation: true,
      confirmMessage: `Move "${file.name}" to Trash?\n${file.label}`,
      confirmLabel: 'Move to Trash',
      cancelLabel: 'Cancel',
      shortcut: 'CommandOrControl+Backspace',
    },
  )
}

async function loadBigFiles(ctx: ExtensionContext): Promise<ExtensionItem[]> {
  const filesApi = ctx.desktop.files
  if (!filesApi) throw new Error('File access is unavailable in Nevermind.')

  const found = await filesApi.find(['~/Downloads'], {
    sortBy: 'size',
    order: 'desc',
    limit: 100,
    scanLimit: 10000,
  })

  const sorted = [...found].sort((a, b) => (b.size ?? 0) - (a.size ?? 0))

  const canQuickLook = ctx.system.capabilities.has('quick-look')

  return sorted.map((file): ExtensionItem => {
    const sizeLabel = formatBytes(file.size)
    const display = file.displayPath ?? file.path
    const label = `${sizeLabel} • ${display}`
    return {
      id: file.path,
      title: file.name,
      subtitle: label,
      icon: 'file',
      keywords: [file.name, file.extension ?? ''],
      accessories: [
        { text: sizeLabel, tone: 'warning' },
      ],
      path: file.path,
      filePath: file.path,
      primaryAction: ctx.actions.openPath(file.path, 'Open File'),
      actions: [
        deleteAction(ctx, { path: file.path, name: file.name, label }),
        ctx.actions.revealPath(file.path, 'Reveal in Finder'),
        ...(canQuickLook ? [ctx.actions.quickLook(file.path, 'Quick Look')] : []),
        ctx.actions.copyText(file.path, 'Copy Path'),
      ],
    }
  })
}

export default {
  id: 'local.downloads-big-files',
  title: 'Downloads Big Files',
  subtitle: 'Recursive biggest files with delete',
  capabilities: ['desktop.files', 'system'],
  commands: [
    {
      id: 'list-big-files',
      title: 'List Big Files in Downloads',
      subtitle: 'Recursive, ordered by size',
      aliases: ['big files downloads', 'large downloads', 'downloads size', 'biggest downloads'],
      icon: 'hard-drive',
      run(ctx) {
        return ctx.ui.list({
          title: 'Big Files in Downloads',
          searchBarPlaceholder: 'Filter big files…',
          items: ctx.data.staleWhileRevalidate({
            cacheKey: CACHE_KEY,
            ttlMs: 60_000,
            staleTtlMs: 300_000,
            loader: () => loadBigFiles(ctx),
            retry: true,
          }),
          emptyView: {
            title: 'No files found',
            subtitle: 'Your Downloads folder is empty.',
          },
          actions: [
            {
              ...ctx.views.refresh(),
              title: 'Refresh',
            },
          ],
        })
      },
    },
  ],
} satisfies NevermindExtension
