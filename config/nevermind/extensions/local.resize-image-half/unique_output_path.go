package main

import (
	"fmt"
	"math"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func uniqueOutputPath(ctx api.Context, source, ext string) (string, error) {
	stem := withoutExtension(source)
	candidate := stem + "-half." + ext
	for suffix := 2; ; suffix++ {
		exists, err := pathExists(ctx, candidate)
		if err != nil {
			return "", err
		}
		if !exists {
			return candidate, nil
		}
		candidate = fmt.Sprintf("%s-half-%d.%s", stem, suffix, ext)
	}
}

func pathExists(ctx api.Context, path string) (bool, error) {
	result, err := ctx.Desktop().Shell().Exec("/usr/bin/test", []string{"-e", path}, api.ShellOptions{})
	if err != nil {
		return false, err
	}
	return result.ExitCode == 0, nil
}

func removeIfPresent(ctx api.Context, path string) error {
	_, err := ctx.Desktop().Shell().Exec("/bin/rm", []string{"-f", path}, api.ShellOptions{})
	return err
}

func imageDimensions(ctx api.Context, path string) (dimensions, bool) {
	if meta, err := ctx.Desktop().Files().Metadata(path); err == nil && meta.Width > 0 && meta.Height > 0 {
		return dimensions{width: int64(meta.Width), height: int64(meta.Height)}, true
	}
	if dims, ok := sipsDimensions(ctx, path); ok {
		return dims, true
	}
	return ffprobeDimensions(ctx, path)
}

func sipsDimensions(ctx api.Context, path string) (dimensions, bool) {
	result, err := ctx.Desktop().Shell().Exec("sips", []string{"-g", "pixelWidth", "-g", "pixelHeight", path}, api.ShellOptions{})
	if err != nil || result.ExitCode != 0 {
		return dimensions{}, false
	}
	widthMatch := pixelWidth.FindStringSubmatch(result.Stdout)
	heightMatch := pixelHeight.FindStringSubmatch(result.Stdout)
	if widthMatch == nil || heightMatch == nil {
		return dimensions{}, false
	}
	return parseDimensions(widthMatch[1], heightMatch[1])
}

func ffprobeDimensions(ctx api.Context, path string) (dimensions, bool) {
	if !toolAvailable(ctx, "ffprobe") {
		return dimensions{}, false
	}
	result, err := ctx.Desktop().Shell().Exec("ffprobe", []string{
		"-v", "error",
		"-select_streams", "v:0",
		"-show_entries", "stream=width,height",
		"-of", "csv=s=x:p=0",
		path,
	}, api.ShellOptions{})
	if err != nil || result.ExitCode != 0 {
		return dimensions{}, false
	}
	parts := strings.Split(strings.TrimSpace(result.Stdout), "x")
	if len(parts) != 2 {
		return dimensions{}, false
	}
	return parseDimensions(parts[0], parts[1])
}

func parseDimensions(width, height string) (dimensions, bool) {
	w, errW := strconv.ParseInt(width, 10, 64)
	h, errH := strconv.ParseInt(height, 10, 64)
	if errW != nil || errH != nil {
		return dimensions{}, false
	}
	return dimensions{width: w, height: h}, true
}

func toolAvailable(ctx api.Context, command string) bool {
	result, err := ctx.Desktop().Shell().Which(command)
	return err == nil && result.ExitCode == 0
}

func selectedImages(ctx api.Context) ([]string, error) {
	files, err := ctx.Desktop().Selection().Files()
	if err != nil {
		return nil, err
	}
	var images []string
	for _, path := range files {
		if contains(imageExtensions, extensionOf(path)) {
			images = append(images, path)
		}
	}
	return images, nil
}

func startProgress(ctx api.Context, total int) error {
	return ctx.Indicators().Show(api.IndicatorInput{
		ID:       progressIndicatorID,
		Title:    "Resizing images to 50%",
		Subtitle: fmt.Sprintf("Processing 1 of %d", total),
		Status:   api.IndicatorLoading,
		Value:    0,
		Total:    total,
	})
}

func updateProgress(ctx api.Context, title, subtitle string, value, total int) error {
	return ctx.Indicators().Update(api.IndicatorInput{
		ID:       progressIndicatorID,
		Title:    title,
		Subtitle: subtitle,
		Status:   api.IndicatorLoading,
		Value:    value,
		Total:    total,
	})
}

func hideProgress(ctx api.Context) {
	_ = ctx.Indicators().Hide(progressIndicatorID)
}

func resultsView(ctx api.Context, saved []resized, failures []failure) api.View {
	var totalBefore, totalAfter int64
	var items []api.Item
	for _, item := range saved {
		totalBefore += item.before
		totalAfter += item.after
		items = append(items, savedItem(ctx, item))
	}
	for _, item := range failures {
		items = append(items, failedItem(item))
	}
	netSaved := totalBefore - totalAfter
	view := api.ListView("Resize Results", items...)
	view.Subtitle = resultsSummary(len(saved), len(failures), netSaved)
	view.EmptyView = &api.EmptyState{Title: "No files resized", Subtitle: "No output images were created."}
	return view
}

func resultsSummary(savedCount, failedCount int, netSaved int64) string {
	if savedCount == 0 {
		summary := "Resizing failed"
		if failedCount > 0 {
			summary += " · " + plural(failedCount, "error")
		}
		return summary
	}
	summary := plural(savedCount, "image") + " resized to 50%"
	if netSaved > 0 {
		summary += " · " + formatBytes(netSaved) + " saved"
	}
	if failedCount > 0 {
		summary += fmt.Sprintf(" · %d failed", failedCount)
	}
	return summary
}

func savedItem(ctx api.Context, item resized) api.Item {
	sizeChange := formatBytes(item.before) + " → " + formatBytes(item.after)
	if item.before > item.after {
		percent := int64(jsRound((1 - float64(item.after)/float64(item.before)) * 100))
		if percent > 0 {
			sizeChange += fmt.Sprintf(" · saved %d%%", percent)
		}
	}
	return api.Item{
		ID:         "saved:" + item.output,
		Title:      basename(item.output),
		Subtitle:   fmt.Sprintf("%s → %s · %s", item.origDims, item.newDims, sizeChange),
		Image:      &api.Image{Src: ctx.Desktop().Files().FileURL(item.output)},
		Icon:       "circle-check",
		Appearance: &api.Appearance{Foreground: api.ColorGreen},
		Primary:    api.Primary(api.RevealPath("Reveal in Finder", item.output)),
		Actions: []api.Action{
			api.RevealPath("Reveal in Finder", item.output),
			api.OpenPath("Open", item.output),
			{Kind: api.ActionQuickLook, Title: "Quick Look", Path: item.output},
			api.CopyText("Copy Output Path", item.output, false),
		},
	}
}

func failedItem(item failure) api.Item {
	return api.Item{
		ID:         "error:" + item.source,
		Title:      basename(item.source),
		Subtitle:   "Failed · " + item.reason,
		Icon:       "circle-x",
		Appearance: &api.Appearance{Foreground: api.ColorRed},
		Primary:    api.Primary(api.RevealPath("Reveal in Finder", item.source)),
	}
}

func anyPNG(paths []string) bool {
	for _, path := range paths {
		if extensionOf(path) == "png" {
			return true
		}
	}
	return false
}

func halfOf(value int64) int64 {
	return int64(math.Max(1, jsRound(float64(value)*0.5)))
}

func jsRound(value float64) float64 {
	return math.Floor(value + 0.5)
}

func formatBytes(bytes int64) string {
	switch {
	case bytes < 1024:
		return fmt.Sprintf("%d B", bytes)
	case bytes < 1024*1024:
		return fmt.Sprintf("%.0f KB", jsRound(float64(bytes)/1024))
	}
	return fmt.Sprintf("%.1f MB", float64(bytes)/(1024*1024))
}

func plural(count int, noun string) string {
	if count == 1 {
		return fmt.Sprintf("%d %s", count, noun)
	}
	return fmt.Sprintf("%d %ss", count, noun)
}

func extensionOf(path string) string {
	parts := strings.Split(path, ".")
	return strings.ToLower(parts[len(parts)-1])
}

func basename(path string) string {
	parts := strings.Split(path, "/")
	if name := parts[len(parts)-1]; name != "" {
		return name
	}
	return "File"
}

func withoutExtension(path string) string {
	slash := strings.LastIndex(path, "/")
	dot := strings.LastIndex(path, ".")
	if dot > slash {
		return path[:dot]
	}
	return path
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
