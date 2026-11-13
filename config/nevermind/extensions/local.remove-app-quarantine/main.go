package main

import (
	"fmt"
	"regexp"
	"sort"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	commandRemoveQuarantine = "remove-app-quarantine"
	actionRemove            = "remove"
	quarantineAttribute     = "com.apple.quarantine"
	xattrBinary             = "/usr/bin/xattr"
	findAppsScript          = `for dir in /Applications "$HOME/Applications"; do if [ -d "$dir" ]; then /usr/bin/find "$dir" -maxdepth 2 -name "*.app" -prune -print; fi; done`
)

type quarantineStatus string

const (
	statusQuarantined quarantineStatus = "quarantined"
	statusClear       quarantineStatus = "clear"
	statusUnknown     quarantineStatus = "unknown"
)

var missingAttribute = regexp.MustCompile(`(?i)no such xattr|attribute not found`)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       commandRemoveQuarantine,
		Title:    "Remove App Quarantine",
		Subtitle: "Find quarantined apps and remove the quarantine attribute",
		Icon:     "shield-off",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case commandRemoveQuarantine:
		paths, err := quarantinedApps(ctx)
		if err != nil {
			return api.Result{}, err
		}
		view := appListView(ctx, paths)
		return api.Result{View: &view, Navigation: api.NavPush}, nil
	case actionRemove:
		return removeQuarantine(ctx, in.Ref.Args)
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func appPaths(ctx api.Context) ([]string, error) {
	result, err := ctx.Desktop().Shell().Script(findAppsScript, api.ShellOptions{TimeoutMs: 30000})
	if err != nil {
		return nil, err
	}
	if result.ExitCode != 0 {
		return nil, fmt.Errorf("Could not list apps: %s", firstNonEmpty(strings.TrimSpace(result.Stderr), fmt.Sprintf("find exited %d", result.ExitCode)))
	}
	return uniqueNonEmptyLines(result.Stdout), nil
}

func quarantineOf(ctx api.Context, path string) (quarantineStatus, error) {
	result, err := ctx.Desktop().Shell().Exec(xattrBinary, []string{"-p", quarantineAttribute, path}, api.ShellOptions{TimeoutMs: 10000})
	if err != nil {
		return statusUnknown, err
	}
	if result.ExitCode == 0 {
		return statusQuarantined, nil
	}
	if missingAttribute.MatchString(result.Stderr) {
		return statusClear, nil
	}
	return statusUnknown, nil
}

func quarantinedApps(ctx api.Context) ([]string, error) {
	paths, err := appPaths(ctx)
	if err != nil {
		return nil, err
	}
	var quarantined, unknown []string
	for _, path := range paths {
		status, err := quarantineOf(ctx, path)
		if err != nil {
			return nil, err
		}
		switch status {
		case statusQuarantined:
			quarantined = append(quarantined, path)
		case statusUnknown:
			unknown = append(unknown, path)
		}
	}
	if len(unknown) > 0 {
		return nil, fmt.Errorf("Could not check quarantine on %d app(s), including %s. Check permissions and try again.", len(unknown), unknown[0])
	}
	sort.SliceStable(quarantined, func(i, j int) bool {
		return strings.ToLower(quarantined[i]) < strings.ToLower(quarantined[j])
	})
	return quarantined, nil
}

func appListView(ctx api.Context, paths []string) api.View {
	items := make([]api.Item, 0, len(paths))
	for _, path := range paths {
		items = append(items, appItem(ctx, path))
	}
	view := api.ListView("Remove App Quarantine", items...)
	view.Subtitle = fmt.Sprintf("%d quarantined app(s) in /Applications and ~/Applications", len(paths))
	view.Placeholder = "Find a quarantined app…"
	view.EmptyView = &api.EmptyState{
		Title:    "No quarantined apps found",
		Subtitle: "No .app bundles with com.apple.quarantine found in /Applications or ~/Applications.",
	}
	return view
}

func appItem(ctx api.Context, path string) api.Item {
	name := lastPathComponent(path)
	remove := api.Run(actionRemove, "Remove Quarantine", map[string]string{"path": path, "name": name})
	remove = api.WithConfirmation(remove, api.Confirmation{
		Title:        fmt.Sprintf("Remove quarantine from %s?", name),
		Message:      fmt.Sprintf("Recursively remove the com.apple.quarantine attribute from %s. Only do this if you trust the app. This does not bypass other macOS security checks.", path),
		ConfirmLabel: "Remove Quarantine",
		Destructive:  true,
	})
	return api.Item{
		ID:          path,
		Title:       name,
		Subtitle:    path,
		Icon:        "app-window",
		Accessories: []api.Accessory{{Text: "Quarantined", Tone: api.ToneWarning}},
		Primary:     api.Primary(remove),
		Actions: []api.Action{
			api.RevealPath(ctx.System().Labels().RevealInFileManager, path),
			api.CopyText("Copy App Path", path, false),
		},
	}
}

func removeQuarantine(ctx api.Context, args map[string]string) (api.Result, error) {
	path, name := args["path"], args["name"]
	before, err := quarantineOf(ctx, path)
	if err != nil {
		return api.Result{}, err
	}
	if before != statusQuarantined {
		if before == statusClear {
			return api.Result{}, fmt.Errorf("%s is no longer marked as quarantined. Reopen the command to refresh the list.", name)
		}
		return api.Result{}, fmt.Errorf("Could not verify quarantine on %s; nothing was changed.", name)
	}
	result, err := ctx.Desktop().Shell().Exec(xattrBinary, []string{"-d", "-r", quarantineAttribute, path}, api.ShellOptions{TimeoutMs: 120000})
	if err != nil {
		return api.Result{}, err
	}
	if result.ExitCode != 0 {
		detail := firstNonEmpty(strings.TrimSpace(result.Stderr), strings.TrimSpace(result.Stdout), fmt.Sprintf("xattr exited %d", result.ExitCode))
		return api.Result{}, fmt.Errorf("Could not remove quarantine from %s: %s. You may need write permission for this app.", name, detail)
	}
	after, err := quarantineOf(ctx, path)
	if err != nil {
		return api.Result{}, err
	}
	if after != statusClear {
		return api.Result{}, fmt.Errorf("Could not verify that quarantine was removed from %s.", name)
	}
	paths, err := quarantinedApps(ctx)
	if err != nil {
		return api.Result{}, err
	}
	view := appListView(ctx, paths)
	return api.Result{View: &view, Navigation: api.NavReplace}, nil
}

func uniqueNonEmptyLines(output string) []string {
	seen := map[string]bool{}
	var lines []string
	for _, line := range strings.Split(output, "\n") {
		if line == "" || seen[line] {
			continue
		}
		seen[line] = true
		lines = append(lines, line)
	}
	return lines
}

func lastPathComponent(path string) string {
	parts := strings.Split(path, "/")
	if last := parts[len(parts)-1]; last != "" {
		return last
	}
	return path
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}
