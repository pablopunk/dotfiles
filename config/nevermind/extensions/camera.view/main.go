package main

import (
	"fmt"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	cmdOpen     = "open-camera"
	actMirror   = "toggle-mirror"
	actFraming  = "toggle-framing"
	keyMirror   = "mirror"
	keyControls = "controls"
	keyFraming  = "framing"
	keyMuted    = "muted"
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{
		{ID: cmdOpen, Title: "Open Camera", Subtitle: "Webcam feed, switch cameras from Command-K", Icon: "camera"},
	}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case cmdOpen:
		view := buildCameraView(loadPrefs(ctx))
		return api.Result{View: &view, Navigation: api.NavPush}, nil
	case actMirror, actFraming:
		p := togglePref(ctx, in.Ref.ID)
		view := buildCameraView(p)
		return api.Result{View: &view, Navigation: api.NavReplace}, nil
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

type prefs struct {
	mirrored, controls, muted bool
	framing                   string
}

func loadPrefs(ctx api.Context) prefs {
	p := prefs{mirrored: true, controls: true, muted: true, framing: "cover"}
	var b bool
	if found, _ := ctx.Storage().Get(keyMirror, &b); found {
		p.mirrored = b
	}
	if found, _ := ctx.Storage().Get(keyControls, &b); found {
		p.controls = b
	}
	if found, _ := ctx.Storage().Get(keyMuted, &b); found {
		p.muted = b
	}
	var s string
	if found, _ := ctx.Storage().Get(keyFraming, &s); found && (s == "cover" || s == "contain") {
		p.framing = s
	}
	return p
}

func togglePref(ctx api.Context, id string) prefs {
	p := loadPrefs(ctx)
	switch id {
	case actMirror:
		p.mirrored = !p.mirrored
		_ = ctx.Storage().Set(keyMirror, p.mirrored)
	case actFraming:
		p.framing = otherFraming(p.framing)
		_ = ctx.Storage().Set(keyFraming, p.framing)
	}
	return p
}

func otherFraming(f string) string {
	if f == "cover" {
		return "contain"
	}
	return "cover"
}

func withShortcut(a api.Action, s string) api.Action {
	a.Shortcut = s
	return a
}

func cameraOp(op, title, shortcut string) api.Action {
	return api.Action{Kind: api.ActionCamera, Op: op, Title: title, Icon: "camera", Shortcut: shortcut}
}

// buildCameraView leaves DeviceID empty so the host opens the camera last picked from its Cameras menu.
func buildCameraView(p prefs) api.View {
	display := []api.Action{
		cameraOp("next-device", "Next Camera", "n"),
		withShortcut(api.Run(actMirror, mirrorTitle(p.mirrored), nil), "m"),
		withShortcut(api.Run(actFraming, framingTitle(p.framing), nil), "f"),
		cameraOp("toggle-muted", "Toggle Preview Sound", "u"),
		cameraOp("toggle-controls", "Toggle Controls", "c"),
	}
	return api.View{
		ID:    "camera-feed",
		Kind:  api.ViewCamera,
		Title: "Webcam Feed",
		Size:  api.SizeLarge,
		Camera: &api.CameraSpec{
			ShowDeviceSwitcher: api.Checkbox(true),
			Muted:              api.Checkbox(p.muted),
			Controls:           p.controls,
			Mirrored:           p.mirrored,
			Framing:            p.framing,
		},
		Actions:     display,
		ActionPanel: api.Panel(api.Section("Display", display...)),
		FooterHints: []api.FooterHint{
			{Key: "n", Title: "Next"},
			{Key: "m", Title: "Mirror"},
			{Key: "f", Title: "Framing"},
		},
	}
}

func mirrorTitle(on bool) string {
	if on {
		return "Turn Mirror Off"
	}
	return "Turn Mirror On"
}

func framingTitle(f string) string {
	if f == "cover" {
		return "Framing: Contain (fit)"
	}
	return "Framing: Cover (fill)"
}
