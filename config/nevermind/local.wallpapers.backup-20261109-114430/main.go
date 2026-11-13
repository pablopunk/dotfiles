package main

import (
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	wallpapersDir   = "~/.config/wallpapers"
	gridCommandID   = "wallpapers.grid"
	setPictureID    = "set-picture"
	previewColorsID = "preview-colors"
	restoreID       = "restore-colors"
	refreshIconID   = "refresh-icon-appearance"
	restartDockID   = "restart-finder-dock"
	backupKey       = "appearance-original-v1"
	rootCacheKey    = "wallpaper-root"
	colorIndicator  = "wallpaper-colors"
	paletteTTL      = 24 * time.Hour
	gridRefreshMs   = 10000
	clusterDistance = 0.16
	secondDistance  = 0.23
)

var colorKeys = []string{"AppleHighlightColor", "AppleIconAppearanceTintColor", "AppleIconAppearanceCustomTintColor", "AppleIconAppearanceTheme"}

var (
	missingDefaults  = regexp.MustCompile(`(?i)does not exist|could not find key|domain/default pair[^\n]*not found`)
	stringPreference = regexp.MustCompile(`(?i)string`)
	noMatchingProcs  = regexp.MustCompile(`(?i)no matching processes`)
)

const sampleScript = `ObjC.import('AppKit');
function run(argv) {
 var image = $.NSImage.alloc.initWithContentsOfFile($(argv[0]));
 if (!image || image.isNil()) throw Error('Cannot decode wallpaper image');
 var bitmap = $.NSBitmapImageRep.imageRepWithData(image.TIFFRepresentation);
 if (!bitmap || bitmap.isNil()) throw Error('Cannot sample wallpaper image');
 var w = Number(bitmap.pixelsWide), h = Number(bitmap.pixelsHigh), samples = [];
 if (w < 1 || h < 1) throw Error('Wallpaper has no pixels');
 for (var y=0;y<40;y++) for (var x=0;x<40;x++) {
  var color = bitmap.colorAtXY(Math.min(w-1,Math.floor((x+0.5)*w/40)),Math.min(h-1,Math.floor((y+0.5)*h/40))).colorUsingColorSpace($.NSColorSpace.sRGBColorSpace);
  if (color && !color.isNil() && Number(color.alphaComponent)>0.5) samples.push([Number(color.redComponent),Number(color.greenComponent),Number(color.blueComponent)]);
 }
 return JSON.stringify(samples);
}`

type snapshot map[string]*string

type palette struct {
	Tint       [3]float64 `json:"tint"`
	Highlight  [3]float64 `json:"highlight"`
	Monochrome bool       `json:"monochrome"`
}

type colorBin struct {
	count int
	sum   [3]float64
}

type colorCluster struct {
	rgb   [3]float64
	count int
}

func Commands(ctx api.Context) ([]api.Command, error) {
	commands := []api.Command{{
		ID:       gridCommandID,
		Title:    "Set Desktop Wallpaper",
		Subtitle: "Browse ~/.config/wallpapers; match icon tint and selection highlight",
		Icon:     "image",
		Aliases:  []string{"wallpapers", "wallpaper", "background", "desktop picture"},
		Triggers: []api.Trigger{{Type: api.TriggerFilesChanged, Roots: []string{wallpapersDir}, DebounceMs: 500, FileKind: api.FileKindImage}},
	}}
	if !isMac(ctx) {
		return commands, nil
	}
	return append(commands,
		api.Command{
			ID:       restoreID,
			Title:    "Restore Previous Colors",
			Subtitle: "Restore the appearance preferences saved before wallpaper color matching",
			Aliases:  []string{"restore wallpaper colors"},
			Icon:     "undo-2",
		},
		api.Command{
			ID:       refreshIconID,
			Title:    "Refresh Wallpaper Icon Appearance",
			Subtitle: "Restart Finder and Dock to reload icon preferences",
			Icon:     "refresh-cw",
		},
	), nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case gridCommandID:
		return gridResult(ctx)
	case setPictureID:
		return api.Result{}, setPicture(ctx, in.Ref.Args["path"], in.Ref.Args["name"], in.Ref.Args["colors"] == "true")
	case previewColorsID:
		return previewColorsResult(ctx, in.Ref.Args["path"])
	case restoreID:
		return api.Result{}, restoreColors(ctx)
	case refreshIconID:
		next := restartDockAction()
		return api.Result{Next: &next}, nil
	case restartDockID:
		return api.Result{}, restartFinderAndDock(ctx)
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func gridResult(ctx api.Context) (api.Result, error) {
	items, err := wallpaperItems(ctx)
	if err != nil {
		return api.Result{}, err
	}
	ctx.Logs().Log(api.LogInfo, "wallpapers.grid.ready", map[string]int{"count": len(items)})
	view := api.GridView("Wallpapers", 0, items...)
	view.ID = "wallpapers-grid"
	view.Subtitle = wallpapersDir
	view.Size = api.SizeLarge
	view.Grid.Layout = "wide"
	view.Placeholder = "Search wallpapers…"
	view.EmptyView = &api.EmptyState{Title: "No Wallpapers Found", Subtitle: "Place your image files in ~/.config/wallpapers to get started."}
	view.Refresh = &api.Refresh{IntervalMs: gridRefreshMs, Mode: api.PatchReplace, Ref: &api.ActionRef{ID: gridCommandID}}
	if isMac(ctx) {
		view.Actions = []api.Action{
			api.Run(restoreID, "Restore Previous Colors", nil),
			api.Run(refreshIconID, "Refresh Wallpaper Icon Appearance", nil),
		}
	}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func wallpaperItems(ctx api.Context) ([]api.Item, error) {
	root, err := wallpaperRoot(ctx)
	if err != nil {
		return nil, err
	}
	started := ctx.Clock().Now()
	ctx.Logs().Log(api.LogInfo, "wallpapers.scan.start", map[string]string{"root": root})
	files, err := ctx.Desktop().Files().Find([]string{root}, api.FindOptions{Kind: "image", Depth: 2, Limit: 300, SortBy: "name", Order: "asc"})
	if err != nil {
		ctx.Logs().Log(api.LogError, "wallpapers.scan.failed", map[string]string{"root": root, "error": err.Error()})
		return nil, fmt.Errorf("Could not load wallpapers: %w", err)
	}
	ctx.Logs().Log(api.LogInfo, "wallpapers.scan.complete", map[string]any{"root": root, "count": len(files), "durationMs": ctx.Clock().Now().Sub(started).Milliseconds()})
	items := make([]api.Item, 0, len(files))
	for _, file := range files {
		items = append(items, wallpaperItem(ctx, file))
	}
	return items, nil
}

func wallpaperItem(ctx api.Context, file api.FileRef) api.Item {
	mac := isMac(ctx)
	title := "Set as Wallpaper"
	if mac {
		title = "Set Wallpaper & Match Colors"
	}
	return api.Item{
		ID:       file.Path,
		Title:    file.Name,
		Subtitle: orDefault(file.DisplayPath, file.Path),
		Image:    &api.Image{Src: orDefault(file.URL, ctx.Desktop().Files().FileURL(file.Path))},
		Primary:  api.Primary(setPictureAction(file, title, true, "image")),
		Actions:  wallpaperActions(file, mac),
	}
}

func wallpaperActions(file api.FileRef, mac bool) []api.Action {
	var actions []api.Action
	if mac {
		actions = append(actions,
			setPictureAction(file, "Set Wallpaper Only", false, ""),
			api.Run(previewColorsID, "Preview Matching Colors", map[string]string{"path": file.Path}),
			api.Run(restoreID, "Restore Previous Colors", nil),
			api.Run(refreshIconID, "Refresh Wallpaper Icon Appearance", nil),
		)
	}
	return append(actions,
		api.Action{Kind: api.ActionQuickLook, Title: "Quick Look", Path: file.Path},
		api.RevealPath("Reveal in Finder", file.Path),
		api.OpenPath("Open Image", file.Path),
		api.CopyText("Copy Path", file.Path, false),
	)
}

func setPictureAction(file api.FileRef, title string, colors bool, icon string) api.Action {
	action := api.Run(setPictureID, title, map[string]string{"path": file.Path, "name": file.Name, "colors": strconv.FormatBool(colors)})
	action.Icon = icon
	return action
}

func restartDockAction() api.Action {
	action := api.Run(restartDockID, "Restart Finder and Dock", nil)
	action.Confirm = &api.Confirmation{
		Title:   "Restart Finder and Dock?",
		Message: "Finder windows and the Dock may briefly disappear. This may refresh icons; some changes still require logout/login. Other apps will not be restarted.",
	}
	return action
}

func previewColorsResult(ctx api.Context, path string) (api.Result, error) {
	colors, err := extractPalette(ctx, path)
	if err != nil {
		return api.Result{}, err
	}
	view := api.View{
		Kind:    api.ViewPreview,
		Title:   "Wallpaper Palette",
		Preview: &api.PreviewSpec{Image: &api.Image{Src: ctx.Desktop().Files().FileURL(path)}, Text: paletteSummary(colors)},
	}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func paletteSummary(colors palette) string {
	single := ""
	if colors.Monochrome {
		single = "Single-color fallback: no sufficiently distinct second color was found.\n"
	}
	return fmt.Sprintf("Icon tint (first dominant color, Light style): %s\nSelection highlight (second color, softened): %s\n%sIcon tint requires macOS 26+. Changes use undocumented preferences; applying colors selects Tinted Light and automatically restarts Dock without changing system-wide appearance. Some apps need reopening or logout/login. Preview does not change any settings.", hex(colors.Tint), hex(colors.Highlight), single)
}

func wallpaperRoot(ctx api.Context) (string, error) {
	if cached, found := ctx.Cache().Get(rootCacheKey); found {
		if root, ok := cached.(string); ok && root != "" {
			return root, nil
		}
	}
	result, err := ctx.Desktop().Shell().Exec("/bin/sh", []string{"-c", `printf "%s" "$HOME"`}, api.ShellOptions{TimeoutMs: 5000})
	home := strings.TrimSpace(result.Stdout)
	if err != nil || result.ExitCode != 0 || !strings.HasPrefix(home, "/") {
		return "", errors.New("Cannot resolve your home directory for ~/.config/wallpapers.")
	}
	root := home + "/.config/wallpapers"
	ctx.Cache().Set(rootCacheKey, root, paletteTTL)
	return root, nil
}

func setPicture(ctx api.Context, path, name string, colors bool) error {
	if err := applyWallpaper(ctx, path); err != nil {
		return err
	}
	if !colors || !isMac(ctx) {
		showIndicator(ctx, api.IndicatorInput{Title: "Wallpaper updated", Subtitle: name, Status: api.IndicatorSuccess, DurationMs: 2000})
		return nil
	}
	showIndicator(ctx, api.IndicatorInput{ID: colorIndicator, Title: "Wallpaper updated · Extracting colors…", Status: api.IndicatorLoading})
	summary, err := matchColors(ctx, path)
	if err != nil {
		hideIndicator(ctx, colorIndicator)
		return fmt.Errorf("Wallpaper was set, but color matching failed: %w", err)
	}
	if err := restartDock(ctx); err != nil {
		hideIndicator(ctx, colorIndicator)
		return fmt.Errorf("Wallpaper and colors were updated, but Dock could not be restarted: %w", err)
	}
	showIndicator(ctx, api.IndicatorInput{ID: colorIndicator, Title: "Wallpaper and colors updated · Dock refreshed", Subtitle: summary + " · Other apps may still need reopening or logout/login.", Status: api.IndicatorSuccess, DurationMs: 8000})
	return nil
}

func matchColors(ctx api.Context, path string) (string, error) {
	colors, err := extractPalette(ctx, path)
	if err != nil {
		return "", err
	}
	return applyColors(ctx, colors)
}

func restartDock(ctx api.Context) error {
	result, err := ctx.Desktop().Shell().Exec("/usr/bin/killall", []string{"Dock"}, api.ShellOptions{TimeoutMs: 10000})
	if err != nil {
		return err
	}
	if result.ExitCode != 0 && !noMatchingProcs.MatchString(result.Stderr+result.Stdout) {
		return errors.New(orDefault(firstNonEmptyTrimmed(result.Stderr, result.Stdout), fmt.Sprintf("killall exited with code %d", result.ExitCode)))
	}
	return nil
}
