import type { NevermindExtension, ExtensionContext, ExtensionItem } from './nevermind-extension-api'

type RunningApp = {
  name: string
  bundlePath: string
  pids: number[]
}

function parseRunningApps(output: string): RunningApp[] {
  const apps = new Map<string, RunningApp>()

  for (const line of output.split('\n')) {
    const match = line.match(/^\s*(\d+)\s+(\/Applications\/.*?\.app)(?:\/|$)/)
    if (!match) continue

    const pid = Number(match[1])
    const bundlePath = match[2]
    const name = bundlePath.split('/').pop()?.replace(/\.app$/, '') || bundlePath

    // Nevermind cannot finish the action or refresh its UI after killing itself.
    if (name === 'Nevermind') continue

    const existing = apps.get(bundlePath)
    if (existing) {
      if (!existing.pids.includes(pid)) existing.pids.push(pid)
    } else {
      apps.set(bundlePath, { name, bundlePath, pids: [pid] })
    }
  }

  return [...apps.values()].sort((a, b) =>
    a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }),
  )
}

async function loadItems(ctx: ExtensionContext): Promise<ExtensionItem[]> {
  const shell = ctx.desktop.shell
  const appsApi = ctx.desktop.apps
  if (!shell || !appsApi) throw new Error('App and process access is unavailable.')

  const result = await shell.exec('/bin/ps', ['-axo', 'pid=,comm='], {
    timeout: 5000,
    outputLimit: 1_000_000,
  })

  if (result.exitCode !== 0) {
    throw new Error(result.stderr.trim() || 'Could not list running applications.')
  }

  const runningApps = parseRunningApps(result.stdout)

  return Promise.all(
    runningApps.map(async (app) => {
      const image = await appsApi.icon(app.bundlePath).catch(() => null)
      const pidLabel = app.pids.length === 1 ? `PID ${app.pids[0]}` : `${app.pids.length} processes`

      return {
        id: app.bundlePath,
        title: app.name,
        subtitle: app.bundlePath,
        image: image || undefined,
        accessories: [{ text: pidLabel, tone: 'muted' }],
        keywords: ['quit', 'kill', 'force quit', app.bundlePath],
        primaryAction: ctx.actions.run(`Kill ${app.name}`, async (actionCtx) => {
          const killResult = await actionCtx.desktop.shell?.exec(
            '/bin/kill',
            ['-KILL', ...app.pids.map(String)],
            { timeout: 5000 },
          )

          if (!killResult) throw new Error('Process control is unavailable.')
          if (killResult.exitCode !== 0) {
            throw new Error(killResult.stderr.trim() || `Could not kill ${app.name}.`)
          }

          actionCtx.ui.indicator.show({
            title: `${app.name} killed`,
            status: 'success',
            durationMs: 1800,
          })
          return actionCtx.navigation.pop()
        }, {
          icon: 'skull',
          style: 'destructive',
        }),
      }
    }),
  )
}

export default {
  id: 'quit-running-app',
  title: 'Quit App',
  subtitle: 'Force-kill a running app from /Applications',
  capabilities: ['desktop.apps', 'system'],
  commands: [
    {
      id: 'quit-app',
      title: 'Quit App',
      subtitle: 'List and force-kill running apps from /Applications',
      aliases: ['kill app', 'force quit app'],
      icon: 'power-off',
      run(ctx) {
        return ctx.ui.list({
          title: 'Quit App',
          searchBarPlaceholder: 'Search running apps…',
          items: ctx.data.loader(() => loadItems(ctx), { retry: true }),
          emptyView: {
            title: 'No Running Apps',
            subtitle: 'No apps running from /Applications were found.',
          },
        })
      },
    },
  ],
} satisfies NevermindExtension
