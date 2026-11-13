package main

import (
	"errors"
	"fmt"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func selectedMedia(ctx api.Context) ([]string, error) {
	paths, err := ctx.Desktop().Selection().Files()
	if err != nil {
		return nil, err
	}
	var media []string
	for _, path := range paths {
		if isMedia(path) {
			media = append(media, path)
		}
	}
	return media, nil
}

func uniqueOutputPath(ctx api.Context, source, extension string) string {
	stem := withoutExtension(source)
	candidate := fmt.Sprintf("%s-compatible.%s", stem, extension)
	for suffix := 2; pathExists(ctx, candidate); suffix++ {
		candidate = fmt.Sprintf("%s-compatible-%d.%s", stem, suffix, extension)
	}
	return candidate
}

func pathExists(ctx api.Context, path string) bool {
	result, err := ctx.Desktop().Shell().Exec("/usr/bin/test", []string{"-e", path}, api.ShellOptions{})
	return succeeded(result, err)
}

func moveFile(ctx api.Context, from, to string) error {
	result, err := ctx.Desktop().Shell().Exec("/bin/mv", []string{from, to}, api.ShellOptions{})
	return processError(result, err, "Could not save the converted file")
}

// removeFile is best effort: a temporary file that cannot be removed is left for the system to clean.
func removeFile(ctx api.Context, path string) {
	_, _ = ctx.Desktop().Shell().Exec("/bin/rm", []string{"-f", path}, api.ShellOptions{})
}

func showProgress(ctx api.Context, input api.IndicatorInput) {
	_ = ctx.Indicators().Show(input)
}

func updateProgress(ctx api.Context, input api.IndicatorInput) {
	_ = ctx.Indicators().Update(input)
}

// errorResult is the 1.x ui.error: a list with one contextual row that holds the title and the message.
func errorResult(title, message string) api.Result {
	view := api.ErrorView(title, message)
	return api.Result{View: &view, Navigation: api.NavPush}
}

func succeeded(result api.ShellResult, err error) bool {
	return err == nil && result.ExitCode == 0
}

func processError(result api.ShellResult, err error, fallback string) error {
	if err != nil {
		return err
	}
	if result.ExitCode != 0 {
		if detail := strings.TrimSpace(result.Stderr); detail != "" {
			return errors.New(detail)
		}
		return errors.New(fallback)
	}
	return nil
}

func quickLook(title, path string) api.Action {
	return api.Action{Kind: api.ActionQuickLook, Title: title, Path: path}
}

func isVideo(path string) bool {
	return contains(videoExtensions, extensionOf(path))
}

func isMedia(path string) bool {
	return contains(imageExtensions, extensionOf(path)) || isVideo(path)
}

func anyVideo(paths []string) bool {
	for _, path := range paths {
		if isVideo(path) {
			return true
		}
	}
	return false
}

// targetExtension is mp4 for videos and jpg for images.
func targetExtension(path string) string {
	if isVideo(path) {
		return "mp4"
	}
	return "jpg"
}

func isSameFormat(source, target string) bool {
	return source == target || ((source == "jpg" || source == "jpeg") && target == "jpg")
}

func contains(values []string, value string) bool {
	for _, candidate := range values {
		if candidate == value {
			return true
		}
	}
	return false
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
