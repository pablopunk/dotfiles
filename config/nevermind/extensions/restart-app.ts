import type { NevermindExtension, ExtensionContext, ExtensionItem } from './nevermind-extension-api'

type RunningApp = {
  name: string
  bundlePath: string
  pids: number[]
}

function parseRunningApps(output: string, installedMap?: Map<string, string>): RunningApp[] {
  const apps = new Map<string, RunningApp>()

  for (const line of output.split('\n')) {
    // Match any .app bundle located in /Applications, /System/Applications, or user Applications
    const match = line.match(
      /^\s*(\d+)\s+(\/(?:Applications|System\/Applications|Users\/[^/]+\/Applications)\/.*?\.app)(?:\/|$)/,
    )
    if (!match) continue

    const pid = Number(match[1])
    const bundlePath = match[2]

    // Nevermind cannot finish the action or refresh its UI after killing itself
    if (bundlePath.includes('Nevermind.app')) continue

    const baseName = bundlePath.split('/').pop()?.replace(/\.app$/, '') || bundlePath
    const name = installedMap?.get(bundlePath) || baseName

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

async function restartApplication(
  ctx: ExtensionContext,
  app: RunningApp,
  force = false,
): Promise<void> {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('Shell access is unavailable.')

  ctx.ui.indicator.show({
    title: `Restarting ${app.name}…`,
    status: 'loading',
  })

  if (force) {
    await shell
      .exec('/bin/kill', ['-KILL', ...app.pids.map(String)], { timeout: 3000 })
      .catch(() => null)
  } else {
    // Graceful SIGTERM first
    await shell
      .exec('/bin/kill', ['-TERM', ...app.pids.map(String)], { timeout: 3000 })
      .catch(() => null)

    // Wait up to 1.5s for processes to exit
    const start = Date.now()
    let stillAlive = [...app.pids]
    while (stillAlive.length > 0 && Date.now() - start < 1500) {
      const nextAlive: number[] = []
      for (const pid of stillAlive) {
        const check = await shell
          .exec('/bin/kill', ['-0', String(pid)], { timeout: 1000 })
          .catch(() => ({ exitCode: 1 }))
        if (check.exitCode === 0) {
          nextAlive.push(pid)
        }
      }
      stillAlive = nextAlive
      if (stillAlive.length > 0) {
        await new Promise((resolve) => setTimeout(resolve, 150))
      }
    }

    // If still running after timeout, force kill with SIGKILL
    if (stillAlive.length > 0) {
      await shell
        .exec('/bin/kill', ['-KILL', ...stillAlive.map(String)], { timeout: 3000 })
        .catch(() => null)
    }
  }

  // Short delay to ensure OS process cleanup before launching
  await new Promise((resolve) => setTimeout(resolve, 200))

  // Relaunch the app using open
  const openResult = await shell
    .exec('/usr/bin/open', [app.bundlePath], { timeout: 5000 })
    .catch(() => null)

  if (!openResult || openResult.exitCode !== 0) {
    if (ctx.desktop.apps?.launch) {
      ctx.desktop.apps.launch(app.bundlePath)
    } else {
      throw new Error(
        `Failed to relaunch ${app.name}: ${openResult?.stderr || 'unknown error'}`,
      )
    }
  }

  ctx.ui.indicator.show({
    title: `${app.name} restarted`,
    status: 'success',
    durationMs: 2000,
  })
}

async function loadItems(ctx: ExtensionContext): Promise<ExtensionItem[]> {
  const shell = ctx.desktop.shell
  const appsApi = ctx.desktop.apps
  if (!shell || !appsApi) {
    throw new Error('App and process access is unavailable.')
  }

  const result = await shell.exec('/bin/ps', ['-axo', 'pid=,comm='], {
    timeout: 5000,
    outputLimit: 1_000_000,
  })

  if (result.exitCode !== 0) {
    throw new Error(result.stderr.trim() || 'Could not list running applications.')
  }

  const installedMap = new Map<string, string>()
  try {
    const installed = appsApi.list() || []
    for (const app of installed) {
      if (app.path && app.name) {
        installedMap.set(app.path, app.name)
      }
    }
  } catch {
    // Ignore error mapping installed names
  }

  const runningApps = parseRunningApps(result.stdout, installedMap)

  return Promise.all(
    runningApps.map(async (app) => {
      const image = await appsApi.icon(app.bundlePath).catch(() => null)
      const pidLabel =
        app.pids.length === 1 ? `PID ${app.pids[0]}` : `${app.pids.length} processes`

      const restartAction = ctx.actions.run(
        `Restart ${app.name}`,
        async (actionCtx) => {
          await restartApplication(actionCtx, app, false)
          return actionCtx.navigation.pop()
        },
        {
          icon: 'rotate-cw',
          dismissAfterRun: 'auto',
        },
      )

      const forceRestartAction = ctx.actions.run(
        `Force Restart ${app.name}`,
        async (actionCtx) => {
          await restartApplication(actionCtx, app, true)
          return actionCtx.navigation.pop()
        },
        {
          icon: 'zap',
          style: 'destructive',
          dismissAfterRun: 'auto',
        },
      )

      const quitAction = ctx.actions.run(
        `Quit ${app.name}`,
        async (actionCtx) => {
          const actionShell = actionCtx.desktop.shell
          if (!actionShell) throw new Error('Shell access is unavailable.')
          await actionShell
            .exec('/bin/kill', ['-TERM', ...app.pids.map(String)], { timeout: 3000 })
            .catch(() => null)
          actionCtx.ui.indicator.show({
            title: `${app.name} quit`,
            status: 'success',
            durationMs: 1800,
          })
          return actionCtx.navigation.pop()
        },
        {
          icon: 'power-off',
          style: 'destructive',
          dismissAfterRun: 'auto',
        },
      )

      return {
        id: app.bundlePath,
        title: app.name,
        subtitle: app.bundlePath,
        image: image || undefined,
        icon: image ? undefined : 'app-window',
        accessories: [{ text: pidLabel, tone: 'muted' }],
        keywords: [app.name, 'restart', 'relaunch', 'reboot', app.bundlePath],
        primaryAction: restartAction,
        actions: [
          restartAction,
          forceRestartAction,
          quitAction,
          ctx.actions.revealPath(app.bundlePath, 'Reveal in Finder'),
          ctx.actions.copyText(app.bundlePath, 'Copy App Path'),
        ],
      }
    }),
  )
}

export default {
  id: 'restart-app',
  title: 'Restart App',
  subtitle: 'Restart a running application',
  capabilities: ['desktop.apps', 'desktop.files', 'system'],
  commands: [
    {
      id: 'restart-app',
      title: 'Restart App',
      subtitle: 'Choose a running application to restart',
      aliases: ['restart application', 'relaunch app', 'reboot app', 'reload app'],
      icon: 'rotate-cw',
      run(ctx) {
        return ctx.ui.list({
          title: 'Restart App',
          searchBarPlaceholder: 'Search running apps to restart…',
          items: ctx.data.loader(() => loadItems(ctx), { retry: true }),
          emptyView: {
            title: 'No Running Apps',
            subtitle: 'No running applications were found.',
          },
        })
      },
    },
  ],
} satisfies NevermindExtension
