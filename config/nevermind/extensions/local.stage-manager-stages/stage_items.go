package main

import (
	"strings"
	"unicode"
	"unicode/utf8"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func stageItems(ctx api.Context) ([]api.Item, error) {
	raw, err := runAppleScript(ctx, scanScript, 10000)
	if err != nil {
		return nil, err
	}
	stages := parseStages(raw)
	if len(stages) == 0 {
		return []api.Item{inspectItem()}, nil
	}
	apps := appList(ctx)
	windows := listWindows(ctx)
	owners := make([]api.App, len(stages))
	matched := make([]bool, len(stages))
	for index, entry := range stages {
		owners[index], matched[index] = matchApp(entry.name, windows, apps)
	}
	icons := appIcons(ctx, owners, matched)
	items := make([]api.Item, 0, len(stages))
	for index, entry := range stages {
		items = append(items, stageItem(entry, owners[index], matched[index], icons))
	}
	return items, nil
}

func parseStages(raw string) []stage {
	seen := map[string]bool{}
	var stages []stage
	for _, line := range strings.Split(raw, "\n") {
		line = strings.TrimSuffix(line, "\r")
		split := strings.Index(line, "|")
		if split < 0 {
			continue
		}
		path, name := line[:split], strings.TrimSpace(line[split+1:])
		if !stageElementPattern.MatchString(path) || name == "" || seen[path] {
			continue
		}
		seen[path] = true
		stages = append(stages, stage{path: path, name: name})
		if len(stages) >= stageMaxCount {
			break
		}
	}
	return stages
}

func listWindows(ctx api.Context) []windowEntry {
	raw, err := runAppleScript(ctx, windowScript, 15000)
	if err != nil {
		ctx.Logs().Log(api.LogWarn, "Could not correlate stage labels with app windows", map[string]string{"error": err.Error()})
		return nil
	}
	var windows []windowEntry
	for _, line := range strings.Split(raw, "\n") {
		split := strings.Index(line, "|")
		if split > 0 && strings.TrimSpace(line[split+1:]) != "" {
			windows = append(windows, windowEntry{app: line[:split], title: line[split+1:]})
		}
	}
	return windows
}

func appList(ctx api.Context) []api.App {
	apps, err := ctx.Desktop().Apps().List()
	if err != nil {
		return nil
	}
	return apps
}

func matchApp(label string, windows []windowEntry, apps []api.App) (api.App, bool) {
	if owner, ok := ownerForTitle(label, windows); ok {
		if app, found := appNamed(apps, owner); found {
			return app, true
		}
	}
	return appForLabel(label, apps)
}

func ownerForTitle(label string, windows []windowEntry) (string, bool) {
	owners := map[string]bool{}
	for _, window := range windows {
		if key(window.title) == key(label) {
			owners[key(window.app)] = true
		}
	}
	if len(owners) != 1 {
		return "", false
	}
	for owner := range owners {
		return owner, true
	}
	return "", false
}

func appNamed(apps []api.App, name string) (api.App, bool) {
	for _, app := range apps {
		if key(app.Name) == key(name) && app.Path != "" {
			return app, true
		}
	}
	return api.App{}, false
}

func appForLabel(label string, apps []api.App) (api.App, bool) {
	normalized := key(label)
	best := -1
	var found api.App
	for _, app := range apps {
		name := key(app.Name)
		if name == "" || app.Path == "" || !strings.HasPrefix(normalized, name) {
			continue
		}
		if startsNewWord(normalized[len(name):]) && len(name) > best {
			best = len(name)
			found = app
		}
	}
	return found, best >= 0
}

func startsNewWord(rest string) bool {
	if rest == "" {
		return true
	}
	first, _ := utf8.DecodeRuneInString(rest)
	return unicode.IsSpace(first) || strings.ContainsRune(",:;–—-", first)
}

func appIcons(ctx api.Context, owners []api.App, matched []bool) map[string]string {
	icons := map[string]string{}
	for index, app := range owners {
		if !matched[index] || icons[app.Path] != "" {
			continue
		}
		image, found, err := ctx.Desktop().Apps().Icon(app.Path)
		if err == nil && found {
			icons[app.Path] = image
		}
	}
	return icons
}

func stageItem(entry stage, owner api.App, matched bool, icons map[string]string) api.Item {
	item := api.Item{
		ID:       entry.path,
		Title:    entry.name,
		Subtitle: "Stage Manager shelf",
		Primary:  api.Primary(switchActionFor(entry)),
	}
	if matched {
		item.Subtitle = owner.Name + " · Stage Manager shelf"
	}
	if image := icons[owner.Path]; matched && image != "" {
		item.Image = &api.Image{Src: image}
	} else {
		item.Icon = "panels-top-left"
	}
	return item
}

func switchActionFor(entry stage) api.Action {
	action := api.Run(switchAction, "Switch to "+entry.name, map[string]string{"path": entry.path, "label": entry.name})
	action.DismissAfterRun = true
	return action
}

func inspectItem() api.Item {
	return api.Item{
		ID:       "inspect-stage-accessibility",
		Title:    "Inspect Stage Manager access",
		Subtitle: "No shelf buttons found; see what macOS exposes",
		Icon:     "scan-search",
		Primary:  api.Primary(api.Run(inspectAction, "Inspect Stage Manager access", nil)),
	}
}

func key(text string) string {
	return strings.ToLower(strings.TrimSpace(text))
}

func orDefault(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}

// errorResult is the 1.x ui.error: a list with one contextual row that holds the title and the message.
func errorResult(title, message string) api.Result {
	view := api.ErrorView(title, message)
	return api.Result{View: &view, Navigation: api.NavPush}
}
