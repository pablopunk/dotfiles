import type { NevermindExtension, ExtensionContext, ExtensionItem } from './nevermind-extension-api'

type AppStatus = { path: string; status: 'quarantined' | 'clear' | 'unknown' }

async function appPaths(ctx: ExtensionContext): Promise<string[]> {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('Shell access is unavailable; cannot list applications.')
  const result = await shell.script('for dir in /Applications "$HOME/Applications"; do if [ -d "$dir" ]; then /usr/bin/find "$dir" -maxdepth 2 -name "*.app" -prune -print; fi; done', { timeout: 30000 })
  if (result.exitCode !== 0) throw new Error(`Could not list apps: ${result.stderr.trim() || `find exited ${result.exitCode}`}`)
  return [...new Set(result.stdout.split('\n').filter(Boolean))]
}

async function quarantineStatus(ctx: ExtensionContext, path: string): Promise<AppStatus['status']> {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('Shell access is unavailable; cannot check quarantine attributes.')
  const result = await shell.exec('/usr/bin/xattr', ['-p', 'com.apple.quarantine', path], { timeout: 10000 })
  if (result.exitCode === 0) return 'quarantined'
  if (/no such xattr|attribute not found/i.test(result.stderr)) return 'clear'
  return 'unknown'
}

async function scan(ctx: ExtensionContext): Promise<string[]> {
  const paths = await appPaths(ctx)
  const result: AppStatus[] = []
  let next = 0
  await Promise.all(Array.from({ length: Math.min(8, paths.length) }, async () => {
    while (next < paths.length) {
      const path = paths[next++]
      result.push({ path, status: await quarantineStatus(ctx, path) })
    }
  }))
  const unknown = result.filter(app => app.status === 'unknown')
  if (unknown.length) throw new Error(`Could not check quarantine on ${unknown.length} app(s), including ${unknown[0].path}. Check permissions and try again.`)
  return result.filter(app => app.status === 'quarantined').map(app => app.path).sort((a, b) => a.localeCompare(b))
}

function appItems(ctx: ExtensionContext, paths: string[]): ExtensionItem[] {
  return paths.map(path => {
    const name = path.split('/').pop() || path
    const remove = ctx.actions.run('Remove Quarantine', async (current) => {
      const shell = current.desktop.shell
      if (!shell) throw new Error('Shell access is unavailable; quarantine was not changed.')
      const before = await quarantineStatus(current, path)
      if (before !== 'quarantined') throw new Error(before === 'clear' ? `${name} is no longer marked as quarantined. Reopen the command to refresh the list.` : `Could not verify quarantine on ${name}; nothing was changed.`)
      const result = await shell.exec('/usr/bin/xattr', ['-d', '-r', 'com.apple.quarantine', path], { timeout: 120000 })
      if (result.exitCode !== 0) throw new Error(`Could not remove quarantine from ${name}: ${result.stderr.trim() || result.stdout.trim() || `xattr exited ${result.exitCode}`}. You may need write permission for this app.`)
      const after = await quarantineStatus(current, path)
      if (after !== 'clear') throw new Error(`Could not verify that quarantine was removed from ${name}.`)
      return current.navigation.replace(makeView(current, await scan(current)))
    })
    return {
      id: path,
      title: name,
      subtitle: path,
      icon: 'app-window',
      accessories: [{ text: 'Quarantined', tone: 'warning' }],
      primaryAction: ctx.ui.confirm({
        title: `Remove quarantine from ${name}?`,
        message: `Recursively remove the com.apple.quarantine attribute from ${path}. Only do this if you trust the app. This does not bypass other macOS security checks.`,
        confirmLabel: 'Remove Quarantine',
        destructive: true,
        onConfirm: remove,
      }),
      actions: [ctx.actions.revealPath(path), ctx.actions.copyText(path, 'Copy App Path')],
    }
  })
}

function makeView(ctx: ExtensionContext, paths: string[]) {
  return ctx.ui.list({
    title: 'Remove App Quarantine',
    subtitle: `${paths.length} quarantined app(s) in /Applications and ~/Applications`,
    searchBarPlaceholder: 'Find a quarantined app…',
    items: appItems(ctx, paths),
    emptyView: { title: 'No quarantined apps found', subtitle: 'No .app bundles with com.apple.quarantine found in /Applications or ~/Applications.' },
  })
}

export default {
  id: 'local.remove-app-quarantine',
  title: 'Remove App Quarantine',
  capabilities: ['desktop.files', 'system'],
  commands: [{
    id: 'remove-app-quarantine',
    title: 'Remove App Quarantine',
    subtitle: 'Find quarantined apps and remove the quarantine attribute',
    icon: 'shield-off',
    async run(ctx) {
      return makeView(ctx, await scan(ctx))
    },
  }],
} satisfies NevermindExtension