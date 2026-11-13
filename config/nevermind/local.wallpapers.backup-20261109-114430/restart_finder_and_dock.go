package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"sort"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func restartFinderAndDock(ctx api.Context) error {
	for _, name := range []string{"Finder", "Dock"} {
		result, err := ctx.Desktop().Shell().Exec("/usr/bin/killall", []string{name}, api.ShellOptions{})
		if err != nil {
			return err
		}
		if result.ExitCode != 0 && !noMatchingProcs.MatchString(result.Stderr) {
			return fmt.Errorf("Could not restart %s: %s", name, strings.TrimSpace(result.Stderr))
		}
	}
	showIndicator(ctx, api.IndicatorInput{Title: "Finder and Dock restarted", Status: api.IndicatorSuccess, DurationMs: 2500})
	return nil
}

func applyWallpaper(ctx api.Context, path string) error {
	shell := ctx.Desktop().Shell()
	if strings.Contains(strings.ToLower(ctx.System().OS()), "linux") {
		return setLinuxWallpaper(shell, path)
	}
	lastError := ""
	for _, script := range pictureScripts(escapeAppleScript(path)) {
		result, err := shell.AppleScript(script, api.ShellOptions{})
		if err != nil {
			lastError = err.Error()
			continue
		}
		if result.ExitCode == 0 {
			return nil
		}
		lastError = orDefault(orDefault(result.Stderr, result.Stdout), lastError)
	}
	result, err := shell.Exec("/usr/bin/osascript", []string{"-e", `tell application "System Events" to tell every desktop to set picture to POSIX file "` + escapeAppleScript(path) + `"`}, api.ShellOptions{})
	if err != nil {
		lastError = err.Error()
	} else if result.ExitCode == 0 {
		return nil
	} else {
		lastError = orDefault(orDefault(result.Stderr, result.Stdout), lastError)
	}
	return errors.New(orDefault(strings.TrimSpace(lastError), "Could not set wallpaper. Check System Settings > Privacy & Security > Automation permissions."))
}

func pictureScripts(escaped string) []string {
	file := `POSIX file "` + escaped + `"`
	return []string{
		"tell application \"System Events\"\n tell every desktop\n set picture to " + file + "\n end tell\n end tell",
		"tell application \"System Events\" to set picture of every desktop to " + file,
		"tell application \"Finder\" to set desktop picture to " + file,
	}
}

func escapeAppleScript(path string) string {
	return strings.NewReplacer(`\`, `\\`, `"`, `\"`).Replace(path)
}

func setLinuxWallpaper(shell api.Shell, path string) error {
	result, err := shell.Script(linuxWallpaperScript(path), api.ShellOptions{})
	if err != nil {
		return err
	}
	if result.ExitCode != 0 {
		return errors.New(orDefault(strings.TrimSpace(result.Stderr), "Failed to set wallpaper on Linux."))
	}
	return nil
}

func linuxWallpaperScript(path string) string {
	uri := quoteShell("file://" + path)
	return "if command -v gsettings >/dev/null 2>&1; then\n" +
		"   gsettings set org.gnome.desktop.background picture-uri " + uri + " && gsettings set org.gnome.desktop.background picture-uri-dark " + uri + "\n" +
		"   elif command -v feh >/dev/null 2>&1; then feh --bg-fill " + quoteShell(path) + "\n" +
		"   elif command -v swww >/dev/null 2>&1; then swww img " + quoteShell(path) + "\n" +
		"   elif command -v hyprctl >/dev/null 2>&1; then hyprctl hyprpaper wallpaper " + quoteShell(","+path) + "\n" +
		"   else echo 'No supported wallpaper setter is installed.' >&2; exit 1; fi"
}

func quoteShell(text string) string {
	return "'" + strings.ReplaceAll(text, "'", `'\''`) + "'"
}

func extractPalette(ctx api.Context, path string) (palette, error) {
	meta, _ := ctx.Desktop().Files().Metadata(path)
	key := fmt.Sprintf("palette-v1:%s:%d:%d", path, meta.MtimeMs, meta.Size)
	var colors palette
	err := ctx.Storage().Memo(key, paletteTTL, &colors, func() (any, error) {
		sampled, sampleErr := samplePalette(ctx, path)
		return sampled, sampleErr
	})
	return colors, err
}

func samplePalette(ctx api.Context, path string) (palette, error) {
	result, err := ctx.Desktop().Shell().Exec("/usr/bin/osascript", []string{"-l", "JavaScript", "-e", sampleScript, path}, api.ShellOptions{TimeoutMs: 45000, OutputLimit: 200000})
	if err != nil {
		return palette{}, err
	}
	if result.ExitCode != 0 {
		return palette{}, fmt.Errorf("Local palette extraction failed: %s", firstNonEmptyTrimmed(result.Stderr, result.Stdout))
	}
	var samples [][]float64
	if err := json.Unmarshal([]byte(strings.TrimSpace(result.Stdout)), &samples); err != nil {
		return palette{}, errors.New("Image sampler returned invalid data.")
	}
	return buildPalette(samples)
}

func buildPalette(samples [][]float64) (palette, error) {
	clusters := clusterColors(binColors(samples))
	if len(clusters) == 0 {
		return palette{}, errors.New("No opaque colors could be extracted from this image.")
	}
	candidates := usableClusters(clusters)
	if len(candidates) == 0 {
		candidates = clusters
	}
	first := candidates[0].rgb
	second, hasSecond := distinctColor(first, candidates)
	if !hasSecond {
		second, hasSecond = distinctColor(first, clusters)
	}
	highlight := first
	if hasSecond {
		highlight = second
	}
	return palette{Tint: first, Highlight: softened(highlight), Monochrome: !hasSecond}, nil
}

func binColors(samples [][]float64) []colorBin {
	position := map[string]int{}
	var bins []colorBin
	for _, sample := range samples {
		if len(sample) != 3 || !allUnit(sample) {
			continue
		}
		rgb := [3]float64{sample[0], sample[1], sample[2]}
		key := binKey(rgb)
		index, seen := position[key]
		if !seen {
			index = len(bins)
			position[key] = index
			bins = append(bins, colorBin{})
		}
		bins[index].count++
		for channel := range rgb {
			bins[index].sum[channel] += rgb[channel]
		}
	}
	sort.SliceStable(bins, func(i, j int) bool { return bins[i].count > bins[j].count })
	return bins
}

func clusterColors(bins []colorBin) []colorCluster {
	var clusters []colorCluster
	for _, bin := range bins {
		rgb := averageOf(bin)
		near := nearbyCluster(clusters, rgb)
		if near < 0 {
			clusters = append(clusters, colorCluster{rgb: rgb, count: bin.count})
			continue
		}
		clusters[near] = mergeCluster(clusters[near], rgb, bin.count)
	}
	sort.SliceStable(clusters, func(i, j int) bool { return clusters[i].count > clusters[j].count })
	return clusters
}

func averageOf(bin colorBin) [3]float64 {
	var rgb [3]float64
	for channel := range rgb {
		rgb[channel] = bin.sum[channel] / float64(bin.count)
	}
	return rgb
}

func nearbyCluster(clusters []colorCluster, rgb [3]float64) int {
	for index, cluster := range clusters {
		if distance(cluster.rgb, rgb) < clusterDistance {
			return index
		}
	}
	return -1
}

func mergeCluster(cluster colorCluster, rgb [3]float64, count int) colorCluster {
	merged := colorCluster{count: cluster.count + count}
	for channel := range rgb {
		merged.rgb[channel] = (cluster.rgb[channel]*float64(cluster.count) + rgb[channel]*float64(count)) / float64(merged.count)
	}
	return merged
}

func usableClusters(clusters []colorCluster) []colorCluster {
	var usable []colorCluster
	for _, cluster := range clusters {
		if maxChannel(cluster.rgb) > 0.12 && minChannel(cluster.rgb) < 0.9 {
			usable = append(usable, cluster)
		}
	}
	return usable
}

func distinctColor(first [3]float64, clusters []colorCluster) ([3]float64, bool) {
	for _, cluster := range clusters {
		if distance(first, cluster.rgb) >= secondDistance {
			return cluster.rgb, true
		}
	}
	return [3]float64{}, false
}

func softened(rgb [3]float64) [3]float64 {
	for channel := range rgb {
		rgb[channel] = rgb[channel]*0.5 + 0.5
	}
	return rgb
}

func binKey(rgb [3]float64) string {
	return fmt.Sprintf("%d,%d,%d", binIndex(rgb[0]), binIndex(rgb[1]), binIndex(rgb[2]))
}

func binIndex(value float64) int {
	index := int(math.Floor(value * 12))
	if index > 11 {
		return 11
	}
	return index
}

func allUnit(values []float64) bool {
	for _, value := range values {
		if math.IsNaN(value) || value < 0 || value > 1 {
			return false
		}
	}
	return true
}

func distance(a, b [3]float64) float64 {
	sum := 0.0
	for channel := range a {
		sum += (a[channel] - b[channel]) * (a[channel] - b[channel])
	}
	return math.Sqrt(sum)
}

func maxChannel(rgb [3]float64) float64 {
	return math.Max(rgb[0], math.Max(rgb[1], rgb[2]))
}

func minChannel(rgb [3]float64) float64 {
	return math.Min(rgb[0], math.Min(rgb[1], rgb[2]))
}

func hex(rgb [3]float64) string {
	out := "#"
	for _, value := range rgb {
		out += fmt.Sprintf("%02x", int(math.Round(value*255)))
	}
	return out
}

func components(rgb [3]float64) string {
	return fmt.Sprintf("%.6f %.6f %.6f", rgb[0], rgb[1], rgb[2])
}
