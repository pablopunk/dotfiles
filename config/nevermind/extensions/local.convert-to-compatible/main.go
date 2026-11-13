package main

import (
	"fmt"
	"math"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	convertCommandID = "convert-media-compatible"
	batchCommandID   = "batch-convert"
	progressID       = "convert-compatible-progress"
)

var (
	imageExtensions = []string{"jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "webp", "bmp", "gif", "avif"}
	videoExtensions = []string{"mp4", "mov", "mkv", "avi", "webm", "m4v", "flv", "wmv", "ts"}
)

type savedFile struct {
	source, output string
	before, after  int64
	targetExt      string
}

type failure struct {
	source, reason string
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{
		{ID: convertCommandID, Title: "Convert to Compatible Format", Subtitle: "Convert selected images to JPG and videos to MP4 with compression", Icon: "arrow-right-left"},
		{ID: batchCommandID, Title: "Convert & Compress All", Icon: "play", Placement: []api.Placement{api.PlacementHidden}},
	}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case convertCommandID:
		return selectionResult(ctx)
	case batchCommandID:
		return convertAll(ctx)
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func selectionResult(ctx api.Context) (api.Result, error) {
	paths, err := selectedMedia(ctx)
	if err != nil {
		return api.Result{}, err
	}
	if len(paths) == 0 {
		return errorResult("No Media Selected", "Select one or more images or videos in Finder first."), nil
	}
	items := make([]api.Item, 0, len(paths))
	for _, path := range paths {
		items = append(items, selectionItem(path))
	}
	view := api.ListView("Convert to Compatible Format", items...)
	view.Subtitle = fmt.Sprintf("%d selected · images → JPG, videos → MP4", len(paths))
	view.Actions = []api.Action{batchAction()}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func selectionItem(path string) api.Item {
	ext := extensionOf(path)
	target, icon := "JPG", "image"
	if isVideo(path) {
		target, icon = "MP4", "video"
	}
	return api.Item{
		ID:       path,
		Title:    basename(path),
		Subtitle: fmt.Sprintf("%s → %s (compressed)", strings.ToUpper(ext), target),
		Icon:     icon,
		Primary:  api.Primary(batchAction()),
		Actions:  []api.Action{batchAction(), api.RevealPath("Reveal in Finder", path), quickLook("Quick Look", path)},
	}
}

func batchAction() api.Action {
	action := api.Run(batchCommandID, "Convert & Compress All", nil)
	action.Icon = "play"
	return action
}

// convertAll converts every selected file, reports progress through an indicator and ends on the results list.
func convertAll(ctx api.Context) (api.Result, error) {
	paths, err := selectedMedia(ctx)
	if err != nil {
		return api.Result{}, err
	}
	if len(paths) == 0 {
		return errorResult("Selection Changed", "The selected media files are no longer available in Finder."), nil
	}
	if anyVideo(paths) && !succeeded(ctx.Desktop().Shell().Which("ffmpeg")) {
		return errorResult("FFmpeg Missing", "Video conversion requires FFmpeg. Install it with Homebrew: brew install ffmpeg"), nil
	}
	total := len(paths)
	showProgress(ctx, api.IndicatorInput{ID: progressID, Title: "Converting media", Subtitle: fmt.Sprintf("Preparing 1 of %d", total), Status: api.IndicatorLoading, Total: total})
	defer func() { _ = ctx.Indicators().Hide(progressID) }()

	var saved []savedFile
	var skipped, errs []failure
	for index, source := range paths {
		updateProgress(ctx, api.IndicatorInput{ID: progressID, Title: "Converting " + basename(source), Subtitle: fmt.Sprintf("%d of %d (%s)", index+1, total, strings.ToUpper(targetExtension(source))), Status: api.IndicatorLoading, Value: index, Total: total})
		file, skip, err := convertFile(ctx, source, index)
		switch {
		case err != nil:
			errs = append(errs, failure{source: source, reason: err.Error()})
		case skip != "":
			skipped = append(skipped, failure{source: source, reason: skip})
		default:
			saved = append(saved, file)
		}
		updateProgress(ctx, api.IndicatorInput{ID: progressID, Title: fmt.Sprintf("Converted %d of %d", index+1, total), Subtitle: basename(source), Status: api.IndicatorLoading, Value: index + 1, Total: total})
	}
	return conversionResults(saved, skipped, errs), nil
}

// convertFile encodes one file next to its source. It returns the saved output, or the reason it was skipped.
func convertFile(ctx api.Context, source string, index int) (savedFile, string, error) {
	temporary := fmt.Sprintf("%s.nvm-convert-%d-%d.%s", withoutExtension(source), ctx.Clock().Now().UnixNano(), index, targetExtension(source))
	file, skip, err := encodeAndStore(ctx, source, temporary)
	if err != nil {
		removeFile(ctx, temporary)
	}
	return file, skip, err
}

func encodeAndStore(ctx api.Context, source, temporary string) (savedFile, string, error) {
	files := ctx.Desktop().Files()
	sourceMeta, err := files.Metadata(source)
	if err != nil {
		return savedFile{}, "", err
	}
	if err := encode(ctx, source, temporary); err != nil {
		return savedFile{}, "", err
	}
	candidateMeta, err := files.Metadata(temporary)
	if err != nil {
		return savedFile{}, "", err
	}
	target := targetExtension(source)
	if isSameFormat(extensionOf(source), target) && candidateMeta.Size >= sourceMeta.Size {
		removeFile(ctx, temporary)
		reason := fmt.Sprintf("Already optimal %s (%s; candidate was %s)", strings.ToUpper(target), formatBytes(sourceMeta.Size), formatBytes(candidateMeta.Size))
		return savedFile{}, reason, nil
	}
	output := uniqueOutputPath(ctx, source, target)
	if err := moveFile(ctx, temporary, output); err != nil {
		return savedFile{}, "", err
	}
	return savedFile{source: source, output: output, before: sourceMeta.Size, after: candidateMeta.Size, targetExt: strings.ToUpper(target)}, "", nil
}

func encode(ctx api.Context, source, temporary string) error {
	if isVideo(source) {
		return encodeVideo(ctx, source, temporary)
	}
	return encodeImage(ctx, source, temporary)
}

// encodeVideo writes H.264 with AAC and yuv420p: the most widely playable MP4 layout.
func encodeVideo(ctx api.Context, source, temporary string) error {
	result, err := ctx.Desktop().Shell().Exec("ffmpeg", []string{
		"-hide_banner", "-loglevel", "error", "-i", source,
		"-map_metadata", "-1",
		"-c:v", "libx264", "-crf", "23", "-preset", "fast",
		"-pix_fmt", "yuv420p",
		"-vf", "scale=1920:1920:force_original_aspect_ratio=decrease:force_divisible_by=2",
		"-c:a", "aac", "-b:a", "128k",
		"-movflags", "+faststart",
		temporary, "-y",
	}, api.ShellOptions{})
	return processError(result, err, "Conversion failed")
}

// encodeImage writes a JPEG capped at 2048 px with sips, and falls back to ffmpeg for formats sips cannot decode.
func encodeImage(ctx api.Context, source, temporary string) error {
	shell := ctx.Desktop().Shell()
	result, err := shell.Exec("sips", []string{"-s", "format", "jpeg", "-s", "formatOptions", "80", "-Z", "2048", source, "--out", temporary}, api.ShellOptions{})
	if !succeeded(result, err) && succeeded(shell.Which("ffmpeg")) {
		result, err = shell.Exec("ffmpeg", []string{
			"-hide_banner", "-loglevel", "error",
			"-i", source,
			"-vframes", "1",
			"-vf", "scale=2048:2048:force_original_aspect_ratio=decrease:force_divisible_by=2",
			"-q:v", "3",
			temporary, "-y",
		}, api.ShellOptions{})
	}
	return processError(result, err, "Conversion failed")
}

func conversionResults(saved []savedFile, skipped, errs []failure) api.Result {
	var items []api.Item
	var before, after int64
	for _, file := range saved {
		before += file.before
		after += file.after
		items = append(items, savedItem(file))
	}
	for _, skip := range skipped {
		items = append(items, failureItem(skip.source, "skipped:", "Skipped · "+skip.reason, "shield-check", api.ColorYellow))
	}
	for _, failed := range errs {
		items = append(items, failureItem(failed.source, "error:", "Failed · "+failed.reason, "circle-x", api.ColorRed))
	}
	view := api.ListView("Conversion Results", items...)
	view.Subtitle = conversionSummary(len(saved), len(skipped), len(errs), before-after)
	view.EmptyView = &api.EmptyState{Title: "No files converted", Subtitle: "No output files were created."}
	return api.Result{View: &view, Navigation: api.NavReplace}
}

func savedItem(file savedFile) api.Item {
	subtitle := fmt.Sprintf("%s → %s · converted to %s", formatBytes(file.before), formatBytes(file.after), file.targetExt)
	if percent := savedPercent(file.before, file.after); percent > 0 {
		subtitle = fmt.Sprintf("%s → %s · saved %d%% (%s)", formatBytes(file.before), formatBytes(file.after), percent, file.targetExt)
	}
	return api.Item{
		ID:         "saved:" + file.output,
		Title:      basename(file.output),
		Subtitle:   subtitle,
		Icon:       "circle-check",
		Appearance: &api.Appearance{Foreground: api.ColorGreen},
		Primary:    api.Primary(api.RevealPath("Reveal in Finder", file.output)),
		Actions: []api.Action{
			api.OpenPath("Open", file.output),
			quickLook("Quick Look", file.output),
			api.RevealPath("Reveal in Finder", file.output),
		},
	}
}

func failureItem(source, prefix, subtitle, icon string, color api.Color) api.Item {
	return api.Item{
		ID:         prefix + source,
		Title:      basename(source),
		Subtitle:   subtitle,
		Icon:       icon,
		Appearance: &api.Appearance{Foreground: color},
		Primary:    api.Primary(api.RevealPath("Reveal in Finder", source)),
	}
}

func conversionSummary(saved, skipped, failed int, netSaved int64) string {
	if saved == 0 {
		summary := "No conversions needed"
		if skipped > 0 {
			summary += fmt.Sprintf(" · %d skipped", skipped)
		}
		if failed > 0 {
			summary += fmt.Sprintf(" · %d failed", failed)
		}
		return summary
	}
	summary := fmt.Sprintf("%d file%s converted", saved, plural(saved))
	if netSaved > 0 {
		summary += " · " + formatBytes(netSaved) + " saved"
	}
	if skipped > 0 {
		summary += fmt.Sprintf(" · %d skipped", skipped)
	}
	return summary
}

func plural(count int) string {
	if count == 1 {
		return ""
	}
	return "s"
}

func savedPercent(before, after int64) int {
	if before <= after {
		return 0
	}
	return int(math.Round((1 - float64(after)/float64(before)) * 100))
}
