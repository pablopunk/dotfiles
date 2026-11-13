package main

import (
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func uniqueOutputPath(ctx api.Context, source, suffix, extension string) (string, error) {
	stem := withoutExtension(source)
	candidate := fmt.Sprintf("%s-%s.%s", stem, suffix, extension)
	for n := 2; ; n++ {
		exists, err := pathExists(ctx, candidate)
		if err != nil {
			return "", err
		}
		if !exists {
			return candidate, nil
		}
		candidate = fmt.Sprintf("%s-%s-%d.%s", stem, suffix, n, extension)
	}
}

// moveNoClobber moves a file without overwriting an existing target.
func moveNoClobber(ctx api.Context, source, target string) error {
	result, err := ctx.Desktop().Shell().Exec("/bin/mv", []string{"-n", source, target}, api.ShellOptions{})
	if err != nil {
		return err
	}
	stillThere, err := pathExists(ctx, source)
	if err != nil {
		return err
	}
	if result.ExitCode != 0 || stillThere {
		return errors.New(orDefault(strings.TrimSpace(result.Stderr), "Could not save output without overwriting an existing file."))
	}
	return nil
}

func removeFile(ctx api.Context, path string) error {
	result, err := ctx.Desktop().Shell().Exec("/bin/rm", []string{"-f", path}, api.ShellOptions{})
	return processError(result, err, "Could not remove a temporary media file.")
}

// failureReason is the error text plus any cleanup problem, so a failed file still says what was left behind.
func failureReason(ctx api.Context, err error, temporaries ...string) string {
	reason := err.Error()
	for _, path := range temporaries {
		if cleanup := removeFile(ctx, path); cleanup != nil {
			reason += " · Cleanup: " + cleanup.Error()
		}
	}
	return reason
}

// dimensions reads the pixel size from the file index, then sips, then ffprobe. It reports false when none knows.
func dimensions(ctx api.Context, path string) (pixelSize, bool) {
	if meta, err := ctx.Desktop().Files().Metadata(path); err == nil && meta.Width > 0 && meta.Height > 0 {
		return pixelSize{width: meta.Width, height: meta.Height}, true
	}
	shell := ctx.Desktop().Shell()
	if sips, err := shell.Exec("sips", []string{"-g", "pixelWidth", "-g", "pixelHeight", path}, api.ShellOptions{}); succeeded(sips, err) {
		width := pixelWidthRegex.FindStringSubmatch(sips.Stdout)
		height := pixelHeightRegex.FindStringSubmatch(sips.Stdout)
		if width != nil && height != nil {
			return pixelSize{width: atoi(width[1]), height: atoi(height[1])}, true
		}
	}
	if !succeeded(shell.Which("ffprobe")) {
		return pixelSize{}, false
	}
	probe, err := shell.Exec("ffprobe", []string{"-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "csv=s=x:p=0", path}, api.ShellOptions{})
	if !succeeded(probe, err) {
		return pixelSize{}, false
	}
	parts := strings.Split(strings.TrimSpace(probe.Stdout), "x")
	if len(parts) != 2 {
		return pixelSize{}, false
	}
	size := pixelSize{width: atoi(parts[0]), height: atoi(parts[1])}
	return size, size.width > 0 && size.height > 0
}

// halfOf is the half-size dimension, never below one pixel.
func halfOf(value int) int {
	half := int(math.Round(float64(value) * 0.5))
	if half < 1 {
		return 1
	}
	return half
}

func savedPercent(before, after int64) int {
	if before <= after {
		return 0
	}
	return int(math.Round((1 - float64(after)/float64(before)) * 100))
}

func showIndicator(ctx api.Context, input api.IndicatorInput) {
	_ = ctx.Indicators().Show(input)
}

func updateIndicator(ctx api.Context, input api.IndicatorInput) {
	_ = ctx.Indicators().Update(input)
}

func hideIndicator(ctx api.Context, id string) {
	_ = ctx.Indicators().Hide(id)
}

func processError(result api.ShellResult, err error, fallback string) error {
	if err != nil {
		return err
	}
	if result.ExitCode != 0 {
		return errors.New(orDefault(strings.TrimSpace(result.Stderr), fallback))
	}
	return nil
}

func succeeded(result api.ShellResult, err error) bool {
	return err == nil && result.ExitCode == 0
}

// errorResult is the 1.x ui.error: a list with one contextual row that holds the title and the message.
func errorResult(title, message string) api.Result {
	view := api.ErrorView(title, message)
	return api.Result{View: &view, Navigation: api.NavPush}
}

func quickLook(title, path string) api.Action {
	return api.Action{Kind: api.ActionQuickLook, Title: title, Path: path}
}

func mediaTarget(isVideo bool) string {
	if isVideo {
		return "MP4"
	}
	return "JPG"
}

func anyVideo(paths []string, operation string) bool {
	for _, path := range paths {
		if contains(videosFor(operation), extensionOf(path)) {
			return true
		}
	}
	return false
}

func anyExt(paths []string, ext string) bool {
	for _, path := range paths {
		if extensionOf(path) == ext {
			return true
		}
	}
	return false
}

func anyNotGIF(paths []string) bool {
	for _, path := range paths {
		if extensionOf(path) != "gif" {
			return true
		}
	}
	return false
}

func isSameFormat(source, target string) bool {
	return source == target || ((source == "jpeg" || source == "jpg") && target == "jpg")
}

func unique(values []string) []string {
	seen := map[string]bool{}
	var out []string
	for _, value := range values {
		if value != "" && !seen[value] {
			seen[value] = true
			out = append(out, value)
		}
	}
	return out
}

func nilIfEmpty(paths []string) []string {
	if len(paths) == 0 {
		return nil
	}
	return paths
}

func contains(values []string, value string) bool {
	for _, candidate := range values {
		if candidate == value {
			return true
		}
	}
	return false
}

func orDefault(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}

func plural(count int) string {
	if count == 1 {
		return ""
	}
	return "s"
}

func atoi(text string) int {
	value, _ := strconv.Atoi(text)
	return value
}

func extensionOf(path string) string {
	return strings.ToLower(path[strings.LastIndex(path, ".")+1:])
}

func basename(path string) string {
	name := path[strings.LastIndex(path, "/")+1:]
	if name == "" {
		return "File"
	}
	return name
}

func withoutExtension(path string) string {
	dot := strings.LastIndex(path, ".")
	if dot > strings.LastIndex(path, "/") {
		return path[:dot]
	}
	return path
}

func formatBytes(bytes int64) string {
	switch {
	case bytes < 1024:
		return fmt.Sprintf("%d B", bytes)
	case bytes < 1024*1024:
		return fmt.Sprintf("%.0f KB", float64(bytes)/1024)
	}
	return fmt.Sprintf("%.1f MB", float64(bytes)/(1024*1024))
}
