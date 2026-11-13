package main

import (
	"errors"
	"fmt"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func batchSavedItem(ctx api.Context, operation string, output savedOutput) api.Item {
	sizes := fmt.Sprintf("%s → %s", formatBytes(output.before), formatBytes(output.after))
	if percent := savedPercent(output.before, output.after); percent > 0 {
		sizes += fmt.Sprintf(" · saved %d%%", percent)
	}
	subtitle := sizes
	switch operation {
	case "half":
		subtitle = output.origDims + " → " + output.newDims + " · " + sizes
	case "convert":
		subtitle += " · " + output.targetExt
	}
	item := api.Item{
		ID:         "saved:" + output.output,
		Title:      basename(output.output),
		Subtitle:   subtitle,
		Icon:       "circle-check",
		Appearance: &api.Appearance{Foreground: api.ColorGreen},
		Primary:    api.Primary(api.RevealPath("Reveal in Finder", output.output)),
		Actions: []api.Action{
			api.OpenPath("Open", output.output),
			quickLook("Quick Look", output.output),
			api.CopyText("Copy Output Path", output.output, false),
		},
	}
	if operation == "half" {
		item.Image = &api.Image{Src: ctx.Desktop().Files().FileURL(output.output)}
	}
	return item
}

func batchSummary(saved []savedOutput, skipped, errs []failure) string {
	var before, after int64
	for _, output := range saved {
		before += output.before
		after += output.after
	}
	summary := fmt.Sprintf("%d saved", len(saved))
	if before > after {
		summary += " · " + formatBytes(before-after) + " saved"
	}
	if len(skipped) > 0 {
		summary += fmt.Sprintf(" · %d skipped", len(skipped))
	}
	if len(errs) > 0 {
		summary += fmt.Sprintf(" · %d failed", len(errs))
	}
	return summary
}

func speedMenu(ctx api.Context, supplied []string) (api.Result, error) {
	paths, err := selectedFor(ctx, "speed", supplied)
	if err != nil {
		return api.Result{}, err
	}
	if len(paths) == 0 {
		return errorResult("No Media Selected", "Select videos or GIFs in Finder, or copy files in Finder and use the clipboard."), nil
	}
	if err := ctx.Storage().Set(speedSelectionKey, paths); err != nil {
		return api.Result{}, err
	}
	items := make([]api.Item, 0, len(speedOptions))
	for _, speed := range speedOptions {
		items = append(items, api.Item{
			ID:      speed.id(),
			Title:   "Speed up by " + speed.label,
			Icon:    "zap",
			Primary: api.Primary(capturedRun(speed.id(), "Speed Up Media "+speed.label)),
		})
	}
	view := api.ListView("Select Speed", items...)
	view.Subtitle = fmt.Sprintf("%d selected · videos and GIFs", len(paths))
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

// processSpeed speeds up every selected video or GIF by one factor, and ends on the results list.
func processSpeed(ctx api.Context, speed speedOption, supplied []string) (api.Result, error) {
	paths, err := selectedFor(ctx, "speed", supplied)
	if err != nil {
		return api.Result{}, err
	}
	if len(paths) == 0 {
		return errorResult("No Media Selected", "Select videos or GIFs in Finder, or copy files in Finder first."), nil
	}
	shell := ctx.Desktop().Shell()
	if !succeeded(shell.Which("ffmpeg")) {
		return errorResult("FFmpeg Missing", "Speeding up media requires FFmpeg. Install it with Homebrew: brew install ffmpeg"), nil
	}
	if anyNotGIF(paths) && !succeeded(shell.Which("ffprobe")) {
		return errorResult("FFprobe Missing", "Audio detection requires ffprobe, included with FFmpeg."), nil
	}
	indicatorID := "media-actions-speed"
	title := "Speeding up by " + speed.label
	showIndicator(ctx, api.IndicatorInput{ID: indicatorID, Title: title, Status: api.IndicatorLoading, Total: len(paths)})
	defer hideIndicator(ctx, indicatorID)

	var items []api.Item
	successes := 0
	for index, source := range paths {
		temporary := fmt.Sprintf("%s.nvm-speed-%d-%d.%s", withoutExtension(source), ctx.Clock().Now().UnixNano(), index, extensionOf(source))
		output, err := speedFile(ctx, speed, source, temporary)
		if err != nil {
			items = append(items, failureItem(source, "error:", "Failed · "+failureReason(ctx, err, temporary), "circle-x", api.ColorRed))
		} else {
			successes++
			items = append(items, speedItem(speed, output))
		}
		updateIndicator(ctx, api.IndicatorInput{ID: indicatorID, Title: title, Subtitle: fmt.Sprintf("%d of %d", index+1, len(paths)), Status: api.IndicatorLoading, Value: index + 1, Total: len(paths)})
	}
	view := api.ListView("Speed-Up Results", items...)
	view.Subtitle = fmt.Sprintf("%d succeeded · %d failed", successes, len(paths)-successes)
	return api.Result{View: &view, Navigation: api.NavReplace}, nil
}

func speedFile(ctx api.Context, speed speedOption, source, temporary string) (string, error) {
	if err := encodeSpeed(ctx, speed, source, temporary); err != nil {
		return "", err
	}
	output, err := uniqueOutputPath(ctx, source, strings.ReplaceAll(speed.label, ".", "_"), extensionOf(source))
	if err != nil {
		return "", err
	}
	return output, moveNoClobber(ctx, temporary, output)
}

// encodeSpeed changes the pace of the video and its audio. GIFs keep their format; videos become x265.
func encodeSpeed(ctx api.Context, speed speedOption, source, temporary string) error {
	shell := ctx.Desktop().Shell()
	pts := fmt.Sprintf("setpts=%.4f*PTS", 1/speed.value)
	if extensionOf(source) == "gif" {
		result, err := shell.Exec("ffmpeg", []string{"-i", source, "-vf", pts, temporary, "-y"}, api.ShellOptions{})
		return processError(result, err, "Speed conversion failed")
	}
	probe, err := shell.Exec("ffprobe", []string{"-show_streams", "-select_streams", "a", "-loglevel", "error", source}, api.ShellOptions{})
	if err := processError(probe, err, "Could not detect audio streams"); err != nil {
		return err
	}
	filters := []string{"-vf", pts}
	if strings.TrimSpace(probe.Stdout) != "" {
		tempo := strconv.FormatFloat(speed.value, 'f', -1, 64)
		filters = []string{"-filter_complex", fmt.Sprintf("[0:v]%s[v];[0:a]atempo=%s[a]", pts, tempo), "-map", "[v]", "-map", "[a]"}
	}
	args := append([]string{"-i", source}, filters...)
	args = append(args, "-vcodec", "libx265", "-crf", "28", "-preset", "fast", "-acodec", "aac", "-b:a", "128k", "-movflags", "+faststart", temporary, "-y")
	result, err := shell.Exec("ffmpeg", args, api.ShellOptions{})
	return processError(result, err, "Speed conversion failed")
}

func speedItem(speed speedOption, output string) api.Item {
	subtitle := "Sped up by " + speed.label
	if extensionOf(output) != "gif" {
		subtitle += " · compressed with x265"
	}
	return api.Item{
		ID:         output,
		Title:      basename(output),
		Subtitle:   subtitle,
		Icon:       "circle-check",
		Appearance: &api.Appearance{Foreground: api.ColorGreen},
		Primary:    api.Primary(api.RevealPath("Reveal in Finder", output)),
		Actions: []api.Action{
			api.OpenPath("Open", output),
			quickLook("Quick Look", output),
			api.CopyText("Copy Output Path", output, false),
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

// selectedFor returns the supported paths of a supplied list, or of the Finder selection, or of the clipboard files.
func selectedFor(ctx api.Context, operation string, supplied []string) ([]string, error) {
	if supplied != nil {
		return supportedPaths(unique(supplied), operation), nil
	}
	finder, err := ctx.Desktop().Selection().Files()
	if err != nil {
		return nil, err
	}
	paths := unique(finder)
	if len(paths) == 0 {
		if paths, err = clipboardFilePaths(ctx); err != nil {
			return nil, err
		}
	}
	return supportedPaths(paths, operation), nil
}

func clipboardFilePaths(ctx api.Context) ([]string, error) {
	files, err := ctx.Desktop().Clipboard().ReadFiles()
	if err != nil {
		return nil, err
	}
	paths := make([]string, 0, len(files))
	for _, file := range files {
		paths = append(paths, file.Path)
	}
	return unique(paths), nil
}

func storedSelection(ctx api.Context, key string, captured bool) []string {
	if !captured {
		return nil
	}
	return storedPaths(ctx, key)
}

func storedPaths(ctx api.Context, key string) []string {
	var paths []string
	_, _ = ctx.Storage().Get(key, &paths)
	return paths
}

func selectionKey(operation string) string {
	return "selection:" + operation
}

func supportedPaths(paths []string, operation string) []string {
	var supportedList []string
	for _, path := range paths {
		if supported(path, operation) {
			supportedList = append(supportedList, path)
		}
	}
	return supportedList
}

func supported(path, operation string) bool {
	ext := extensionOf(path)
	switch operation {
	case "half":
		return contains(images, ext)
	case "speed":
		return contains(videos, ext) || ext == "gif"
	case "compress":
		return contains(compressImages, ext) || contains(videos, ext)
	}
	return contains(images, ext) || contains(convertVideos, ext)
}

func countSupported(paths []string, operation string) int {
	return len(supportedPaths(paths, operation))
}

func videosFor(operation string) []string {
	if operation == "convert" {
		return convertVideos
	}
	return videos
}

func pathExists(ctx api.Context, path string) (bool, error) {
	result, err := ctx.Desktop().Shell().Exec("/usr/bin/test", []string{"-e", path}, api.ShellOptions{})
	if err != nil {
		return false, err
	}
	if result.ExitCode != 0 && result.ExitCode != 1 {
		return false, errors.New(orDefault(strings.TrimSpace(result.Stderr), "Could not check the output path."))
	}
	return result.ExitCode == 0, nil
}
