package main

import (
	"errors"
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	restartCommandID = "restart-app"
	runningAppsLoad  = "running-apps"
	actionRestart    = "restart"
	actionForce      = "force-restart"
	actionQuit       = "quit"
)

var runningAppPattern = regexp.MustCompile(`^\s*(\d+)\s+(/(?:Applications|System/Applications|Users/[^/]+/Applications)/.*?\.app)(?:/|$)`)

type runningApp struct {
	name       string
	bundlePath string
	pids       []int
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       restartCommandID,
		Title:    "Restart App",
		Subtitle: "Choose a running application to restart",
		Aliases:  []string{"restart application", "relaunch app", "reboot app", "reload app"},
		Icon:     "rotate-cw",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case restartCommandID:
		return restartListResult(), nil
	case actionRestart:
		return popAfter(restartApp(ctx, appFromRef(in.Ref), false))
	case actionForce:
		return popAfter(restartApp(ctx, appFromRef(in.Ref), true))
	case actionQuit:
		return quitApp(ctx, appFromRef(in.Ref)), nil
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func LoadItems(ctx api.Context, loader string) ([]api.Item, error) {
	apps, err := listRunningApps(ctx)
	if err != nil {
		return nil, err
	}
	items := make([]api.Item, 0, len(apps))
	for _, app := range apps {
		items = append(items, appItem(ctx, app))
	}
	return items, nil
}

func restartListResult() api.Result {
	view := api.ListView("Restart App")
	view.Placeholder = "Search running apps to restart…"
	view.Source = &api.DataSource{Loader: runningAppsLoad, Retry: true}
	view.EmptyView = &api.EmptyState{Title: "No Running Apps", Subtitle: "No running applications were found."}
	return api.Result{View: &view, Navigation: api.NavPush}
}

func popAfter(err error) (api.Result, error) {
	if err != nil {
		return api.Result{}, err
	}
	return api.Result{Navigation: api.NavPop}, nil
}

func listRunningApps(ctx api.Context) ([]runningApp, error) {
	result, err := ctx.Desktop().Shell().Exec("/bin/ps", []string{"-axo", "pid=,comm="}, api.ShellOptions{TimeoutMs: 5000, OutputLimit: 1000000})
	if err != nil {
		return nil, err
	}
	if result.ExitCode != 0 {
		return nil, errors.New(orDefault(strings.TrimSpace(result.Stderr), "Could not list running applications."))
	}
	return parseRunningApps(result.Stdout, installedNames(ctx)), nil
}

func installedNames(ctx api.Context) map[string]string {
	names := map[string]string{}
	installed, err := ctx.Desktop().Apps().List()
	if err != nil {
		return names
	}
	for _, app := range installed {
		if app.Path != "" && app.Name != "" {
			names[app.Path] = app.Name
		}
	}
	return names
}

func parseRunningApps(output string, installed map[string]string) []runningApp {
	byPath := map[string]*runningApp{}
	var order []string
	for _, line := range strings.Split(output, "\n") {
		match := runningAppPattern.FindStringSubmatch(line)
		if match == nil || strings.Contains(match[2], "Nevermind.app") {
			continue
		}
		pid, _ := strconv.Atoi(match[1])
		bundlePath := match[2]
		name := orDefault(installed[bundlePath], bundleBaseName(bundlePath))
		if name == "Nevermind" {
			continue
		}
		if app, ok := byPath[bundlePath]; ok {
			app.pids = appendUniquePID(app.pids, pid)
			continue
		}
		byPath[bundlePath] = &runningApp{name: name, bundlePath: bundlePath, pids: []int{pid}}
		order = append(order, bundlePath)
	}
	apps := make([]runningApp, 0, len(order))
	for _, path := range order {
		apps = append(apps, *byPath[path])
	}
	sort.SliceStable(apps, func(i, j int) bool {
		return strings.ToLower(apps[i].name) < strings.ToLower(apps[j].name)
	})
	return apps
}

func bundleBaseName(bundlePath string) string {
	base := bundlePath[strings.LastIndex(bundlePath, "/")+1:]
	return orDefault(strings.TrimSuffix(base, ".app"), bundlePath)
}

func appendUniquePID(pids []int, pid int) []int {
	for _, existing := range pids {
		if existing == pid {
			return pids
		}
	}
	return append(pids, pid)
}

func appItem(ctx api.Context, app runningApp) api.Item {
	item := api.Item{
		ID:          app.bundlePath,
		Title:       app.name,
		Subtitle:    app.bundlePath,
		Accessories: []api.Accessory{{Text: pidLabel(app.pids), Tone: api.ToneMuted}},
		Keywords:    []string{app.name, "restart", "relaunch", "reboot", app.bundlePath},
	}
	if image := appIcon(ctx, app.bundlePath); image != "" {
		item.Image = &api.Image{Src: image}
	} else {
		item.Icon = "app-window"
	}
	restart := appAction(app, actionRestart, "Restart "+app.name, "rotate-cw")
	item.Primary = api.Primary(restart)
	item.Actions = []api.Action{
		restart,
		api.Destructive(appAction(app, actionForce, "Force Restart "+app.name, "zap")),
		api.Destructive(appAction(app, actionQuit, "Quit "+app.name, "power-off")),
		api.RevealPath("Reveal in Finder", app.bundlePath),
		api.CopyText("Copy App Path", app.bundlePath, false),
	}
	return item
}

func appAction(app runningApp, id, title, icon string) api.Action {
	action := api.Run(id, title, map[string]string{"bundle": app.bundlePath, "name": app.name, "pids": strings.Join(pidStrings(app.pids), ",")})
	action.Icon = icon
	action.DismissAfterRun = true
	return action
}

func appFromRef(ref api.ActionRef) runningApp {
	app := runningApp{name: ref.Args["name"], bundlePath: ref.Args["bundle"]}
	for _, field := range strings.Split(ref.Args["pids"], ",") {
		if pid, err := strconv.Atoi(field); err == nil {
			app.pids = append(app.pids, pid)
		}
	}
	return app
}

func pidLabel(pids []int) string {
	if len(pids) == 1 {
		return "PID " + strconv.Itoa(pids[0])
	}
	return strconv.Itoa(len(pids)) + " processes"
}

func appIcon(ctx api.Context, bundlePath string) string {
	image, found, err := ctx.Desktop().Apps().Icon(bundlePath)
	if err != nil || !found {
		return ""
	}
	return image
}

func restartApp(ctx api.Context, app runningApp, force bool) error {
	shell := ctx.Desktop().Shell()
	showIndicator(ctx, api.IndicatorInput{Title: "Restarting " + app.name + "…", Status: api.IndicatorLoading})
	if force {
		signalPIDs(shell, "-KILL", app.pids)
	} else {
		signalPIDs(shell, "-TERM", app.pids)
		if alive := waitForExit(ctx, shell, app.pids, 1500*time.Millisecond); len(alive) > 0 {
			signalPIDs(shell, "-KILL", alive)
		}
	}
	time.Sleep(200 * time.Millisecond)
	return relaunch(ctx, app)
}

func relaunch(ctx api.Context, app runningApp) error {
	opened, err := ctx.Desktop().Shell().Exec("/usr/bin/open", []string{app.bundlePath}, api.ShellOptions{TimeoutMs: 5000})
	if err != nil || opened.ExitCode != 0 {
		if launchErr := ctx.Desktop().Apps().Launch(app.bundlePath); launchErr != nil {
			return fmt.Errorf("Failed to relaunch %s: %s", app.name, relaunchDetail(opened, err))
		}
	}
	showIndicator(ctx, api.IndicatorInput{Title: app.name + " restarted", Status: api.IndicatorSuccess, DurationMs: 2000})
	return nil
}

func relaunchDetail(opened api.ShellResult, err error) string {
	if err != nil {
		return err.Error()
	}
	return orDefault(opened.Stderr, "unknown error")
}

func quitApp(ctx api.Context, app runningApp) api.Result {
	signalPIDs(ctx.Desktop().Shell(), "-TERM", app.pids)
	showIndicator(ctx, api.IndicatorInput{Title: app.name + " quit", Status: api.IndicatorSuccess, DurationMs: 1800})
	return api.Result{Navigation: api.NavPop}
}

func signalPIDs(shell api.Shell, signal string, pids []int) {
	_, _ = shell.Exec("/bin/kill", append([]string{signal}, pidStrings(pids)...), api.ShellOptions{TimeoutMs: 3000})
}

func waitForExit(ctx api.Context, shell api.Shell, pids []int, limit time.Duration) []int {
	start := ctx.Clock().Now()
	alive := pids
	for len(alive) > 0 && ctx.Clock().Now().Sub(start) < limit {
		alive = survivors(shell, alive)
		if len(alive) > 0 {
			time.Sleep(150 * time.Millisecond)
		}
	}
	return alive
}

func survivors(shell api.Shell, pids []int) []int {
	var alive []int
	for _, pid := range pids {
		result, err := shell.Exec("/bin/kill", []string{"-0", strconv.Itoa(pid)}, api.ShellOptions{TimeoutMs: 1000})
		if err == nil && result.ExitCode == 0 {
			alive = append(alive, pid)
		}
	}
	return alive
}

func pidStrings(pids []int) []string {
	out := make([]string, 0, len(pids))
	for _, pid := range pids {
		out = append(out, strconv.Itoa(pid))
	}
	return out
}

func showIndicator(ctx api.Context, input api.IndicatorInput) {
	_ = ctx.Indicators().Show(input)
}

func orDefault(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
