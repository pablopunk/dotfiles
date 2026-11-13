package main

import (
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	commandResizeHalf   = "resize-image-to-half"
	actionBatchResize   = "batch-resize-half"
	progressIndicatorID = "resize-half-progress"
)

var (
	imageExtensions = []string{"jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "webp", "bmp", "avif", "gif"}
	pixelWidth      = regexp.MustCompile(`pixelWidth:\s*(\d+)`)
	pixelHeight     = regexp.MustCompile(`pixelHeight:\s*(\d+)`)
)

type dimensions struct {
	width  int64
	height int64
}

type resized struct {
	source   string
	output   string
	before   int64
	after    int64
	origDims string
	newDims  string
}

type failure struct {
	source string
	reason string
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{
		{
			ID:       commandResizeHalf,
			Title:    "Resize Image to Half (50%)",
			Subtitle: "Scale selected Finder images down to 50% and compress",
			Icon:     "shrink",
			Aliases:  []string{"resize half", "50%", "half size", "compress half", "scale 50"},
		},
		{
			ID:        actionBatchResize,
			Title:     "Resize & Compress (50%)",
			Icon:      "play",
			Placement: []api.Placement{api.PlacementHidden},
		},
	}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case commandResizeHalf:
		return selectionView(ctx)
	case actionBatchResize:
		return batchResize(ctx)
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func selectionView(ctx api.Context) (api.Result, error) {
	targets, err := selectedImages(ctx)
	if err != nil {
		return api.Result{}, err
	}
	if len(targets) == 0 {
		return errorResult("No Images Selected", "Select one or more image files in Finder first."), nil
	}
	items := make([]api.Item, 0, len(targets))
	for _, path := range targets {
		items = append(items, selectionItem(ctx, path))
	}
	view := api.ListView("Resize to Half (50%)", items...)
	view.Subtitle = fmt.Sprintf("%s selected · Enter to resize & compress", plural(len(targets), "image"))
	view.Actions = []api.Action{api.Run(actionBatchResize, "Resize & Compress (50%)", nil)}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func selectionItem(ctx api.Context, path string) api.Item {
	subtitle := "Scale to 50%"
	if dims, ok := imageDimensions(ctx, path); ok {
		subtitle = fmt.Sprintf("%d × %d → %d × %d", dims.width, dims.height, halfOf(dims.width), halfOf(dims.height))
	}
	if meta, err := ctx.Desktop().Files().Metadata(path); err == nil && meta.Size > 0 {
		subtitle += " · " + formatBytes(meta.Size)
	}
	batch := api.Run(actionBatchResize, "Resize & Compress (50%)", nil)
	return api.Item{
		ID:       path,
		Title:    basename(path),
		Subtitle: subtitle,
		Image:    &api.Image{Src: ctx.Desktop().Files().FileURL(path)},
		Icon:     "image",
		Primary:  api.Primary(batch),
		Actions: []api.Action{
			batch,
			{Kind: api.ActionQuickLook, Title: "Quick Look", Path: path},
			api.RevealPath("Reveal in Finder", path),
		},
	}
}

func batchResize(ctx api.Context) (api.Result, error) {
	targets, err := selectedImages(ctx)
	if err != nil {
		return api.Result{}, err
	}
	if len(targets) == 0 {
		return errorResult("Selection Changed", "The selected image files are no longer available in Finder."), nil
	}
	hasPngquant := anyPNG(targets) && toolAvailable(ctx, "pngquant")
	if err := startProgress(ctx, len(targets)); err != nil {
		return api.Result{}, err
	}
	defer hideProgress(ctx)

	var saved []resized
	var failures []failure
	for index, source := range targets {
		if err := updateProgress(ctx, fmt.Sprintf("Resizing %s", basename(source)), fmt.Sprintf("%d of %d", index+1, len(targets)), index, len(targets)); err != nil {
			return api.Result{}, err
		}
		item, err := resizeWithCleanup(ctx, source, index, hasPngquant)
		if err != nil {
			failures = append(failures, failure{source: source, reason: err.Error()})
		} else {
			saved = append(saved, item)
		}
		if err := updateProgress(ctx, fmt.Sprintf("Resized %d of %d", index+1, len(targets)), basename(source), index+1, len(targets)); err != nil {
			return api.Result{}, err
		}
	}
	view := resultsView(ctx, saved, failures)
	return api.Result{View: &view, Navigation: api.NavReplace}, nil
}

func resizeWithCleanup(ctx api.Context, source string, index int, hasPngquant bool) (resized, error) {
	sourceExt := extensionOf(source)
	outputExt := sourceExt
	if sourceExt == "jpeg" {
		outputExt = "jpg"
	}
	temporary := fmt.Sprintf("%s.nvm-half-%d-%d.%s", withoutExtension(source), ctx.Clock().Now().UnixMilli(), index, outputExt)
	item, err := resizeToTemporary(ctx, source, temporary, sourceExt, outputExt, hasPngquant)
	if err != nil {
		_ = removeIfPresent(ctx, temporary)
		return resized{}, err
	}
	return item, nil
}

func resizeToTemporary(ctx api.Context, source, temporary, sourceExt, outputExt string, hasPngquant bool) (resized, error) {
	sourceMeta, err := ctx.Desktop().Files().Metadata(source)
	if err != nil {
		return resized{}, errors.New("Could not read original file size")
	}
	dims, hasDims := imageDimensions(ctx, source)
	origDims := "Original"
	var targetWidth int64
	if hasDims {
		targetWidth = halfOf(dims.width)
		origDims = fmt.Sprintf("%d × %d", dims.width, dims.height)
	}
	if err := writeHalfSized(ctx, source, temporary, sourceExt, targetWidth); err != nil {
		return resized{}, err
	}
	if outputExt == "png" && hasPngquant {
		if err := quantizePNG(ctx, temporary); err != nil {
			return resized{}, err
		}
	}
	candidateMeta, err := ctx.Desktop().Files().Metadata(temporary)
	if err != nil {
		return resized{}, errors.New("Could not read resized file size")
	}
	outputPath, err := uniqueOutputPath(ctx, source, outputExt)
	if err != nil {
		return resized{}, err
	}
	if err := moveFile(ctx, temporary, outputPath, "Could not save the resized file"); err != nil {
		return resized{}, err
	}
	newDims := "50%"
	if after, ok := imageDimensions(ctx, outputPath); ok {
		newDims = fmt.Sprintf("%d × %d", after.width, after.height)
	}
	return resized{
		source:   source,
		output:   outputPath,
		before:   sourceMeta.Size,
		after:    candidateMeta.Size,
		origDims: origDims,
		newDims:  newDims,
	}, nil
}

// writeHalfSized scales with sips and falls back to ffmpeg when sips fails or the width is unknown.
func writeHalfSized(ctx api.Context, source, temporary, sourceExt string, targetWidth int64) error {
	var result *api.ShellResult
	if targetWidth > 0 {
		args := []string{"--resampleWidth", strconv.FormatInt(targetWidth, 10)}
		if sourceExt == "jpg" || sourceExt == "jpeg" {
			args = append(args, "-s", "format", "jpeg", "-s", "formatOptions", "80")
		}
		args = append(args, source, "--out", temporary)
		sipsResult, err := ctx.Desktop().Shell().Exec("sips", args, api.ShellOptions{})
		if err != nil {
			return err
		}
		result = &sipsResult
	}
	if result == nil || result.ExitCode != 0 {
		ffmpegResult, err := scaleWithFFmpeg(ctx, source, temporary, targetWidth)
		if err != nil {
			return err
		}
		if ffmpegResult != nil {
			result = ffmpegResult
		}
	}
	if result == nil || result.ExitCode != 0 {
		stderr := ""
		if result != nil {
			stderr = strings.TrimSpace(result.Stderr)
		}
		return errors.New(firstNonEmpty(stderr, "Resizing failed"))
	}
	return nil
}

func scaleWithFFmpeg(ctx api.Context, source, temporary string, targetWidth int64) (*api.ShellResult, error) {
	if !toolAvailable(ctx, "ffmpeg") {
		return nil, nil
	}
	filter := "scale=iw*0.5:ih*0.5"
	if targetWidth > 0 {
		filter = fmt.Sprintf("scale=%d:-2", targetWidth)
	}
	result, err := ctx.Desktop().Shell().Exec("ffmpeg", []string{
		"-hide_banner", "-loglevel", "error",
		"-i", source,
		"-vframes", "1",
		"-vf", filter,
		temporary, "-y",
	}, api.ShellOptions{})
	if err != nil {
		return nil, err
	}
	return &result, nil
}

func quantizePNG(ctx api.Context, temporary string) error {
	quantized := temporary + ".opt.png"
	result, err := ctx.Desktop().Shell().Exec("pngquant", []string{
		"--quality", "65-85", "--speed", "1", "--strip", "--force",
		"--output", quantized, "--", temporary,
	}, api.ShellOptions{})
	if err != nil {
		return err
	}
	if result.ExitCode != 0 {
		return removeIfPresent(ctx, quantized)
	}
	return moveFile(ctx, quantized, temporary, "Could not optimize the resized file")
}

func moveFile(ctx api.Context, from, to, fallback string) error {
	result, err := ctx.Desktop().Shell().Exec("/bin/mv", []string{from, to}, api.ShellOptions{})
	if err != nil {
		return err
	}
	if result.ExitCode != 0 {
		return errors.New(firstNonEmpty(strings.TrimSpace(result.Stderr), fallback))
	}
	return nil
}
