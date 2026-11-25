package main

import (
	"fmt"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{
		{ID: "caffeinate", Title: "Caffeinate Mac", Subtitle: "Keep your Mac awake indefinitely", Icon: "coffee", DismissAfterRun: true},
		{ID: "decaffeinate", Title: "Decaffeinate Mac", Subtitle: "Allow your Mac to sleep normally", Icon: "moon", DismissAfterRun: true},
		{ID: "toggle", Title: "Toggle Caffeinate", Subtitle: "Switch between awake and normal sleep", Icon: "coffee", DismissAfterRun: true},
	}, nil
}

func MenuBarTriggers() []api.Trigger {
	return []api.Trigger{{Type: api.TriggerInterval, Every: "30s"}}
}

func MenuBars(ctx api.Context) ([]api.MenuBar, error) {
	active := isActive(ctx)
	icon := api.MenuBarIcon("moon")
	title := ""
	tooltip := "Caffeinate: off — Mac can sleep"
	statusTitle := "Off — Mac can sleep"
	toggleTitle := "Turn On — Keep Mac Awake"
	toggleIcon := api.MenuBarIcon("coffee")
	if active {
		icon = api.MenuBarIcon("coffee")
		tooltip = "Caffeinate: on — Mac stays awake"
		statusTitle = "On — Mac stays awake"
		toggleTitle = "Turn Off — Allow Sleep"
		toggleIcon = api.MenuBarIcon("moon")
	}
	toggleAct := api.Run("toggle", toggleTitle, nil)
	statusRow := api.MenuRow{ID: "status", Title: statusTitle, Subtitle: "caffeinate -di", Icon: icon, Disabled: true, Checked: api.Checkbox(active)}
	toggleRow := api.MenuRow{ID: "toggle", Title: toggleTitle, Icon: toggleIcon, Action: &toggleAct}
	bar := api.MenuBar{
		ID:      "caffeinate",
		Icon:    icon,
		Title:   title,
		Tooltip: tooltip,
		Sections: []api.MenuSection{
			{Title: "Caffeinate", Rows: []api.MenuRow{statusRow, toggleRow}},
		},
	}
	return []api.MenuBar{bar}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case "caffeinate":
		return caffeinate(ctx)
	case "decaffeinate":
		return decaffeinate(ctx)
	case "toggle":
		if isActive(ctx) {
			return decaffeinate(ctx)
		}
		return caffeinate(ctx)
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func isActive(ctx api.Context) bool {
	res, err := ctx.Desktop().Shell().Exec("/usr/bin/pgrep", []string{"-x", "caffeinate"}, api.ShellOptions{TimeoutMs: 5000, OutputLimit: 1024})
	if err != nil {
		return false
	}
	return res.ExitCode == 0
}

// caffeinate keeps the display and idle sleep awake until decaffeinate runs.
func caffeinate(ctx api.Context) (api.Result, error) {
	if isActive(ctx) {
		ctx.Views().RefreshMenuBar()
		return api.Result{Toast: &api.Toast{Message: "Already keeping Mac awake ☕"}}, nil
	}
	_, err := ctx.Desktop().Shell().Script("nohup /usr/bin/caffeinate -di > /dev/null 2>&1 &", api.ShellOptions{})
	if err != nil {
		ctx.Logs().Log(api.LogError, "Failed to run caffeinate", err.Error())
		return api.Result{Toast: &api.Toast{Message: "Failed to caffeinate Mac.", Tone: "error"}}, nil
	}
	ctx.Views().RefreshMenuBar()
	return api.Result{Toast: &api.Toast{Message: "Mac will stay awake indefinitely ☕"}}, nil
}

// decaffeinate stops caffeinate. killall fails when caffeinate was not running, which the user does not need to hear about.
func decaffeinate(ctx api.Context) (api.Result, error) {
	_, _ = ctx.Desktop().Shell().Exec("/usr/bin/killall", []string{"caffeinate"}, api.ShellOptions{})
	ctx.Views().RefreshMenuBar()
	return api.Result{Toast: &api.Toast{Message: "Sleep enabled. Caffeinate deactivated."}}, nil
}
