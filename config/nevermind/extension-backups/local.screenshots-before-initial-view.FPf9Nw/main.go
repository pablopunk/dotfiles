package main

import (
	"fmt"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	gridCommandID   = "screenshots.grid"
	filesCacheKey   = "screenshots-files-v2"
	resultLimit     = 80
	scanCooldown    = 5 * time.Second
	previewAction   = "preview"
	stepAction      = "step"
	openWithAction  = "open-with"
	emptyTitle      = "No screenshots"
	emptySubtitle   = "No recent screenshots or screen recordings found."
	shortcutPreview = "Command+Y"
)

var screenshotRoots = []string{"~/Desktop", "~/Downloads", "~/Documents/CleanShot X"}

var videoExtensions = map[string]bool{"mp4": true, "mov": true, "m4v": true, "webm": true, "mkv": true, "avi": true}

var lastScanAt time.Time

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       gridCommandID,
		Title:    "Screenshots",
		Subtitle: "Recent screenshots & screen recordings",
		Icon:     "grid",
		Aliases:  []string{"screen shots", "screen recordings", "cleanshot"},
		Triggers: []api.Trigger{{
			Type:       api.TriggerFilesChanged,
			Roots:      screenshotRoots,
			DebounceMs: 500,
			FileKind:   api.FileKindMedia,
		}},
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case gridCommandID:
		return gridResult(ctx, in.Launch), nil
	case previewAction:
		return previewResult(ctx, refIndex(in.Ref), api.NavPush), nil
	case stepAction:
		return previewResult(ctx, refIndex(in.Ref), api.NavReplace), nil
	case openWithAction:
		return openWithResult(ctx, in.Ref.Args["path"])
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func gridResult(ctx api.Context, launch api.LaunchContext) api.Result {
	refreshing := launch.Trigger != nil || launch.Refresh
	files := cachedFiles(ctx)
	if refreshing {
		files = scanScreenshots(ctx)
	}
	view := screenshotGrid(ctx, files)
	if !refreshing && (len(files) == 0 || ctx.Clock().Now().Sub(lastScanAt) > scanCooldown) {
		lastScanAt = ctx.Clock().Now()
		view.Refresh = &api.Refresh{Immediate: true, Mode: api.PatchReplace, Ref: &api.ActionRef{ID: gridCommandID}}
	}
	return api.Result{View: &view, Navigation: api.NavPush}
}

func cachedFiles(ctx api.Context) []api.FileRef {
	var files []api.FileRef
	if _, err := ctx.Storage().Get(filesCacheKey, &files); err != nil {
		ctx.Logs().Log(api.LogError, "Failed to read screenshots cache", map[string]string{"error": err.Error()})
	}
	return files
}

func scanScreenshots(ctx api.Context) []api.FileRef {
	var found []api.FileRef
	for _, root := range screenshotRoots {
		files, err := ctx.Desktop().Files().Find([]string{root}, api.FindOptions{SortBy: "added", Depth: 0, Limit: resultLimit, Kind: "media"})
		if err == nil {
			found = append(found, files...)
		}
	}
	sort.SliceStable(found, func(i, j int) bool {
		return newestMs(found[i]) > newestMs(found[j])
	})
	if len(found) > resultLimit {
		found = found[:resultLimit]
	}
	if err := ctx.Storage().Set(filesCacheKey, found); err != nil {
		ctx.Logs().Log(api.LogError, "Failed in background scan", map[string]string{"error": err.Error()})
	}
	return found
}

func newestMs(file api.FileRef) int64 {
	newest := file.DateAddedMs
	if file.MtimeMs > newest {
		newest = file.MtimeMs
	}
	if file.BirthtimeMs > newest {
		newest = file.BirthtimeMs
	}
	return newest
}

func screenshotGrid(ctx api.Context, files []api.FileRef) api.View {
	hydrated := hydrateAll(ctx, files)
	items := make([]api.Item, 0, len(hydrated))
	for index := range hydrated {
		items = append(items, screenshotItem(hydrated, index))
	}
	view := api.GridView("Screenshots", 0, items...)
	view.ID = gridCommandID
	view.Size = api.SizeLarge
	view.Grid.Layout = "wide"
	view.IsLoading = len(files) == 0
	view.EmptyView = &api.EmptyState{Title: emptyTitle, Subtitle: emptySubtitle}
	return view
}

func hydrateAll(ctx api.Context, files []api.FileRef) []api.FileRef {
	out := make([]api.FileRef, 0, len(files))
	for _, file := range files {
		out = append(out, hydrate(ctx, file))
	}
	return out
}

func hydrate(ctx api.Context, file api.FileRef) api.FileRef {
	fileURL := ctx.Desktop().Files().FileURL(file.Path)
	thumbnail, _ := ctx.Desktop().Files().Thumbnail(file.Path)
	file.FileURL = fileURL
	file.ThumbnailURL = thumbnail
	file.URL = orDefault(thumbnail, fileURL)
	file.VideoURL = ""
	if isVideo(file) {
		file.VideoURL = fileURL
	}
	return file
}

func isVideo(file api.FileRef) bool {
	if file.Kind == "video" {
		return true
	}
	extension := file.Extension
	if extension == "" {
		extension = filepath.Ext(file.Name)
	}
	return videoExtensions[strings.TrimPrefix(strings.ToLower(extension), ".")]
}

func screenshotItem(files []api.FileRef, index int) api.Item {
	file := files[index]
	preview := api.Run(previewAction, "Preview", map[string]string{"index": strconv.Itoa(index)})
	preview.Shortcut = shortcutPreview
	item := api.Item{
		ID:       file.Path,
		Title:    file.Name,
		Subtitle: file.DisplayPath,
		Image:    &api.Image{Src: orDefault(file.ThumbnailURL, orDefault(file.URL, file.FileURL))},
		Primary:  api.Primary(preview),
	}
	if isVideo(file) {
		item.Video = orDefault(file.VideoURL, orDefault(file.FileURL, file.URL))
	}
	item.Actions = []api.Action{
		preview,
		copyAction(file),
		api.CopyText("Copy Path", file.Path, false),
		quickLookAction(file.Path),
		api.RevealPath("Reveal in Finder", file.Path),
		api.OpenPath("Open", file.Path),
		api.Run(openWithAction, "Open with…", map[string]string{"path": file.Path}),
	}
	return item
}

func copyAction(file api.FileRef) api.Action {
	if isVideo(file) {
		return api.CopyText("Copy", file.Path, false)
	}
	return api.Action{Kind: api.ActionCopyImage, Title: "Copy image", Path: file.Path}
}

func quickLookAction(path string) api.Action {
	return api.Action{Kind: api.ActionQuickLook, Title: "Quick Look", Path: path}
}

func previewResult(ctx api.Context, index int, navigation api.NavigationMode) api.Result {
	files := hydrateAll(ctx, cachedFiles(ctx))
	if index < 0 || index >= len(files) {
		return api.Result{}
	}
	view := previewView(files[index], index, len(files))
	view.Actions = previewActions(files, index)
	return api.Result{View: &view, Navigation: navigation}
}

func previewView(file api.FileRef, index, count int) api.View {
	video := isVideo(file)
	adjusted := file
	adjusted.Kind = "image"
	adjusted.VideoURL = ""
	adjusted.URL = orDefault(file.FileURL, file.URL)
	if video {
		adjusted.Kind = "video"
		adjusted.VideoURL = orDefault(file.VideoURL, orDefault(file.URL, file.FileURL))
	}
	view := api.View{
		Kind:                  api.ViewFilePreview,
		Title:                 fmt.Sprintf("%s (%d/%d)", file.Name, index+1, count),
		Size:                  api.SizeLarge,
		ActionPanelVisibility: api.PanelHidden,
		File:                  &api.FilePreview{File: adjusted},
	}
	return view
}

func previewActions(files []api.FileRef, index int) []api.Action {
	file := files[index]
	var actions []api.Action
	if len(files) > 1 {
		next := (index + 1) % len(files)
		previous := (index - 1 + len(files)) % len(files)
		actions = append(actions,
			withShortcut(api.Run(stepAction, "Next", map[string]string{"index": strconv.Itoa(next)}), "Right"),
			withShortcut(api.Run(stepAction, "Previous", map[string]string{"index": strconv.Itoa(previous)}), "Left"),
		)
	}
	return append(actions,
		copyAction(file),
		api.CopyText("Copy Path", file.Path, false),
		quickLookAction(file.Path),
		api.RevealPath("Reveal in Finder", file.Path),
	)
}

func withShortcut(action api.Action, shortcut string) api.Action {
	action.Shortcut = shortcut
	return action
}

func openWithResult(ctx api.Context, path string) (api.Result, error) {
	apps, err := ctx.Desktop().Files().OpenWithApps(path)
	if err != nil {
		return api.Result{}, err
	}
	items := make([]api.Item, 0, len(apps))
	for _, app := range apps {
		items = append(items, openWithItem(path, app))
	}
	view := api.ListView("Open with…", items...)
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func openWithItem(path string, app api.App) api.Item {
	name := orDefault(app.Name, "Unknown App")
	action := api.Action{Kind: api.ActionOpenWith, Title: "Open with " + orDefault(app.Name, "App"), Path: path, App: orDefault(app.Path, app.Name)}
	return api.Item{ID: orDefault(app.Path, app.Name), Title: name, Primary: api.Primary(action)}
}

func refIndex(ref api.ActionRef) int {
	index, err := strconv.Atoi(ref.Args["index"])
	if err != nil {
		return -1
	}
	return index
}

func orDefault(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
