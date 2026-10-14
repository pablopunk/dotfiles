import type { NevermindExtension, ExtensionContext, ExtensionItem } from './nevermind-extension-api'

// Compile a small CoreAudio helper once, then reuse it for listing and switching.
const SOURCE = `
import Foundation
import CoreAudio
let system = AudioObjectID(kAudioObjectSystemObject)
func devices(_ scope: AudioObjectPropertyScope) -> [[String: Any]] {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(system, &addr, 0, nil, &size) == noErr else { return [] }
    var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    guard AudioObjectGetPropertyData(system, &addr, 0, nil, &size, &ids) == noErr else { return [] }
    var defaultAddr = AudioObjectPropertyAddress(mSelector: scope == kAudioDevicePropertyScopeInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var defaultID: AudioObjectID = 0
    var defaultSize = UInt32(MemoryLayout<AudioObjectID>.size)
    AudioObjectGetPropertyData(system, &defaultAddr, 0, nil, &defaultSize, &defaultID)
    return ids.compactMap { id in
        var streamAddr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration, mScope: scope, mElement: kAudioObjectPropertyElementMain)
        var streamSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &streamAddr, 0, nil, &streamSize) == noErr, streamSize > 0 else { return nil }
        let pointer = UnsafeMutableRawPointer.allocate(byteCount: Int(streamSize), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { pointer.deallocate() }
        var actualSize = streamSize
        guard AudioObjectGetPropertyData(id, &streamAddr, 0, nil, &actualSize, pointer) == noErr else { return nil }
        let buffers = UnsafeMutableAudioBufferListPointer(pointer.assumingMemoryBound(to: AudioBufferList.self))
        let channels = buffers.reduce(UInt32(0)) { $0 + $1.mNumberChannels }
        guard channels > 0 else { return nil }
        var nameAddr = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var name: CFString = "" as CFString
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        AudioObjectGetPropertyData(id, &nameAddr, 0, nil, &nameSize, &name)
        var uidAddr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceUID, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var uid: CFString = "" as CFString
        var uidSize = UInt32(MemoryLayout<CFString>.size)
        AudioObjectGetPropertyData(id, &uidAddr, 0, nil, &uidSize, &uid)
        return ["id": id, "name": name as String, "uid": uid as String, "isDefault": id == defaultID, "channels": channels] as [String: Any]
    }
}
let args = CommandLine.arguments
let scope: AudioObjectPropertyScope = args.contains("input") ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
if args.count >= 4 && args[1] == "set" {
    guard let device = devices(scope).first(where: { ($0["uid"] as? String) == args[3] }), let id = device["id"] as? AudioObjectID else {
        fputs("Audio device not found or unavailable for this direction\\n", stderr)
        exit(1)
    }
    var defaultAddr = AudioObjectPropertyAddress(mSelector: scope == kAudioDevicePropertyScopeInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var selected = id
    let status = AudioObjectSetPropertyData(system, &defaultAddr, 0, nil, UInt32(MemoryLayout<AudioObjectID>.size), &selected)
    guard status == noErr else {
        fputs("Could not change default audio device (CoreAudio status \\(status))\\n", stderr)
        exit(1)
    }
} else {
    do {
        let data = try JSONSerialization.data(withJSONObject: devices(scope))
        print(String(decoding: data, as: UTF8.self))
    } catch {
        fputs("Could not encode audio devices: \\(error)\\n", stderr)
        exit(1)
    }
}
`

const tool = '$HOME/Library/Caches/nevermind-audio-devices/audio-devices-v2'
let compiling: Promise<void> | undefined

async function ensureTool(ctx: ExtensionContext): Promise<void> {
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('Shell access is unavailable for Audio Devices.')
  const check = await shell.script(`test -x "${tool}"`)
  if (check.exitCode === 0) return
  if (!compiling) {
    compiling = (async () => {
      const script = `set -eu
DIR="$HOME/Library/Caches/nevermind-audio-devices"
mkdir -p "$DIR"
if test -x "$DIR/audio-devices-v2"; then exit 0; fi
SOURCE_FILE="$(mktemp "$DIR/source.XXXXXXXX.swift")"
BINARY_FILE="$(mktemp "$DIR/binary.XXXXXXXX")"
trap 'rm -f "$SOURCE_FILE" "$BINARY_FILE"' EXIT
cat > "$SOURCE_FILE" <<'NEVERMIND_AUDIO_SWIFT_SOURCE'
${SOURCE}
NEVERMIND_AUDIO_SWIFT_SOURCE
swiftc "$SOURCE_FILE" -o "$BINARY_FILE"
chmod 700 "$BINARY_FILE"
mv "$BINARY_FILE" "$DIR/audio-devices-v2"`
      const result = await shell.script(script, { timeout: 120000 })
      if (result.exitCode !== 0) throw new Error(`CoreAudio helper compilation failed: ${result.stderr || result.stdout}`)
    })().finally(() => { compiling = undefined })
  }
  await compiling
}

type Device = { uid: string; name: string; isDefault: boolean; channels: number }
async function runTool(ctx: ExtensionContext, args: string[]): Promise<string> {
  await ensureTool(ctx)
  const shell = ctx.desktop.shell
  if (!shell) throw new Error('Shell access is unavailable for Audio Devices.')
  const command = `"${tool}" ${args.map(arg => `'${arg.replaceAll("'", "'\\''")}'`).join(' ')}`
  const result = await shell.script(command, { timeout: 15000 })
  if (result.exitCode !== 0) throw new Error(result.stderr.trim() || result.stdout.trim() || `Audio helper exited with code ${result.exitCode}`)
  return result.stdout
}

async function listDevices(ctx: ExtensionContext, direction: 'input' | 'output'): Promise<Device[]> {
  const output = await runTool(ctx, ['list', direction])
  let devices: Device[]
  try { devices = JSON.parse(output) as Device[] }
  catch { throw new Error('Could not read the audio device list returned by CoreAudio.') }
  if (!Array.isArray(devices)) throw new Error('CoreAudio returned an invalid audio device list.')
  return devices
}

function deviceItems(ctx: ExtensionContext, direction: 'input' | 'output', devices: Device[]): ExtensionItem[] {
  return devices.map(device => ({
    id: device.uid,
    title: device.name || 'Unknown Device',
    subtitle: device.isDefault ? 'Current Default' : `${device.channels || 0} channels`,
    icon: direction === 'input' ? 'mic' : 'volume-2',
    accessories: device.isDefault ? [{ text: '✓' }] : [],
    // Capture the UID and direction in a freshly registered row action. ref() does not
    // forward arbitrary options as fields to a durable action's run handler.
    primaryAction: ctx.actions.run('Set as Default', async innerCtx => {
      await runTool(innerCtx, ['set', direction, device.uid])
      const updated = await listDevices(innerCtx, direction)
      return innerCtx.navigation.replace(renderDeviceList(innerCtx, direction, updated))
    }),
  }))
}

function renderDeviceList(ctx: ExtensionContext, direction: 'input' | 'output', devices?: Device[]) {
  return ctx.ui.list({
    title: direction === 'input' ? 'Audio Inputs' : 'Audio Outputs',
    searchBarPlaceholder: direction === 'input' ? 'Search microphones...' : 'Search speakers, headphones...',
    // Never persist view-local handlers in a cached item list. Recreate them on each open.
    items: devices ? deviceItems(ctx, direction, devices) : ctx.data.loader(async () => deviceItems(ctx, direction, await listDevices(ctx, direction))),
    emptyView: { title: 'No audio devices found', subtitle: 'No connected audio devices for this direction.' },
  })
}

export default {
  id: 'audio-devices',
  title: 'Audio Devices',
  capabilities: ['system'],
  commands: [
    { id: 'audio-outputs', title: 'Audio Outputs', subtitle: 'Change system audio output device', icon: 'volume-2', run(ctx) { return renderDeviceList(ctx, 'output') } },
    { id: 'audio-inputs', title: 'Audio Inputs', subtitle: 'Change system audio input device', icon: 'mic', run(ctx) { return renderDeviceList(ctx, 'input') } },
  ],
} satisfies NevermindExtension