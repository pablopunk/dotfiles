import type {
  ExtensionContext,
  ExtensionItem,
  ExtensionView,
  NevermindExtension,
} from './nevermind-extension-api'

const ID = 'pablo.organize-downloads'
const MOVE_PROGRESS_ID = `${ID}.move-progress`
const RESERVED = new Set(['categories', 'originals'])

type EntryKind = 'file' | 'dir' | 'link' | 'other'

type Entry = {
  kind: EntryKind
  name: string
  size: number
}

type PlanRow = Entry & { category: string }

type ScanResult = {
  rootPath: string
  entries: Entry[]
  categories: string[]
  hasOriginals: boolean
}

const CATEGORY_ICONS: Record<string, string> = {
  '3D Models': 'shapes',
  Archives: 'file-archive',
  'Credentials & Sensitive': 'key-round',
  Data: 'database',
  Documents: 'file-text',
  Installers: 'package-down',
  Media: 'image',
  Misc: 'box',
}

const KEYWORDS: Record<string, string[]> = {
  '3D Models': ['3d'],
  'Credentials & Sensitive': ['credential', 'sensitive', 'security'],
  Installers: ['install'],
}

const EXTENSION_GROUPS: Array<{ category: string; extensions: string[] }> = [
  { category: 'Installers', extensions: ['dmg', 'pkg', 'iso', 'exe', 'msi', 'app'] },
  { category: '3D Models', extensions: ['3mf', 'stl', 'obj', 'step', 'stp', 'scad'] },
  {
    category: 'Media',
    extensions: [
      'png', 'jpg', 'jpeg', 'gif', 'heic', 'webp', 'tiff', 'bmp', 'svg', 'avif',
      'mp4', 'mov', 'mkv', 'webm', 'avi', 'm4v',
      'mp3', 'wav', 'm4a', 'flac', 'aac', 'aiff', 'ogg',
    ],
  },
  {
    category: 'Documents',
    extensions: [
      'pdf', 'md', 'markdown', 'txt', 'rtf', 'doc', 'docx', 'xls', 'xlsx',
      'ppt', 'pptx', 'pages', 'numbers', 'keynote', 'epub',
    ],
  },
  {
    category: 'Data',
    extensions: [
      'csv', 'tsv', 'xml', 'har', 'sqlite', 'db', 'json', 'jsonl', 'parquet',
      'log', 'yaml', 'yml', 'plist', 'gz', 'tar', 'tgz', 'bz2', 'xz',
    ],
  },
  { category: 'Archives', extensions: ['zip', 'rar', '7z'] },
]

const SENSITIVE_PATTERN = /client_secret|credential|password|passwd|secret|\.p12$|\.pem$|\.key$/i

function requireShell(ctx: ExtensionContext) {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('Shell helpers are not available in this build.')
  return shell
}

function updateMoveProgress(
  ctx: ExtensionContext,
  input: {
    title: string
    subtitle: string
    status: 'loading' | 'success' | 'error'
    value?: number
    total?: number
    durationMs?: number
  },
) {
  try {
    ctx.ui.indicator.update({ id: MOVE_PROGRESS_ID, ...input })
  } catch (error) {
    ctx.logs.warn(`Downloads progress indicator update failed: ${String(error)}`)
  }
}

function normalize(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]/g, '')
}

function resolveCategory(desired: string, existing: string[]): string {
  const target = normalize(desired)
  const exact = existing.find((category) => normalize(category) === target)
  if (exact) return exact
  const keywords = KEYWORDS[desired] ?? []
  const related = existing.find((category) =>
    keywords.some((keyword) => normalize(category).includes(keyword)),
  )
  return related ?? desired
}

function classify(entry: Entry, categories: string[]): string {
  if (entry.kind !== 'file') return resolveCategory('Misc', categories)
  const lower = entry.name.toLowerCase()
  const extension = lower.includes('.') ? (lower.split('.').pop() ?? '') : ''
  if (SENSITIVE_PATTERN.test(lower)) return resolveCategory('Credentials & Sensitive', categories)
  for (const group of EXTENSION_GROUPS) {
    if (!group.extensions.includes(extension)) continue
    if (group.category === 'Archives' && /install|setup/.test(lower)) {
      return resolveCategory('Installers', categories)
    }
    return resolveCategory(group.category, categories)
  }
  return resolveCategory('Misc', categories)
}

function formatBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  let value = bytes
  let unit = 0
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024
    unit += 1
  }
  return `${value >= 10 || unit === 0 ? Math.round(value) : value.toFixed(1)} ${units[unit]}`
}

const SCAN_SCRIPT = `cd "$HOME/Downloads" || exit 1
pwd -P
echo '---ENTRIES---'
find . -mindepth 1 -maxdepth 1 -exec sh -c '
  for f; do
    if [ -L "$f" ]; then t=link
    elif [ -d "$f" ]; then t=dir
    elif [ -f "$f" ]; then t=file
    else t=other; fi
    s=$(stat -f%z "$f" 2>/dev/null || echo 0)
    printf "%s\\t%s\\t%s\\n" "$t" "\${f#./}" "$s"
  done' _ {} +
echo '---CATEGORIES---'
find categories -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's|^categories/||' | sort
echo '---ORIGINALS---'
if [ -d originals ]; then echo yes; else echo no; fi
`

async function scan(ctx: ExtensionContext): Promise<ScanResult> {
  const shell = requireShell(ctx)
  const result = await shell.script(SCAN_SCRIPT, { timeout: 15000 })
  if (result.exitCode !== 0) {
    throw new Error(
      `Could not read ~/Downloads${result.stderr.trim() ? `: ${result.stderr.trim()}` : '.'}`,
    )
  }
  const lines = result.stdout.split('\n')
  const rootPath = (lines[0] ?? '').trim()
  if (!rootPath) throw new Error('Could not resolve the Downloads folder path.')

  const entries: Entry[] = []
  const categories: string[] = []
  let hasOriginals = false
  let section: 'header' | 'entries' | 'categories' | 'originals' = 'header'
  for (const line of lines.slice(1)) {
    const trimmed = line.trim()
    if (trimmed === '---ENTRIES---') {
      section = 'entries'
      continue
    }
    if (trimmed === '---CATEGORIES---') {
      section = 'categories'
      continue
    }
    if (trimmed === '---ORIGINALS---') {
      section = 'originals'
      continue
    }
    if (!trimmed) continue
    if (section === 'entries') {
      const [kind, name, size] = line.split('\t')
      if (!name) continue
      entries.push({
        kind: (kind as EntryKind) ?? 'other',
        name,
        size: Number.parseInt(size ?? '0', 10) || 0,
      })
    } else if (section === 'categories') {
      categories.push(trimmed)
    } else if (section === 'originals') {
      hasOriginals = trimmed === 'yes'
    }
  }

  return {
    rootPath,
    categories,
    hasOriginals,
    entries: entries.filter(
      (entry) => !entry.name.startsWith('.') && !RESERVED.has(entry.name),
    ),
  }
}

function buildPlan(scanResult: ScanResult): PlanRow[] {
  return scanResult.entries
    .map((entry) => ({ ...entry, category: classify(entry, scanResult.categories) }))
    .sort((a, b) => a.category.localeCompare(b.category) || a.name.localeCompare(b.name))
}

function summarizePlan(rows: PlanRow[]): string {
  const counts = new Map<string, number>()
  for (const row of rows) counts.set(row.category, (counts.get(row.category) ?? 0) + 1)
  return [...counts.entries()]
    .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
    .map(([category, count]) => `${count} ${category}`)
    .join(' · ')
}

async function planView(ctx: ExtensionContext): Promise<ExtensionView> {
  const scanResult = await scan(ctx)
  const rows = buildPlan(scanResult)
  if (rows.length === 0) {
    return ctx.ui.preview({
      title: 'Downloads already organized',
      format: 'markdown',
      content: [
        'Nothing to move: there are no loose files or folders left in the `~/Downloads` root.',
        '',
        '- `categories/` holds the organized files',
        '- `originals/` is never modified once it exists',
      ].join('\n'),
    })
  }

  const confirm = ctx.ui.confirm({
    title: `Move ${rows.length} item${rows.length === 1 ? '' : 's'} into categories/?`,
    message: [
      `Plan: ${summarizePlan(rows)}.`,
      'Files are moved, never deleted. Existing category folders are reused, and originals/ is left untouched.',
    ].join('\n\n'),
    confirmLabel: 'Move files',
    onConfirm: ctx.actions.run('Moving files…', async (innerCtx) => performMoves(innerCtx)),
  })

  const destinationCount = new Set(rows.map((row) => row.category)).size

  const heading: ExtensionItem = {
    id: 'plan:move',
    title: `Move ${rows.length} item${rows.length === 1 ? '' : 's'} into categories`,
    subtitle: summarizePlan(rows),
    icon: 'folder-tree',
    appearance: { prominence: 'primary' },
    primaryAction: confirm,
    actions: [
      ctx.actions.run('Rescan Downloads', async (innerCtx) => planView(innerCtx)),
      ctx.actions.revealPath(scanResult.rootPath, 'Reveal ~/Downloads'),
      ctx.actions.openPath(`${scanResult.rootPath}/categories`, 'Open categories/'),
    ],
  }

  const fileItems: ExtensionItem[] = rows.map((row) => {
    const path = `${scanResult.rootPath}/${row.name}`
    return {
      id: `entry:${row.name}`,
      title: row.name,
      subtitle: `→ categories/${row.category}`,
      icon: row.kind === 'dir' || row.kind === 'link'
        ? 'folder'
        : (CATEGORY_ICONS[row.category] ?? 'file'),
      accessories: [
        { text: row.kind === 'dir' ? 'folder' : formatBytes(row.size), tone: 'muted' },
      ],
      detail: {
        text: row.name,
        metadata: [
          { label: 'Destination', value: `categories/${row.category}`, copyable: true },
          { label: 'Source', value: path, copyable: true },
          { label: 'Type', value: row.kind === 'dir' ? 'folder' : row.kind },
          { label: 'Size', value: formatBytes(row.size) },
        ],
      },
      primaryAction: ctx.actions.revealPath(path),
      actions: [
        ctx.actions.openPath(path),
        ctx.actions.copyText(path, 'Copy Path'),
      ],
    }
  })

  return ctx.ui.list({
    title: 'Organize Downloads',
    subtitle: `${rows.length} item${rows.length === 1 ? '' : 's'} in root · ${destinationCount} target categor${destinationCount === 1 ? 'y' : 'ies'}`,
    presentation: 'side-preview',
    detail: { visible: true },
    sections: [
      { title: 'Plan', items: [heading] },
      { title: 'Files to move', items: fileItems },
    ],
    emptyView: { title: 'Nothing to organize' },
  })
}

async function ensureOriginals(
  ctx: ExtensionContext,
  scanResult: ScanResult,
): Promise<{ status: string; detail: string }> {
  if (scanResult.hasOriginals) {
    return {
      status: 'originals/ left untouched',
      detail: 'The flat symlink folder already exists, so this run did not modify it.',
    }
  }
  const shell = requireShell(ctx)
  const script = `cd "$HOME/Downloads" || exit 1
mkdir -p originals
created=0
while IFS= read -r -d '' f; do
  name=$(basename "$f")
  if [ -e "originals/$name" ] || [ -L "originals/$name" ]; then continue; fi
  ln -s "$HOME/Downloads/$f" "originals/$name" && created=$((created + 1))
done < <(find categories -type f -print0 2>/dev/null)
total=$(find originals -mindepth 1 -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
echo "CREATED=$created"
echo "TOTAL=$total"
`
  const result = await shell.script(script, { timeout: 20000 })
  const created = /CREATED=(\d+)/.exec(result.stdout)?.[1] ?? '0'
  const total = /TOTAL=(\d+)/.exec(result.stdout)?.[1] ?? '0'
  if (result.exitCode !== 0) {
    return {
      status: 'originals/ was not created',
      detail: result.stderr.trim() || 'The symlink step failed.',
    }
  }
  return {
    status: `originals/ created with ${created} new symlink${created === '1' ? '' : 's'}`,
    detail: `${total} symlink${total === '1' ? '' : 's'} now point into categories/ using absolute paths.`,
  }
}

async function performMoves(ctx: ExtensionContext): Promise<ExtensionView> {
  const shell = requireShell(ctx)
  const scanResult = await scan(ctx)
  const rows = buildPlan(scanResult)
  if (rows.length === 0) {
    return ctx.ui.list({
      title: 'Nothing to organize',
      subtitle: 'The Downloads root is already clear.',
      items: [],
      emptyView: { title: 'Nothing to move' },
      contentSizing: 'fit',
    })
  }

  try {
    ctx.ui.indicator.show({
      id: MOVE_PROGRESS_ID,
      title: 'Organizing Downloads',
      subtitle: `Preparing to move ${rows.length} items…`,
      status: 'loading',
      value: 0,
      total: rows.length,
    })
  } catch (error) {
    ctx.logs.warn(`Downloads progress indicator could not be shown: ${String(error)}`)
  }

  try {
    const movedByCategory = new Map<string, PlanRow[]>()
    const failures: Array<{ row: PlanRow; reason: string }> = []
    const targets = [...new Set(rows.map((row) => row.category))]
    const ready = new Set<string>()

    updateMoveProgress(ctx, {
      title: 'Organizing Downloads',
      subtitle: 'Preparing category folders…',
      status: 'loading',
      value: 0,
      total: rows.length,
    })

    for (const category of targets) {
      const directory = `${scanResult.rootPath}/categories/${category}`
      const created = await shell.exec('mkdir', ['-p', directory])
      if (created.exitCode === 0) ready.add(category)
      else {
        for (const row of rows.filter((entry) => entry.category === category)) {
          failures.push({ row, reason: `could not create categories/${category}` })
        }
      }
    }

    let processed = 0
    for (const row of rows) {
      updateMoveProgress(ctx, {
        title: 'Organizing Downloads',
        subtitle: `Processing ${processed + 1} of ${rows.length}: ${row.name}`,
        status: 'loading',
        value: processed,
        total: rows.length,
      })

      if (!ready.has(row.category)) {
        processed += 1
        updateMoveProgress(ctx, {
          title: 'Organizing Downloads',
          subtitle: `Processed ${processed} of ${rows.length} · ${row.name} skipped`,
          status: 'loading',
          value: processed,
          total: rows.length,
        })
        continue
      }

      const source = `${scanResult.rootPath}/${row.name}`
      const destination = `${scanResult.rootPath}/categories/${row.category}/${row.name}`
      const result = await shell.exec('mv', ['-n', source, destination])
      if (result.exitCode !== 0) {
        failures.push({ row, reason: result.stderr.trim() || 'mv failed' })
      } else {
        const stillAtSource = await shell.exec('test', ['-e', source])
        if (stillAtSource.exitCode === 0) {
          failures.push({
            row,
            reason: `categories/${row.category} already has a “${row.name}”`,
          })
        } else {
          const bucket = movedByCategory.get(row.category) ?? []
          bucket.push(row)
          movedByCategory.set(row.category, bucket)
        }
      }

      processed += 1
      const failure = failures.find((item) => item.row.name === row.name)
      const movedSoFar = [...movedByCategory.values()].reduce(
        (count, entries) => count + entries.length,
        0,
      )
      updateMoveProgress(ctx, {
        title: 'Organizing Downloads',
        subtitle: failure
          ? `Processed ${processed} of ${rows.length} · ${row.name} skipped`
          : `Processed ${processed} of ${rows.length} · ${movedSoFar} moved`,
        status: 'loading',
        value: processed,
        total: rows.length,
      })
    }

    updateMoveProgress(ctx, {
      title: 'Organizing Downloads',
      subtitle: scanResult.hasOriginals ? 'Finishing up…' : 'Creating originals/ symlinks…',
      status: 'loading',
      value: rows.length,
      total: rows.length,
    })
    const originals = await ensureOriginals(ctx, scanResult)
    const movedCount = [...movedByCategory.values()].reduce(
      (total, rowsInCategory) => total + rowsInCategory.length,
      0,
    )

    ctx.logs.info(
      `${ID} moved ${movedCount}/${rows.length} · ${[...movedByCategory.entries()]
        .map(([category, rowsInCategory]) => `${category}:${rowsInCategory.length}`)
        .join(',')} · failures ${failures.length} · ${originals.status}`,
    )

    updateMoveProgress(ctx, {
      title: failures.length > 0 ? 'Downloads organized with skips' : 'Downloads organized',
      subtitle: `${movedCount} of ${rows.length} moved · ${originals.status}`,
      status: failures.length > 0 || originals.status.includes('not created') ? 'error' : 'success',
      value: processed,
      total: rows.length,
      durationMs: 5000,
    })

    const categoryItems: ExtensionItem[] = [...movedByCategory.entries()]
      .sort((a, b) => b[1].length - a[1].length || a[0].localeCompare(b[0]))
      .map(([category, rowsInCategory]) => ({
        id: `done:${category}`,
        title: category,
        subtitle: `${rowsInCategory.length} item${rowsInCategory.length === 1 ? '' : 's'} moved · categories/${category}`,
        icon: CATEGORY_ICONS[category] ?? 'folder',
        accessories: [{ text: `${rowsInCategory.length}`, tone: 'success' }],
        primaryAction: ctx.actions.openPath(
          `${scanResult.rootPath}/categories/${category}`,
          `Open ${category}`,
        ),
        detail: {
          text: rowsInCategory.map((row) => row.name).join('\n'),
          metadata: [{ label: 'Folder', value: `categories/${category}`, copyable: true }],
        },
      }))

    const failureItems: ExtensionItem[] = failures.map(({ row, reason }) => ({
      id: `failed:${row.name}`,
      title: row.name,
      subtitle: reason,
      icon: 'circle-alert',
      appearance: { foreground: 'red' },
      primaryAction: ctx.actions.revealPath(`${scanResult.rootPath}/${row.name}`),
    }))

    const total = movedCount + failures.length
    return ctx.ui.list({
      title: failures.length > 0 ? 'Downloads organized with skips' : 'Downloads organized',
      subtitle: `${movedCount} of ${total} moved · ${originals.status}`,
      contentSizing: 'fit',
      items: [
        ...categoryItems,
        {
          id: 'done:originals',
          title: 'originals/',
          subtitle: originals.detail,
          icon: 'link',
          primaryAction: ctx.actions.revealPath(
            `${scanResult.rootPath}/originals`,
            'Reveal originals/',
          ),
          actions: [ctx.actions.revealPath(scanResult.rootPath, 'Reveal ~/Downloads')],
        },
        ...failureItems,
      ],
      emptyView: {
        title: 'Nothing moved',
        subtitle: failures.length > 0 ? 'Every item was skipped.' : undefined,
      },
      actions: [
        ctx.actions.run('Organize Again', async (innerCtx) => planView(innerCtx)),
        ctx.actions.revealPath(scanResult.rootPath, 'Reveal ~/Downloads'),
        ctx.actions.openPath(`${scanResult.rootPath}/categories`, 'Open categories/'),
      ],
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    updateMoveProgress(ctx, {
      title: 'Downloads organization failed',
      subtitle: message,
      status: 'error',
      durationMs: 7000,
    })
    if (error instanceof Error) throw error
    throw new Error(`Downloads organization failed: ${message}`)
  }
}

export default {
  id: 'pablo.organize-downloads',
  title: 'Organize Downloads',
  subtitle: 'Sorts loose files in ~/Downloads into categories/ while keeping originals/ intact',
  capabilities: ['desktop.files', 'system'],
  commands: [
    {
      id: 'organize-downloads',
      title: 'Organize Downloads',
      subtitle: 'Review a category plan for ~/Downloads, then move the files',
      aliases: ['sort downloads', 'tidy downloads', 'clean up downloads'],
      icon: 'folder-tree',
      async run(ctx) {
        return planView(ctx)
      },
    },
  ],
} satisfies NevermindExtension
