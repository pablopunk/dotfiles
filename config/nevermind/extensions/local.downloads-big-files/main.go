package main

import (
	"errors"
	"fmt"
	"math"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	listCommandID  = "list-big-files"
	trashActionID  = "move-to-trash"
	bigFilesLoader = "big-files"
	bigFilesCache  = "downloads-big-files-v1"
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       listCommandID,
		Title:    "List Big Files in Downloads",
		Subtitle: "Recursive, ordered by size",
		Aliases:  []string{"big files downloads", "large downloads", "downloads size", "biggest downloads"},
		Icon:     "hard-drive",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case listCommandID:
		return bigFilesResult(ctx)
	case trashActionID:
		return moveToTrash(ctx, in.Ref.Args["path"])
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

// LoadItems fills the list in the background. The host caches the rows for a minute and keeps them for five.
func LoadItems(ctx api.Context, loader string) ([]api.Item, error) {
	if loader != bigFilesLoader {
		return nil, fmt.Errorf("unknown loader %q", loader)
	}
	files, err := ctx.Desktop().Files().Find([]string{"~/Downloads"}, api.FindOptions{
		SortBy:    "size",
		Order:     "desc",
		Depth:     2,
		Limit:     100,
		ScanLimit: 10000,
	})
	if err != nil {
		return nil, err
	}
	sort.SliceStable(files, func(i, j int) bool { return files[i].Size > files[j].Size })
	canQuickLook := ctx.System().HasCapability("quick-look")
	items := make([]api.Item, 0, len(files))
	for _, file := range files {
		items = append(items, bigFileItem(ctx, file, canQuickLook))
	}
	return items, nil
}

func bigFilesResult(ctx api.Context) (api.Result, error) {
	view := api.ListView("Big Files in Downloads")
	view.Placeholder = "Filter big files…"
	source := ctx.Data().StaleWhileRevalidate(bigFilesLoader, bigFilesCache, time.Minute, 5*time.Minute, true)
	view.Source = &source
	view.EmptyView = &api.EmptyState{Title: "No files found", Subtitle: "Your Downloads folder is empty."}
	refresh := ctx.Views().Refresh()
	refresh.Title = "Refresh"
	view.Actions = []api.Action{refresh}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func bigFileItem(ctx api.Context, file api.FileRef, canQuickLook bool) api.Item {
	sizeLabel := formatBytes(file.Size)
	display := file.DisplayPath
	if display == "" {
		display = file.Path
	}
	label := sizeLabel + " • " + display
	actions := []api.Action{
		trashAction(file, label),
		api.RevealPath("Reveal in Finder", file.Path),
	}
	if canQuickLook {
		actions = append(actions, api.Action{Kind: api.ActionQuickLook, Title: "Quick Look", Path: file.Path})
	}
	actions = append(actions, api.CopyText("Copy Path", file.Path, false))
	return api.Item{
		ID:          file.Path,
		Title:       file.Name,
		Subtitle:    label,
		Icon:        "file",
		Keywords:    []string{file.Name, file.Extension},
		Accessories: []api.Accessory{{Text: sizeLabel, Tone: api.ToneWarning}},
		File:        &file,
		Primary:     api.Primary(api.OpenPath("Open File", file.Path)),
		Actions:     actions,
	}
}

func trashAction(file api.FileRef, label string) api.Action {
	action := api.Run(trashActionID, "Move to Trash", map[string]string{"path": file.Path})
	action.Shortcut = "CommandOrControl+Backspace"
	return api.Destructive(api.WithConfirmation(action, api.Confirmation{
		Message:      fmt.Sprintf("Move \"%s\" to Trash?\n%s", file.Name, label),
		ConfirmLabel: "Move to Trash",
		CancelLabel:  "Cancel",
		Destructive:  true,
	}))
}

func moveToTrash(ctx api.Context, path string) (api.Result, error) {
	result, err := ctx.Desktop().Shell().AppleScript(trashScript(path), api.ShellOptions{})
	if err != nil {
		return api.Result{}, err
	}
	if result.ExitCode != 0 {
		return api.Result{}, errors.New(trashFailure(result.Stderr, result.Stdout))
	}
	ctx.Views().Invalidate()
	return api.Result{Patch: &api.ViewPatch{RemoveItemIDs: []string{path}}}, nil
}

var appleScriptEscaper = strings.NewReplacer(`\`, `\\`, `"`, `\"`)

func trashScript(path string) string {
	return fmt.Sprintf(`tell application "Finder" to delete POSIX file "%s"`, appleScriptEscaper.Replace(path))
}

func trashFailure(stderr, stdout string) string {
	detail := strings.TrimSpace(stderr)
	if detail == "" {
		detail = strings.TrimSpace(stdout)
	}
	if detail == "" {
		return "Could not move to Trash."
	}
	return "Could not move to Trash: " + detail
}

// formatBytes matches the 1.x labels: whole bytes below 1 KB, then one decimal below 100 and none above.
func formatBytes(size int64) string {
	if size < 1024 {
		return fmt.Sprintf("%d B", size)
	}
	units := []string{"B", "KB", "MB", "GB", "TB"}
	value := float64(size)
	unit := 0
	for value >= 1024 && unit < len(units)-1 {
		value /= 1024
		unit++
	}
	rounded := math.Round(value*10) / 10
	if value >= 100 {
		rounded = math.Round(value)
	}
	return strconv.FormatFloat(rounded, 'f', -1, 64) + " " + units[unit]
}
