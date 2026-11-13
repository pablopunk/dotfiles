package main

import (
	"fmt"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const toggleThemeCommandID = "toggle-theme"

const toggleThemeScript = `
tell application "System Events"
  tell appearance preferences
    set dark mode to not dark mode
  end tell
end tell
`

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       toggleThemeCommandID,
		Title:    "Toggle System Theme",
		Subtitle: "Switch between light and dark mode",
		Icon:     "circle-lefthalf-fill",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	if in.Ref.ID != toggleThemeCommandID {
		return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
	}
	_, err := ctx.Desktop().Shell().AppleScript(toggleThemeScript, api.ShellOptions{})
	return api.Result{}, err
}
