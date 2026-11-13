package main

import (
	"fmt"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       "open-camera",
		Title:    "Open Camera",
		Subtitle: "Mirrored webcam feed; press Enter to switch cameras",
		Icon:     "camera",
	}}, nil
}

// RunAction opens the host camera view, mirrored, large. Device switching is the view's own switcher.
func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	if in.Ref.ID != "open-camera" {
		return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
	}
	view := api.View{
		Kind:   api.ViewCamera,
		Title:  "Webcam Feed",
		Size:   api.SizeLarge,
		Camera: &api.CameraSpec{Mirrored: true},
	}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}
