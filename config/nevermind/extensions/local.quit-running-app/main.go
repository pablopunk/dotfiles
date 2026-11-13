package main

import (
	"errors"
	"fmt"
	"regexp"
	"sort"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	commandQuitApp = "quit-app"
	actionKill     = "kill"
	loaderApps     = "running-apps"
)

var appLinePattern = regexp.MustCompile(`^\s*(\d+)\s+(/Applications/.*?\.app)(?:/|$)`)

type runningApp struct {
	name       string
	bundlePath string
	pids       []string
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       commandQuitApp,
		Title:    "Quit App",
		Subtitle: "List and force-kill running apps from /Applications",
		Aliases:  []string{"kill app", "force quit app"},
		Icon:     "power-off",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case commandQuitApp:
		view := api.View{
			Kind:        api.ViewList,
			Title:       "Quit App",
			Placeholder: "Search running apps…",
			Source:      &api.DataSource{Loader: loaderApps, Retry: true},
			EmptyView:   &api.EmptyState{Title: "No Running Apps", Subtitle: "No apps running from /Applications were found."},
		}
		return api.Result{View: &view, Navigation: api.NavPush}, nil
	case actionKill:
		return killApp(ctx, in.Ref.Args)
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func LoadItems(ctx api.Context, loader string) ([]api.Item, error) {
	if loader != loaderApps {
		return nil, fmt.Errorf("unknown loader %q", loader)
	}
	result, err := ctx.Desktop().Shell().Exec("/bin/ps", []string{"-axo", "pid=,comm="}, api.ShellOptions{TimeoutMs: 5000, OutputLimit: 1000000})
	if err != nil {
		return nil, err
	}
	if result.ExitCode != 0 {
		return nil, errors.New(firstNonEmpty(strings.TrimSpace(result.Stderr), "Could not list running applications."))
	}
	var items []api.Item
	for _, app := range parseRunningApps(result.Stdout) {
		items = append(items, appItem(ctx, app))
	}
	return items, nil
}

func parseRunningApps(output string) []runningApp {
	var apps []runningApp
	indexByPath := map[string]int{}
	for _, line := range strings.Split(output, "\n") {
		match := appLinePattern.FindStringSubmatch(line)
		if match == nil {
			continue
		}
		pid, bundlePath := match[1], match[2]
		name := bundleName(bundlePath)
		if name == "Nevermind" {
			continue
		}
		if index, ok := indexByPath[bundlePath]; ok {
			if !contains(apps[index].pids, pid) {
				apps[index].pids = append(apps[index].pids, pid)
			}
			continue
		}
		indexByPath[bundlePath] = len(apps)
		apps = append(apps, runningApp{name: name, bundlePath: bundlePath, pids: []string{pid}})
	}
	sort.SliceStable(apps, func(i, j int) bool {
		return strings.ToLower(apps[i].name) < strings.ToLower(apps[j].name)
	})
	return apps
}

func appItem(ctx api.Context, app runningApp) api.Item {
	item := api.Item{
		ID:          app.bundlePath,
		Title:       app.name,
		Subtitle:    app.bundlePath,
		Accessories: []api.Accessory{{Text: pidLabel(app.pids), Tone: api.ToneMuted}},
		Keywords:    []string{"quit", "kill", "force quit", app.bundlePath},
		Primary:     api.Primary(killAction(app)),
	}
	if icon, found, err := ctx.Desktop().Apps().Icon(app.bundlePath); err == nil && found && icon != "" {
		item.Image = &api.Image{Src: icon}
	}
	return item
}

func killAction(app runningApp) api.Action {
	action := api.Run(actionKill, "Kill "+app.name, map[string]string{
		"name": app.name,
		"pids": strings.Join(app.pids, ","),
	})
	action.Icon = "skull"
	return api.Destructive(action)
}

func killApp(ctx api.Context, args map[string]string) (api.Result, error) {
	name := args["name"]
	argv := append([]string{"-KILL"}, strings.Split(args["pids"], ",")...)
	result, err := ctx.Desktop().Shell().Exec("/bin/kill", argv, api.ShellOptions{TimeoutMs: 5000})
	if err != nil {
		return api.Result{}, err
	}
	if result.ExitCode != 0 {
		return api.Result{}, errors.New(firstNonEmpty(strings.TrimSpace(result.Stderr), "Could not kill "+name+"."))
	}
	if err := ctx.Indicators().Show(api.IndicatorInput{Title: name + " killed", Status: api.IndicatorSuccess, DurationMs: 1800}); err != nil {
		return api.Result{}, err
	}
	return api.Result{Navigation: api.NavPop}, nil
}

func pidLabel(pids []string) string {
	if len(pids) == 1 {
		return "PID " + pids[0]
	}
	return fmt.Sprintf("%d processes", len(pids))
}

func bundleName(bundlePath string) string {
	parts := strings.Split(bundlePath, "/")
	name := strings.TrimSuffix(parts[len(parts)-1], ".app")
	if name == "" {
		return bundlePath
	}
	return name
}

func contains(values []string, value string) bool {
	for _, candidate := range values {
		if candidate == value {
			return true
		}
	}
	return false
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}
