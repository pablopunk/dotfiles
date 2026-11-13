package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

// swiftSource is the CoreAudio helper. It is compiled once into the cache folder and then reused for listing and switching.
const swiftSource = `
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
        fputs("Audio device not found or unavailable for this direction\n", stderr)
        exit(1)
    }
    var defaultAddr = AudioObjectPropertyAddress(mSelector: scope == kAudioDevicePropertyScopeInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var selected = id
    let status = AudioObjectSetPropertyData(system, &defaultAddr, 0, nil, UInt32(MemoryLayout<AudioObjectID>.size), &selected)
    guard status == noErr else {
        fputs("Could not change default audio device (CoreAudio status \(status))\n", stderr)
        exit(1)
    }
} else {
    do {
        let data = try JSONSerialization.data(withJSONObject: devices(scope))
        print(String(decoding: data, as: UTF8.self))
    } catch {
        fputs("Could not encode audio devices: \(error)\n", stderr)
        exit(1)
    }
}
`

const (
	toolPath          = "$HOME/Library/Caches/nevermind-audio-devices/audio-devices-v2"
	devicesLoaderBase = "devices:"
	setDefaultID      = "set-default"
)

var compileScript = `set -eu
DIR="$HOME/Library/Caches/nevermind-audio-devices"
mkdir -p "$DIR"
if test -x "$DIR/audio-devices-v2"; then exit 0; fi
SOURCE_FILE="$(mktemp "$DIR/source.XXXXXXXX.swift")"
BINARY_FILE="$(mktemp "$DIR/binary.XXXXXXXX")"
trap 'rm -f "$SOURCE_FILE" "$BINARY_FILE"' EXIT
cat > "$SOURCE_FILE" <<'NEVERMIND_AUDIO_SWIFT_SOURCE'
` + swiftSource + `
NEVERMIND_AUDIO_SWIFT_SOURCE
swiftc "$SOURCE_FILE" -o "$BINARY_FILE"
chmod 700 "$BINARY_FILE"
mv "$BINARY_FILE" "$DIR/audio-devices-v2"`

type audioDevice struct {
	UID       string `json:"uid"`
	Name      string `json:"name"`
	IsDefault bool   `json:"isDefault"`
	Channels  int    `json:"channels"`
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{
		{ID: "audio-outputs", Title: "Audio Outputs", Subtitle: "Change system audio output device", Icon: "volume-2"},
		{ID: "audio-inputs", Title: "Audio Inputs", Subtitle: "Change system audio input device", Icon: "mic"},
	}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case "audio-outputs":
		return deviceListResult(ctx, "output")
	case "audio-inputs":
		return deviceListResult(ctx, "input")
	case setDefaultID:
		return setDefault(ctx, in.Ref.Args["direction"], in.Ref.Args["uid"])
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

// LoadItems lists the devices of the direction named by the loader id, for the lazily loaded list.
func LoadItems(ctx api.Context, loader string) ([]api.Item, error) {
	direction := strings.TrimPrefix(loader, devicesLoaderBase)
	devices, err := listDevices(ctx, direction)
	if err != nil {
		return nil, err
	}
	return deviceItems(direction, devices), nil
}

func deviceListResult(ctx api.Context, direction string) (api.Result, error) {
	view := newDeviceList(direction)
	source := ctx.Data().Loader(devicesLoaderBase+direction, false)
	view.Source = &source
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func setDefault(ctx api.Context, direction, uid string) (api.Result, error) {
	if _, err := runTool(ctx, "set", direction, uid); err != nil {
		return api.Result{}, err
	}
	devices, err := listDevices(ctx, direction)
	if err != nil {
		return api.Result{}, err
	}
	view := newDeviceList(direction)
	view.Items = deviceItems(direction, devices)
	return api.Result{View: &view, Navigation: api.NavReplace}, nil
}

func newDeviceList(direction string) api.View {
	title, placeholder := "Audio Outputs", "Search speakers, headphones..."
	if direction == "input" {
		title, placeholder = "Audio Inputs", "Search microphones..."
	}
	view := api.ListView(title)
	view.Placeholder = placeholder
	view.EmptyView = &api.EmptyState{Title: "No audio devices found", Subtitle: "No connected audio devices for this direction."}
	return view
}

func deviceItems(direction string, devices []audioDevice) []api.Item {
	items := make([]api.Item, 0, len(devices))
	for _, device := range devices {
		items = append(items, deviceItem(direction, device))
	}
	return items
}

// deviceItem carries the UID and direction in its action's arguments, so the row needs no closure.
func deviceItem(direction string, device audioDevice) api.Item {
	item := api.Item{
		ID:      device.UID,
		Title:   device.Name,
		Icon:    "volume-2",
		Primary: api.Primary(api.Run(setDefaultID, "Set as Default", map[string]string{"direction": direction, "uid": device.UID})),
	}
	if direction == "input" {
		item.Icon = "mic"
	}
	if item.Title == "" {
		item.Title = "Unknown Device"
	}
	if device.IsDefault {
		item.Subtitle = "Current Default"
		item.Accessories = []api.Accessory{{Text: "✓"}}
	} else {
		item.Subtitle = fmt.Sprintf("%d channels", device.Channels)
	}
	return item
}

func listDevices(ctx api.Context, direction string) ([]audioDevice, error) {
	output, err := runTool(ctx, "list", direction)
	if err != nil {
		return nil, err
	}
	var devices []audioDevice
	if err := json.Unmarshal([]byte(output), &devices); err != nil {
		return nil, errors.New("Could not read the audio device list returned by CoreAudio.")
	}
	return devices, nil
}

func runTool(ctx api.Context, args ...string) (string, error) {
	if err := ensureTool(ctx); err != nil {
		return "", err
	}
	result, err := ctx.Desktop().Shell().Script(toolCommand(args), api.ShellOptions{TimeoutMs: 15000})
	if err != nil {
		return "", err
	}
	if result.ExitCode != 0 {
		return "", errors.New(firstNonEmpty(strings.TrimSpace(result.Stderr), strings.TrimSpace(result.Stdout), fmt.Sprintf("Audio helper exited with code %d", result.ExitCode)))
	}
	return result.Stdout, nil
}

func toolCommand(args []string) string {
	quoted := make([]string, 0, len(args))
	for _, arg := range args {
		quoted = append(quoted, "'"+strings.ReplaceAll(arg, "'", `'\''`)+"'")
	}
	return `"` + toolPath + `" ` + strings.Join(quoted, " ")
}

func ensureTool(ctx api.Context) error {
	check, err := ctx.Desktop().Shell().Script(`test -x "`+toolPath+`"`, api.ShellOptions{})
	if err != nil {
		return err
	}
	if check.ExitCode == 0 {
		return nil
	}
	result, err := ctx.Desktop().Shell().Script(compileScript, api.ShellOptions{TimeoutMs: 120000})
	if err != nil {
		return err
	}
	if result.ExitCode != 0 {
		return fmt.Errorf("CoreAudio helper compilation failed: %s", firstNonEmpty(result.Stderr, result.Stdout))
	}
	return nil
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}
