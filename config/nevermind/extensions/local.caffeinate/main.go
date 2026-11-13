package main

import (
	"fmt"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{
		{ID: "caffeinate", Title: "Caffeinate Mac", Subtitle: "Keep your Mac awake indefinitely", Icon: "coffee", DismissAfterRun: true},
		{ID: "decaffeinate", Title: "Decaffeinate Mac", Subtitle: "Allow your Mac to sleep normally", Icon: "moon", DismissAfterRun: true},
	}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case "caffeinate":
		return caffeinate(ctx)
	case "decaffeinate":
		return decaffeinate(ctx)
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

// caffeinate keeps the display and idle sleep awake until decaffeinate runs.
func caffeinate(ctx api.Context) (api.Result, error) {
	_, err := ctx.Desktop().Shell().Script("nohup /usr/bin/caffeinate -di > /dev/null 2>&1 &", api.ShellOptions{})
	if err != nil {
		ctx.Logs().Log(api.LogError, "Failed to run caffeinate", err.Error())
		return api.Result{Toast: &api.Toast{Message: "Failed to caffeinate Mac.", Tone: "error"}}, nil
	}
	return api.Result{Toast: &api.Toast{Message: "Mac will stay awake indefinitely ☕"}}, nil
}

// decaffeinate stops caffeinate. killall fails when caffeinate was not running, which the user does not need to hear about.
func decaffeinate(ctx api.Context) (api.Result, error) {
	_, _ = ctx.Desktop().Shell().Exec("/usr/bin/killall", []string{"caffeinate"}, api.ShellOptions{})
	return api.Result{Toast: &api.Toast{Message: "Sleep enabled. Caffeinate deactivated."}}, nil
}
