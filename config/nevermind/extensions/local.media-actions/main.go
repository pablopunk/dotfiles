package main

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	hubCommandID      = "media-actions"
	hubSelectionKey   = "hubSelection"
	speedSelectionKey = "selection:speed"
	capturedArg       = "useCapturedSelection"
)

var (
	compressImages   = []string{"jpg", "jpeg", "png", "heic", "tiff", "tif", "webp"}
	images           = []string{"jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "webp", "bmp", "gif", "avif"}
	videos           = []string{"mp4", "mov", "mkv", "avi", "webm", "m4v"}
	convertVideos    = []string{"mp4", "mov", "mkv", "avi", "webm", "m4v", "flv", "wmv", "ts"}
	pixelWidthRegex  = regexp.MustCompile(`pixelWidth:\s*(\d+)`)
	pixelHeightRegex = regexp.MustCompile(`pixelHeight:\s*(\d+)`)
)

var operations = []string{"compress", "convert", "half"}

var operationTitles = map[string]string{
	"compress": "Compress Media",
	"convert":  "Convert to Compatible Format",
	"half":     "Resize to Half (50%)",
}

var operationIcons = map[string]string{
	"compress": "file-down",
	"convert":  "arrow-right-left",
	"half":     "shrink",
}

var batchIDs = map[string]string{
	"compress": "batch-compress",
	"convert":  "batch-convert",
	"half":     "batch-resize-half",
}

var batchTitles = map[string]string{
	"compress": "Compress All",
	"convert":  "Convert & Compress All",
	"half":     "Resize & Compress (50%)",
}

var resultTitles = map[string]string{
	"compress": "Compression Results",
	"convert":  "Conversion Results",
	"half":     "Resize Results",
}

var previewHints = map[string]string{
	"compress": "larger results are discarded",
	"convert":  "images → JPG, videos → MP4",
	"half":     "Enter to resize & compress",
}

type speedOption struct {
	label string
	value float64
}

var speedOptions = []speedOption{{"1.3x", 1.3}, {"1.5x", 1.5}, {"2.0x", 2}}

func (s speedOption) id() string {
	return "speed-" + strconv.FormatFloat(s.value, 'f', -1, 64)
}

type pixelSize struct {
	width, height int
}

type job struct {
	source, temporary, quantized string
	operation, ext, outputExt    string
	isVideo, hasPngquant         bool
}

type savedOutput struct {
	source, output, origDims, newDims string
	before, after                     int64
	targetExt                         string
}

type failure struct {
	source, reason string
}

func Commands(ctx api.Context) ([]api.Command, error) {
	commands := []api.Command{{
		ID:       hubCommandID,
		Title:    "Media Actions",
		Subtitle: "All media actions in one list",
		Icon:     "clapperboard",
		Aliases:  []string{"media tools", "media utilities"},
	}}
	for _, operation := range operations {
		commands = append(commands,
			hiddenCommand("open-"+operation, operationTitles[operation], operationIcons[operation]),
			hiddenCommand(batchID(operation), batchTitles[operation], "play"),
		)
	}
	commands = append(commands, hiddenCommand("open-speed", "Speed Up Media", "fast-forward"))
	for _, speed := range speedOptions {
		commands = append(commands, api.Command{
			ID:        speed.id(),
			Title:     "Speed Up Media " + speed.label,
			Subtitle:  "Selected Finder or clipboard videos and GIFs",
			Icon:      "fast-forward",
			Placement: []api.Placement{api.PlacementHidden},
		})
	}
	return commands, nil
}

func hiddenCommand(id, title, icon string) api.Command {
	return api.Command{ID: id, Title: title, Icon: icon, Placement: []api.Placement{api.PlacementHidden}}
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	captured := in.Ref.Args[capturedArg] == "true"
	switch in.Ref.ID {
	case hubCommandID:
		return hub(ctx)
	case "open-speed":
		return speedMenu(ctx, storedSelection(ctx, hubSelectionKey, captured))
	}
	for _, operation := range operations {
		if in.Ref.ID == "open-"+operation {
			return previewOperation(ctx, operation, storedSelection(ctx, hubSelectionKey, captured))
		}
		if in.Ref.ID == batchID(operation) {
			return processBatch(ctx, operation)
		}
	}
	for _, speed := range speedOptions {
		if in.Ref.ID == speed.id() {
			return processSpeed(ctx, speed, storedSelection(ctx, speedSelectionKey, captured))
		}
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func batchID(operation string) string {
	return batchIDs[operation]
}

// hub lists the media actions for the Finder selection, or for the files on the clipboard when nothing is selected in Finder.
func hub(ctx api.Context) (api.Result, error) {
	finder, err := ctx.Desktop().Selection().Files()
	if err != nil {
		return api.Result{}, err
	}
	finderPaths := unique(finder)
	var clipboardPaths []string
	if len(finderPaths) == 0 {
		if clipboardPaths, err = clipboardFilePaths(ctx); err != nil {
			return api.Result{}, err
		}
	}
	paths := finderPaths
	if len(paths) == 0 {
		paths = clipboardPaths
	}
	if err := ctx.Storage().Set(hubSelectionKey, nilIfEmpty(paths)); err != nil {
		return api.Result{}, err
	}
	view := api.ListView("Media Actions", hubRows(paths)...)
	view.Subtitle = hubSourceLabel(finderPaths, clipboardPaths) + " · originals are preserved"
	view.Placeholder = "Filter media actions…"
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func hubRows(paths []string) []api.Item {
	return []api.Item{
		hubRow("compress", operationTitles["compress"], "Keep output only when smaller · images and videos", "file-down", "compress", paths),
		hubRow("convert", operationTitles["convert"], "Images → JPG · videos → H.264 MP4 · with compression", "arrow-right-left", "convert", paths),
		hubRow("half", "Resize Images to Half (50%)", "Half-size dimensions · compress JPG and optimize PNG", "shrink", "half", paths),
		hubRow("speed", "Speed Up Media", "1.3x, 1.5x, or 2.0x · videos and GIFs", "fast-forward", "speed", paths),
	}
}

func hubRow(id, title, subtitle, icon, operation string, paths []string) api.Item {
	return api.Item{
		ID:          id,
		Title:       title,
		Subtitle:    subtitle,
		Icon:        icon,
		Accessories: []api.Accessory{{Text: fmt.Sprintf("%d supported", countSupported(paths, operation))}},
		Primary:     api.Primary(openAction(operation)),
	}
}

func openAction(operation string) api.Action {
	if operation == "speed" {
		return capturedRun("open-speed", "Speed Up Media")
	}
	return capturedRun("open-"+operation, operationTitles[operation])
}

func capturedRun(id, title string) api.Action {
	return api.Run(id, title, map[string]string{capturedArg: "true"})
}

func hubSourceLabel(finder, clipboard []string) string {
	switch {
	case len(finder) > 0:
		return fmt.Sprintf("%d Finder file%s selected · Finder selection takes priority", len(finder), plural(len(finder)))
	case len(clipboard) > 0:
		return fmt.Sprintf("%d clipboard file%s available", len(clipboard), plural(len(clipboard)))
	}
	return "Select files in Finder or copy files in Finder first"
}

func previewOperation(ctx api.Context, operation string, supplied []string) (api.Result, error) {
	paths, err := selectedFor(ctx, operation, supplied)
	if err != nil {
		return api.Result{}, err
	}
	if len(paths) == 0 {
		title := "No Media Selected"
		if operation == "half" {
			title = "No Images Selected"
		}
		return errorResult(title, "Select supported files in Finder, or copy files in Finder and use the clipboard."), nil
	}
	if err := ctx.Storage().Set(selectionKey(operation), paths); err != nil {
		return api.Result{}, err
	}
	items := make([]api.Item, 0, len(paths))
	for _, path := range paths {
		items = append(items, previewItem(ctx, operation, path))
	}
	view := api.ListView(operationTitles[operation], items...)
	view.Subtitle = fmt.Sprintf("%d selected · %s", len(paths), previewHints[operation])
	view.Actions = []api.Action{batchAction(operation)}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func previewItem(ctx api.Context, operation, path string) api.Item {
	ext := extensionOf(path)
	isVideo := contains(videosFor(operation), ext)
	icon := "image"
	subtitle := "Image"
	if isVideo {
		icon, subtitle = "video", "Video"
	}
	if operation == "convert" {
		subtitle = fmt.Sprintf("%s → %s (compressed)", strings.ToUpper(ext), mediaTarget(isVideo))
	}
	item := api.Item{
		ID:      path,
		Title:   basename(path),
		Icon:    icon,
		Primary: api.Primary(batchAction(operation)),
		Actions: []api.Action{quickLook("Quick Look", path), api.RevealPath("Reveal in Finder", path)},
	}
	if operation == "half" {
		subtitle = halfSubtitle(ctx, path)
		item.Image = &api.Image{Src: ctx.Desktop().Files().FileURL(path)}
	}
	item.Subtitle = subtitle
	return item
}
