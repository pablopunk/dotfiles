package main

import (
	"fmt"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	syncthingCommandID = "syncthing-browser"
	syncthingURL       = "http://127.0.0.1:8384/"
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       syncthingCommandID,
		Title:    "Syncthing Browser",
		Subtitle: "Open your Syncthing page in the browser",
		Aliases:  []string{"Open Syncthing", "Syncthing UI", "Syncthing Web UI"},
		Icon:     "refresh-cw",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	if in.Ref.ID != syncthingCommandID {
		return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
	}
	next := api.OpenURL("Open Syncthing", syncthingURL)
	return api.Result{Next: &next}, nil
}
