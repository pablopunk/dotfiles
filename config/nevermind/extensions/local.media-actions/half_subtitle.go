package main

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

// halfSubtitle shows the size change of a resize, and the file size when it is known.
func halfSubtitle(ctx api.Context, path string) string {
	subtitle := "Scale to 50%"
	if dims, ok := dimensions(ctx, path); ok {
		subtitle = fmt.Sprintf("%d × %d → %d × %d", dims.width, dims.height, halfOf(dims.width), halfOf(dims.height))
	}
	if meta, err := ctx.Desktop().Files().Metadata(path); err == nil && meta.Size > 0 {
		subtitle += " · " + formatBytes(meta.Size)
	}
	return subtitle
}

func batchAction(operation string) api.Action {
	action := api.Run(batchID(operation), batchTitles[operation], nil)
	action.Icon = "play"
	return action
}

// processBatch converts or resizes every remembered file. A file that fails is recorded and the batch goes on.
func processBatch(ctx api.Context, operation string) (api.Result, error) {
	paths, err := selectedFor(ctx, operation, storedPaths(ctx, selectionKey(operation)))
	if err != nil {
		return api.Result{}, err
	}
	if len(paths) == 0 {
		return errorResult("No Media Selected", "Select supported files in Finder or copy files in Finder first."), nil
	}
	shell := ctx.Desktop().Shell()
	if operation != "half" && anyVideo(paths, operation) && !succeeded(shell.Which("ffmpeg")) {
		return errorResult("FFmpeg Missing", "Video processing requires FFmpeg. Install it with Homebrew: brew install ffmpeg"), nil
	}
	hasPngquant := operation != "convert" && anyExt(paths, "png") && succeeded(shell.Which("pngquant"))
	indicatorID := "media-actions-" + operation
	showIndicator(ctx, api.IndicatorInput{ID: indicatorID, Title: operationTitles[operation], Status: api.IndicatorLoading, Total: len(paths)})
	defer hideIndicator(ctx, indicatorID)

	var saved []savedOutput
	var skipped, errs []failure
	for index, source := range paths {
		updateIndicator(ctx, api.IndicatorInput{ID: indicatorID, Title: fmt.Sprintf("%s %s", batchVerb(operation), basename(source)), Subtitle: fmt.Sprintf("%d of %d", index+1, len(paths)), Status: api.IndicatorLoading, Value: index, Total: len(paths)})
		j := newJob(ctx, operation, source, index, hasPngquant)
		output, skip, err := runJob(ctx, j)
		switch {
		case err != nil:
			errs = append(errs, failure{source: source, reason: failureReason(ctx, err, j.temporary, j.quantized)})
		case skip != "":
			skipped = append(skipped, failure{source: source, reason: skip})
		default:
			saved = append(saved, output)
		}
		updateIndicator(ctx, api.IndicatorInput{ID: indicatorID, Title: fmt.Sprintf("%d of %d processed", index+1, len(paths)), Subtitle: basename(source), Status: api.IndicatorLoading, Value: index + 1, Total: len(paths)})
	}
	view := api.ListView(resultTitles[operation], batchResultItems(ctx, operation, saved, skipped, errs)...)
	view.Subtitle = batchSummary(saved, skipped, errs)
	view.EmptyView = &api.EmptyState{Title: "No output files created"}
	return api.Result{View: &view, Navigation: api.NavReplace}, nil
}

func batchVerb(operation string) string {
	switch operation {
	case "compress":
		return "Compressing"
	case "convert":
		return "Converting"
	}
	return "Resizing"
}

func newJob(ctx api.Context, operation, source string, index int, hasPngquant bool) job {
	ext := extensionOf(source)
	isVideo := operation != "half" && contains(videosFor(operation), ext)
	outputExt := outputExtension(operation, ext, isVideo)
	temporary := fmt.Sprintf("%s.nvm-%s-%d-%d.%s", withoutExtension(source), operation, ctx.Clock().Now().UnixNano(), index, outputExt)
	return job{
		source: source, temporary: temporary, quantized: temporary + ".opt.png",
		operation: operation, ext: ext, outputExt: outputExt,
		isVideo: isVideo, hasPngquant: hasPngquant,
	}
}

func outputExtension(operation, ext string, isVideo bool) string {
	switch operation {
	case "convert":
		if isVideo {
			return "mp4"
		}
		return "jpg"
	case "half":
		if ext == "jpeg" {
			return "jpg"
		}
		return ext
	}
	if isVideo || ext == "png" {
		return ext
	}
	return "jpg"
}

// runJob encodes one file and keeps the output only when it is smaller, for compress and same-format convert.
// It returns the saved output, or the reason the file was skipped.
func runJob(ctx api.Context, j job) (savedOutput, string, error) {
	files := ctx.Desktop().Files()
	before, err := files.Metadata(j.source)
	if err != nil {
		return savedOutput{}, "", err
	}
	origDims, err := encodeJob(ctx, j)
	if err != nil {
		return savedOutput{}, "", err
	}
	after, err := files.Metadata(j.temporary)
	if err != nil {
		return savedOutput{}, "", err
	}
	mustBeSmaller := j.operation == "compress" || (j.operation == "convert" && isSameFormat(j.ext, j.outputExt))
	if mustBeSmaller && after.Size >= before.Size {
		if err := removeFile(ctx, j.temporary); err != nil {
			return savedOutput{}, "", err
		}
		return savedOutput{}, fmt.Sprintf("Already efficient (%s; candidate was %s)", formatBytes(before.Size), formatBytes(after.Size)), nil
	}
	output, err := uniqueOutputPath(ctx, j.source, outputSuffix(j.operation), j.outputExt)
	if err != nil {
		return savedOutput{}, "", err
	}
	if err := moveNoClobber(ctx, j.temporary, output); err != nil {
		return savedOutput{}, "", err
	}
	saved := savedOutput{source: j.source, output: output, origDims: origDims, before: before.Size, after: after.Size, targetExt: strings.ToUpper(j.outputExt), newDims: "50%"}
	if j.operation == "half" {
		if dims, ok := dimensions(ctx, output); ok {
			saved.newDims = fmt.Sprintf("%d × %d", dims.width, dims.height)
		}
	}
	return saved, "", nil
}

func outputSuffix(operation string) string {
	switch operation {
	case "compress":
		return "compressed"
	case "convert":
		return "compatible"
	}
	return "half"
}

func encodeJob(ctx api.Context, j job) (string, error) {
	switch {
	case j.operation == "half":
		return resizeHalf(ctx, j)
	case j.isVideo:
		return "", encodeVideo(ctx, j)
	case j.operation == "compress" && j.ext == "png" && j.hasPngquant:
		return "", pngquantCompress(ctx, j)
	}
	return "", encodeImage(ctx, j)
}

// resizeHalf halves the width with sips, falls back to ffmpeg, and optimizes PNG output with pngquant when present.
func resizeHalf(ctx api.Context, j job) (string, error) {
	shell := ctx.Desktop().Shell()
	origDims := "Original"
	dims, hasDims := dimensions(ctx, j.source)
	targetWidth := 0
	if hasDims {
		origDims = fmt.Sprintf("%d × %d", dims.width, dims.height)
		targetWidth = halfOf(dims.width)
	}
	result := api.ShellResult{ExitCode: 1}
	var err error
	if targetWidth > 0 {
		args := []string{"--resampleWidth", strconv.Itoa(targetWidth)}
		if j.ext == "jpg" || j.ext == "jpeg" {
			args = append(args, "-s", "format", "jpeg", "-s", "formatOptions", "80")
		}
		result, err = shell.Exec("sips", append(args, j.source, "--out", j.temporary), api.ShellOptions{})
	}
	if !succeeded(result, err) && succeeded(shell.Which("ffmpeg")) {
		result, err = shell.Exec("ffmpeg", []string{"-hide_banner", "-loglevel", "error", "-i", j.source, "-vframes", "1", "-vf", halfFilter(targetWidth), j.temporary, "-y"}, api.ShellOptions{})
	}
	if err := processError(result, err, "Resizing failed"); err != nil {
		return origDims, err
	}
	if j.outputExt == "png" && j.hasPngquant {
		return origDims, quantizeInPlace(ctx, j)
	}
	return origDims, nil
}

func halfFilter(targetWidth int) string {
	if targetWidth > 0 {
		return fmt.Sprintf("scale=%d:-2", targetWidth)
	}
	return "scale=iw*0.5:ih*0.5"
}

func quantizeInPlace(ctx api.Context, j job) error {
	shell := ctx.Desktop().Shell()
	quant, err := shell.Exec("pngquant", []string{"--quality", "65-85", "--speed", "1", "--strip", "--force", "--output", j.quantized, "--", j.temporary}, api.ShellOptions{})
	if !succeeded(quant, err) {
		return removeFile(ctx, j.quantized)
	}
	replace, err := shell.Exec("/bin/mv", []string{j.quantized, j.temporary}, api.ShellOptions{})
	return processError(replace, err, "Could not save PNG optimization")
}

// encodeVideo compresses with x265 for compress, and writes H.264 with yuv420p for convert.
func encodeVideo(ctx api.Context, j job) error {
	codec := []string{"-vcodec", "libx265", "-crf", "28", "-preset", "fast"}
	if j.operation == "convert" {
		codec = []string{"-c:v", "libx264", "-crf", "23", "-preset", "fast", "-pix_fmt", "yuv420p"}
	}
	args := append([]string{"-hide_banner", "-loglevel", "error", "-i", j.source, "-map_metadata", "-1"}, codec...)
	args = append(args, "-vf", "scale=1920:1920:force_original_aspect_ratio=decrease:force_divisible_by=2", "-c:a", "aac", "-b:a", "128k", "-movflags", "+faststart", j.temporary, "-y")
	result, err := ctx.Desktop().Shell().Exec("ffmpeg", args, api.ShellOptions{})
	return processError(result, err, "The encoder failed")
}

func pngquantCompress(ctx api.Context, j job) error {
	result, err := ctx.Desktop().Shell().Exec("pngquant", []string{"--quality", "55-85", "--speed", "1", "--strip", "--force", "--output", j.temporary, "--", j.source}, api.ShellOptions{})
	return processError(result, err, "The encoder failed")
}

// encodeImage writes a JPEG (or PNG for compress of PNG) capped at 2048 px. Convert falls back to ffmpeg when sips fails.
func encodeImage(ctx api.Context, j job) error {
	shell := ctx.Desktop().Shell()
	format := "jpeg"
	if j.operation == "compress" && j.ext == "png" {
		format = "png"
	}
	args := []string{"-s", "format", format}
	if format == "jpeg" {
		quality := "75"
		if j.operation == "convert" {
			quality = "80"
		}
		args = append(args, "-s", "formatOptions", quality)
	}
	result, err := shell.Exec("sips", append(args, "-Z", "2048", j.source, "--out", j.temporary), api.ShellOptions{})
	if j.operation == "convert" && !succeeded(result, err) && succeeded(shell.Which("ffmpeg")) {
		result, err = shell.Exec("ffmpeg", []string{"-hide_banner", "-loglevel", "error", "-i", j.source, "-vframes", "1", "-vf", "scale=2048:2048:force_original_aspect_ratio=decrease:force_divisible_by=2", "-q:v", "3", j.temporary, "-y"}, api.ShellOptions{})
	}
	return processError(result, err, "The encoder failed")
}

func batchResultItems(ctx api.Context, operation string, saved []savedOutput, skipped, errs []failure) []api.Item {
	var items []api.Item
	for _, output := range saved {
		items = append(items, batchSavedItem(ctx, operation, output))
	}
	for _, skip := range skipped {
		items = append(items, failureItem(skip.source, "skipped:", "Skipped · "+skip.reason, "shield-check", api.ColorYellow))
	}
	for _, failed := range errs {
		items = append(items, failureItem(failed.source, "error:", "Failed · "+failed.reason, "circle-x", api.ColorRed))
	}
	return items
}
