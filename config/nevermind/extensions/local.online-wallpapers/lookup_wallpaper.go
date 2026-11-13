package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func lookupWallpaper(ctx api.Context, args map[string]string) (wallpaper, error) {
	result, err := listing(ctx, stateFromArgs(args))
	if err != nil {
		return wallpaper{}, err
	}
	for _, candidate := range result.Data {
		if candidate.ID == args["id"] {
			return candidate, nil
		}
	}
	return wallpaper{}, errors.New("Wallpaper is no longer listed. Refresh Results.")
}

func runWallpaperMode(ctx api.Context, candidate wallpaper, args map[string]string) (api.Result, error) {
	mode := args["mode"]
	if err := ctx.Indicators().Show(api.IndicatorInput{ID: indicatorID, Title: "Downloading wallpaper\u2026", Status: api.IndicatorLoading}); err != nil {
		return api.Result{}, err
	}
	result, err := wallpaperSteps(ctx, candidate, args, mode)
	if err != nil {
		_ = ctx.Indicators().Hide(indicatorID)
		return api.Result{}, err
	}
	return result, nil
}

func wallpaperSteps(ctx api.Context, candidate wallpaper, args map[string]string, mode string) (api.Result, error) {
	file, err := downloadWallpaper(ctx, candidate)
	if err != nil {
		return api.Result{}, err
	}
	switch mode {
	case "save":
		return api.Result{}, ctx.Indicators().Show(api.IndicatorInput{ID: indicatorID, Title: "Wallpaper saved", Subtitle: file.Path, Status: api.IndicatorSuccess, DurationMs: 4000})
	case "palette":
		return previewPalette(ctx, candidate, args, file)
	}
	if err := applyWallpaper(ctx, file.Path); err != nil {
		return api.Result{}, err
	}
	if mode == "only" {
		return api.Result{}, ctx.Indicators().Show(api.IndicatorInput{ID: indicatorID, Title: "Wallpaper updated", Subtitle: candidate.Resolution, Status: api.IndicatorSuccess, DurationMs: 3000})
	}
	if err := ctx.Indicators().Update(api.IndicatorInput{ID: indicatorID, Title: "Wallpaper set \u00b7 Matching colors\u2026", Status: api.IndicatorLoading}); err != nil {
		return api.Result{}, err
	}
	summary, err := matchColors(ctx, file)
	if err != nil {
		return api.Result{}, errors.New("Wallpaper was set, but color matching failed: " + err.Error())
	}
	if err := restartDock(ctx); err != nil {
		return api.Result{}, errors.New("Wallpaper and colors were updated, but " + err.Error())
	}
	return api.Result{}, ctx.Indicators().Show(api.IndicatorInput{ID: indicatorID, Title: "Wallpaper updated \u00b7 Dock refreshed", Subtitle: summary, Status: api.IndicatorSuccess, DurationMs: 6000})
}

func previewPalette(ctx api.Context, candidate wallpaper, args map[string]string, file api.FileRef) (api.Result, error) {
	if err := ctx.Indicators().Update(api.IndicatorInput{ID: indicatorID, Title: "Extracting colors locally\u2026", Status: api.IndicatorLoading}); err != nil {
		return api.Result{}, err
	}
	colors, err := extractPalette(ctx, file)
	if err != nil {
		return api.Result{}, err
	}
	if err := ctx.Indicators().Hide(indicatorID); err != nil {
		return api.Result{}, err
	}
	tintHex := hexColor(colors.Tint)
	highHex := hexColor(colors.Highlight)
	localSrc := ctx.Desktop().Files().FileURL(file.Path)
	html := paletteHTML(candidate, tintHex, highHex, localSrc, colors.Monochrome)
	view := api.View{Kind: api.ViewWebview, Title: "Matching Colors \u00b7 " + candidate.ID, Subtitle: candidate.Resolution + " \u00b7 Preview changes nothing", Size: api.SizeLarge, Webview: &api.WebviewSpec{HTML: html}, Actions: []api.Action{applyAction("Set Wallpaper & Match Colors", "colors", wallpaperArgs(stateFromArgs(args), candidate.ID), ""), api.CopyText("Copy Icon Tint "+tintHex, tintHex, false), api.CopyText("Copy Highlight "+highHex, highHex, false), api.OpenURL("View on Wallhaven", candidate.URL)}}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func paletteHTML(candidate wallpaper, tintHex, highHex, imgSrc string, mono bool) string {
	note := "Two distinct colors found."
	if mono {
		note = "Single-color fallback \u00b7 no distinct second color found."
	}
	safeImg := strings.ReplaceAll(imgSrc, "\"", "&quot;")
	return "<html><head><meta charset=\"utf-8\"><style>body{margin:0;padding:20px;font-family:-apple-system,Helvetica,Arial,sans-serif;background:#f5f5f7;color:#111}.card{max-width:620px;margin:0 auto}img.wall{width:100%;border-radius:12px;display:block;border:1px solid rgba(0,0,0,.12)}.sw{display:flex;gap:12px;margin-top:14px}.swd{flex:1;border-radius:12px;overflow:hidden;border:1px solid rgba(0,0,0,.12);background:#fff}.c{height:110px}.l{padding:10px 12px;font-size:13px}.h{font-family:ui-monospace,Menlo,monospace;font-weight:700;font-size:15px;margin-top:2px}.s{opacity:.6;font-size:12px;margin-top:2px}.m{margin-top:10px;font-size:13px;font-weight:600}.n{margin-top:8px;font-size:12px;opacity:.65;line-height:1.5}</style></head><body><div class=\"card\"><img class=\"wall\" src=\"" + safeImg + "\"><div class=\"m\">Wallhaven \u00b7 " + candidate.ID + " \u00b7 " + candidate.Resolution + "</div><div class=\"sw\"><div class=\"swd\"><div class=\"c\" style=\"background:" + tintHex + "\"></div><div class=\"l\"><div>Icon tint</div><div class=\"h\">" + tintHex + "</div><div class=\"s\">Tinted Light \u00b7 macOS 26+</div></div></div><div class=\"swd\"><div class=\"c\" style=\"background:" + highHex + "\"></div><div class=\"l\"><div>Selection highlight</div><div class=\"h\">" + highHex + "</div><div class=\"s\">" + note + "</div></div></div></div></div><div class=\"n\">Preview changes no settings. Applying colors uses local extraction and restarts Dock. System Dark/Light stays unchanged.</div></div></body></html>"
}

func paletteSummary(colors palette) string {
	monochrome := ""
	if colors.Monochrome {
		monochrome = " \u00b7 Single-color fallback"
	}
	return "Icon tint: " + hexColor(colors.Tint) + " (Tinted Light)\n" + "Selection highlight: " + hexColor(colors.Highlight) + monochrome + "\n\n" + "Preview changes no settings."
}

func downloadWallpaper(ctx api.Context, candidate wallpaper) (api.FileRef, error) {
	if !idPattern.MatchString(candidate.ID) {
		return api.FileRef{}, errors.New("Invalid wallpaper ID.")
	}
	directory, err := wallpaperDirectory(ctx)
	if err != nil {
		return api.FileRef{}, err
	}
	extension := "jpg"
	if candidate.FileType == "image/png" {
		extension = "png"
	}
	path := fmt.Sprintf("%s/wallhaven-%s.%s", directory, candidate.ID, extension)
	if _, err := ctx.Desktop().Shell().Exec("/bin/mkdir", []string{"-p", directory}, api.ShellOptions{}); err != nil {
		return api.FileRef{}, err
	}
	if existing, err := ctx.Desktop().Files().Metadata(path); err == nil && existing.Size > 0 {
		if err := requireImageSignature(ctx, path, path); err == nil {
			return existing, nil
		}
		_, _ = ctx.Desktop().Shell().Exec("/bin/rm", []string{"-f", path}, api.ShellOptions{})
	}
	if candidate.FileSize > maxDownloadBytes {
		return api.FileRef{}, errors.New("This wallpaper exceeds the 60 MB download limit.")
	}
	if err := fetchWallpaperFile(ctx, candidate, path); err != nil {
		return api.FileRef{}, err
	}
	return ctx.Desktop().Files().Metadata(path)
}

func fetchWallpaperFile(ctx api.Context, candidate wallpaper, path string) error {
	source, err := checkedURL(candidate.Path, "image")
	if err != nil {
		return err
	}
	partial := path + ".part"
	result, err := ctx.Desktop().Shell().Exec("/usr/bin/curl", []string{"--silent", "--show-error", "--max-time", "90", "--max-filesize", strconv.Itoa(maxDownloadBytes), "--output", partial, "--write-out", "%{http_code} %{content_type}", source}, api.ShellOptions{})
	if err != nil {
		return err
	}
	if result.ExitCode != 0 {
		return removeAfterFailure(ctx, partial, errors.New(firstNonEmpty(strings.TrimSpace(result.Stderr), "Wallpaper download failed.")))
	}
	fields := strings.Fields(result.Stdout)
	if len(fields) < 1 || fields[0] != "200" {
		return removeAfterFailure(ctx, partial, fmt.Errorf("Wallpaper download failed (HTTP %s).", firstNonEmpty(firstField(fields), "unknown")))
	}
	if len(fields) < 2 || !downloadType.MatchString(strings.Join(fields[1:], " ")) {
		return removeAfterFailure(ctx, partial, errors.New("The download was not a supported image."))
	}
	if err := requireImageSignature(ctx, partial, path); err != nil {
		return removeAfterFailure(ctx, partial, err)
	}
	return moveWallpaper(ctx, partial, path)
}

func firstField(fields []string) string {
	if len(fields) == 0 {
		return ""
	}
	return fields[0]
}

func requireImageSignature(ctx api.Context, partial, path string) error {
	kind, err := ctx.Desktop().Shell().Exec("/usr/bin/file", []string{"--brief", "--mime-type", partial}, api.ShellOptions{})
	if err != nil {
		return err
	}
	if kind.ExitCode != 0 {
		return errors.New("Could not verify wallpaper file type: " + firstNonEmpty(strings.TrimSpace(kind.Stderr), strings.TrimSpace(kind.Stdout)))
	}
	actual := strings.TrimSpace(kind.Stdout)
	expected := "image/jpeg"
	if strings.HasSuffix(path, ".png") {
		expected = "image/png"
	}
	if actual != expected {
		return fmt.Errorf("Downloaded image has an unexpected file signature (%s, expected %s). The download was discarded. Try Download Only again.", actual, expected)
	}
	return nil
}

func moveWallpaper(ctx api.Context, partial, path string) error {
	result, err := ctx.Desktop().Shell().Exec("/bin/mv", []string{partial, path}, api.ShellOptions{})
	if err != nil {
		return err
	}
	if result.ExitCode != 0 {
		return removeAfterFailure(ctx, partial, errors.New(firstNonEmpty(strings.TrimSpace(result.Stderr), "Could not save the wallpaper.")))
	}
	return nil
}

func removeAfterFailure(ctx api.Context, partial string, cause error) error {
	_, _ = ctx.Desktop().Shell().Exec("/bin/rm", []string{"-f", partial}, api.ShellOptions{})
	return cause
}

func extractPalette(ctx api.Context, file api.FileRef) (palette, error) {
	var colors palette
	key := fmt.Sprintf("palette-v1:%s:%d:%d", file.Path, file.MtimeMs, file.Size)
	err := ctx.Storage().MemoStale(key, 720*time.Hour, 2160*time.Hour, &colors, func() (any, error) {
		result, err := samplePalette(ctx, file.Path)
		return result, err
	})
	return colors, err
}

func samplePalette(ctx api.Context, path string) (palette, error) {
	result, err := ctx.Desktop().Shell().Exec("/usr/bin/osascript", []string{"-l", "JavaScript", "-e", jxaSampleScript, path}, api.ShellOptions{TimeoutMs: 45000, OutputLimit: 200000})
	if err != nil {
		return palette{}, err
	}
	if result.ExitCode != 0 {
		return palette{}, fmt.Errorf("Local palette extraction failed: %s", firstNonEmpty(strings.TrimSpace(result.Stderr), strings.TrimSpace(result.Stdout)))
	}
	samples, err := parseSamples(strings.TrimSpace(result.Stdout))
	if err != nil {
		return palette{}, err
	}
	return paletteFromClusters(clusterSamples(samples))
}

func parseSamples(text string) ([]rgb, error) {
	var raw any
	if err := json.Unmarshal([]byte(text), &raw); err != nil {
		return nil, errors.New("Image sampler returned invalid data.")
	}
	list, ok := raw.([]any)
	if !ok {
		return nil, errors.New("Image sampler returned invalid data.")
	}
	var colors []rgb
	for _, item := range list {
		if color, ok := parseSample(item); ok {
			colors = append(colors, color)
		}
	}
	return colors, nil
}

func parseSample(item any) (rgb, bool) {
	values, ok := item.([]any)
	if !ok || len(values) != 3 {
		return rgb{}, false
	}
	var color rgb
	for index, value := range values {
		number, ok := value.(float64)
		if !ok || number < 0 || number > 1 {
			return rgb{}, false
		}
		color[index] = number
	}
	return color, true
}

func clusterSamples(colors []rgb) []colorCluster {
	var keys []string
	bins := map[string]*colorBin{}
	for _, color := range colors {
		key := binKey(color)
		bin, found := bins[key]
		if !found {
			bin = &colorBin{}
			bins[key] = bin
			keys = append(keys, key)
		}
		bin.count++
		for index := range color {
			bin.sum[index] += color[index]
		}
	}
	ordered := make([]*colorBin, 0, len(keys))
	for _, key := range keys {
		ordered = append(ordered, bins[key])
	}
	sort.SliceStable(ordered, func(i, j int) bool { return ordered[i].count > ordered[j].count })
	var clusters []colorCluster
	for _, bin := range ordered {
		mean := rgb{}
		for index := range mean {
			mean[index] = bin.sum[index] / float64(bin.count)
		}
		clusters = mergeCluster(clusters, mean, bin.count)
	}
	sort.SliceStable(clusters, func(i, j int) bool { return clusters[i].count > clusters[j].count })
	return clusters
}
