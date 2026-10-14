import type { NevermindExtension, ExtensionContext, ExtensionItem } from './nevermind-extension-api'

interface Device {
  ID?: string
  PublicKey?: string
  HostName?: string
  DNSName?: string
  OS?: string
  TailscaleIPs?: string[]
  Online?: boolean
}
interface Status {
  BackendState?: string
  Self?: Device
  Peer?: Record<string, Device>
}

async function loadDevices(ctx: ExtensionContext): Promise<ExtensionItem[]> {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('System command access is unavailable in Nevermind.')
  let binary = ctx.cache.get<string>('tailscale-binary')
  if (!binary) {
    for (const candidate of [
      'tailscale',
      '/opt/homebrew/bin/tailscale',
      '/usr/local/bin/tailscale',
      '/Applications/Tailscale.app/Contents/MacOS/Tailscale',
      '/usr/bin/tailscale',
    ]) {
      const found = await shell.which(candidate)
      if (found.exitCode === 0 && found.stdout.trim()) {
        binary = found.stdout.trim().split('\n')[0]
        break
      }
    }
    if (!binary) throw new Error('Tailscale was not found. Install the Tailscale app or CLI, sign in, and try again.')
    ctx.cache.set('tailscale-binary', binary)
  }
  const result = await shell.exec(binary, ['status', '--json'], { timeout: 12000, outputLimit: 4000000 })
  if (result.exitCode !== 0) throw new Error(`Could not read Tailscale devices: ${(result.stderr || result.stdout).trim() || 'Tailscale is not running.'}`)
  let status: Status
  try { status = JSON.parse(result.stdout) } catch { throw new Error('Tailscale returned invalid status data.') }
  if (!status || typeof status !== 'object') throw new Error('Tailscale returned invalid status data.')
  if (status.BackendState === 'NeedsLogin' || status.BackendState === 'NeedsMachineAuth') {
    throw new Error('Sign in to Tailscale and authorize this machine, then try again.')
  }
  const devices: Array<{ device: Device; self: boolean; key: string }> = []
  if (status.Self) devices.push({ device: status.Self, self: true, key: 'self' })
  for (const [key, device] of Object.entries(status.Peer || {})) {
    if (device) devices.push({ device, self: false, key })
  }
  const seen = new Set<string>()
  return devices.map(({ device, self, key }): ExtensionItem | null => {
    const dns = (device.DNSName || '').replace(/\.+$/, '')
    const ips = (device.TailscaleIPs || []).filter(ip => typeof ip === 'string')
    const ip = ips.find(ip => !ip.includes(':')) || ips[0]
    const id = device.ID || device.PublicKey || dns || key
    if (seen.has(id)) return null
    seen.add(id)
    const online = device.Online === true
    const title = dns.split('.')[0] || device.HostName || ip || 'Unnamed device'
    return {
      id,
      title,
      online,
      subtitle: [dns || 'No MagicDNS hostname', ip].filter(Boolean).join(' · '),
      icon: self ? 'laptop' : 'monitor',
      appearance: online ? { foreground: 'green' } : undefined,
      keywords: [device.HostName || '', dns, device.OS || '', ...ips],
      accessories: [
        ...(self ? [{ text: 'This device', tone: 'muted' as const }] : []),
        { text: online ? 'Online' : 'Offline', tone: online ? 'success' : 'muted' },
      ],
      primaryAction: dns
        ? ctx.actions.copyText(dns, 'Copy .ts.net Hostname')
        : ctx.actions.run('Hostname Unavailable', () => { throw new Error('This device has no MagicDNS hostname reported by Tailscale.') }),
      actions: ip ? [
        ctx.actions.copyText(ip, 'Copy IP'),
        ...ips.filter(address => address !== ip).map(address => ctx.actions.copyText(address, 'Copy IPv6')),
      ] : [],
    }
  }).filter((item): item is ExtensionItem => item !== null)
    .sort((a, b) => Number(b.online === true) - Number(a.online === true) || a.title.localeCompare(b.title))
}

export default {
  id: 'local.tailscale-machines',
  title: 'Tailscale Machines',
  subtitle: 'Copy device hostnames and IPs, with live online status',
  capabilities: ['system'],
  commands: [{
    id: 'tailscale-machines',
    title: 'Tailscale Machines',
    aliases: ['Tailscale Devices'],
    subtitle: 'Browse devices and copy their MagicDNS hostnames',
    icon: 'network',
    run(ctx) {
      return ctx.ui.list({
        title: 'Tailscale Machines',
        searchBarPlaceholder: 'Search devices, hostnames, or IPs…',
        items: ctx.data.loader(() => loadDevices(ctx), { retry: true }),
        emptyView: { title: 'No Tailscale devices', subtitle: 'Connect Tailscale and sign in to your tailnet.' },
        refresh: { intervalMs: 15000, mode: 'replace' },
      })
    },
  }],
} satisfies NevermindExtension
