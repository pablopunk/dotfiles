package main

import (
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func binKey(color rgb) string {
	parts := make([]string, 0, 3)
	for _, value := range color {
		parts = append(parts, strconv.Itoa(int(math.Min(11, math.Floor(value*12)))))
	}
	return strings.Join(parts, ",")
}

func mergeCluster(clusters []colorCluster, mean rgb, count int) []colorCluster {
	for index := range clusters {
		if distance(clusters[index].color, mean) < 0.16 {
			near := &clusters[index]
			total := float64(near.count + count)
			for channel := range near.color {
				near.color[channel] = (near.color[channel]*float64(near.count) + mean[channel]*float64(count)) / total
			}
			near.count += count
			return clusters
		}
	}
	return append(clusters, colorCluster{color: mean, count: count})
}

func paletteFromClusters(clusters []colorCluster) (palette, error) {
	if len(clusters) == 0 {
		return palette{}, errors.New("No opaque colors could be extracted from this image.")
	}
	var usable []colorCluster
	for _, cluster := range clusters {
		if maxChannel(cluster.color) > 0.12 && minChannel(cluster.color) < 0.9 {
			usable = append(usable, cluster)
		}
	}
	candidates := usable
	if len(candidates) == 0 {
		candidates = clusters
	}
	first := candidates[0].color
	second, found := distantColor(candidates, first)
	if !found {
		second, found = distantColor(clusters, first)
	}
	base := first
	if found {
		base = second
	}
	var highlight rgb
	for index := range base {
		highlight[index] = base[index]*0.5 + 0.5
	}
	return palette{Tint: first, Highlight: highlight, Monochrome: !found}, nil
}

func distantColor(clusters []colorCluster, first rgb) (rgb, bool) {
	for _, cluster := range clusters {
		if distance(first, cluster.color) >= 0.23 {
			return cluster.color, true
		}
	}
	return rgb{}, false
}

func distance(a, b rgb) float64 {
	sum := 0.0
	for index := range a {
		sum += (a[index] - b[index]) * (a[index] - b[index])
	}
	return math.Sqrt(sum)
}

func maxChannel(color rgb) float64 {
	return math.Max(color[0], math.Max(color[1], color[2]))
}

func minChannel(color rgb) float64 {
	return math.Min(color[0], math.Min(color[1], color[2]))
}

func hexColor(color rgb) string {
	out := "#"
	for _, value := range color {
		out += fmt.Sprintf("%02x", int(math.Floor(value*255+0.5)))
	}
	return out
}

func componentsOf(color rgb) string {
	return fmt.Sprintf("%.6f %.6f %.6f", color[0], color[1], color[2])
}

type snapshot map[string]*string

func applyColors(ctx api.Context, colors palette) (string, error) {
	version, err := ctx.Desktop().Shell().Exec("/usr/bin/sw_vers", []string{"-productVersion"}, api.ShellOptions{})
	if err != nil {
		return "", err
	}
	if version.ExitCode != 0 {
		return "", errors.New("Cannot determine macOS version.")
	}
	tahoe := majorVersion(version.Stdout) >= 26
	values := snapshot{"AppleHighlightColor": ptr(componentsOf(colors.Highlight))}
	if tahoe {
		values["AppleIconAppearanceTintColor"] = ptr("Other")
		values["AppleIconAppearanceCustomTintColor"] = ptr(componentsOf(colors.Tint) + " 1.0")
		values["AppleIconAppearanceTheme"] = ptr("TintedLight")
	}
	before, err := readSnapshot(ctx, sortedKeys(values))
	if err != nil {
		return "", err
	}
	if err := rememberOriginal(ctx, before); err != nil {
		return "", err
	}
	if err := applyWithRollback(ctx, values, before); err != nil {
		return "", err
	}
	if tahoe {
		return fmt.Sprintf("Light tint %s \u00b7 Highlight %s", hexColor(colors.Tint), hexColor(colors.Highlight)), nil
	}
	return fmt.Sprintf("Highlight %s \u00b7 Icon tint requires macOS 26+", hexColor(colors.Highlight)), nil
}

func majorVersion(text string) int {
	major, _ := strconv.Atoi(strings.Split(strings.TrimSpace(text), ".")[0])
	return major
}

func rememberOriginal(ctx api.Context, before snapshot) error {
	var original snapshot
	found, err := ctx.Storage().Get(backupKey, &original)
	if err != nil {
		return err
	}
	merged := snapshot{}
	for key, value := range before {
		merged[key] = value
	}
	if found {
		for key, value := range original {
			merged[key] = value
		}
	}
	return ctx.Storage().Set(backupKey, merged)
}

func applyWithRollback(ctx api.Context, values, before snapshot) error {
	err := writeAndVerify(ctx, values)
	if err == nil {
		return nil
	}
	if rollbackErr := writeSnapshot(ctx, before); rollbackErr != nil {
		return fmt.Errorf("%s Rollback failed: %s. Use Restore Online Wallpaper Colors.", err.Error(), rollbackErr.Error())
	}
	return err
}

func writeAndVerify(ctx api.Context, values snapshot) error {
	if err := writeSnapshot(ctx, values); err != nil {
		return err
	}
	check, err := readSnapshot(ctx, sortedKeys(values))
	if err != nil {
		return err
	}
	for key, value := range values {
		if !sameValue(check[key], value) {
			return errors.New("macOS did not retain the requested colors.")
		}
	}
	return nil
}

func sameValue(a, b *string) bool {
	return a != nil && b != nil && *a == *b
}

func readSnapshot(ctx api.Context, keys []string) (snapshot, error) {
	shell := ctx.Desktop().Shell()
	result := snapshot{}
	for _, key := range keys {
		read, err := shell.Exec("/usr/bin/defaults", []string{"read", "-g", key}, api.ShellOptions{})
		if err != nil {
			return nil, err
		}
		if read.ExitCode != 0 {
			if missingKey(read, key) {
				result[key] = nil
				continue
			}
			return nil, fmt.Errorf("Cannot read %s: %s", key, firstNonEmpty(strings.TrimSpace(read.Stderr), strings.TrimSpace(read.Stdout)))
		}
		kind, err := shell.Exec("/usr/bin/defaults", []string{"read-type", "-g", key}, api.ShellOptions{})
		if err != nil {
			return nil, err
		}
		if kind.ExitCode != 0 || !stringType.MatchString(kind.Stdout) {
			return nil, fmt.Errorf("Unexpected preference type for %s; preferences were not changed.", key)
		}
		value := strings.TrimSpace(read.Stdout)
		result[key] = &value
	}
	return result, nil
}

func writeSnapshot(ctx api.Context, values snapshot) error {
	shell := ctx.Desktop().Shell()
	for _, key := range sortedKeys(values) {
		if !contains(appearanceKeys, key) {
			return errors.New("Invalid saved appearance preference.")
		}
		value := values[key]
		args := []string{"delete", "-g", key}
		if value != nil {
			args = []string{"write", "-g", key, "-string", *value}
		}
		result, err := shell.Exec("/usr/bin/defaults", args, api.ShellOptions{})
		if err != nil {
			return err
		}
		if result.ExitCode != 0 && !(value == nil && missingKey(result, key)) {
			return fmt.Errorf("Cannot update %s: %s", key, firstNonEmpty(result.Stderr, result.Stdout))
		}
	}
	return nil
}

func missingKey(result api.ShellResult, key string) bool {
	text := result.Stderr + "\n" + result.Stdout
	return strings.Contains(text, key) && missingDefault.MatchString(text)
}

func restartDock(ctx api.Context) error {
	result, err := ctx.Desktop().Shell().Exec("/usr/bin/killall", []string{"Dock"}, api.ShellOptions{TimeoutMs: 10000})
	if err != nil {
		return err
	}
	if result.ExitCode != 0 && !noMatchingProcess.MatchString(result.Stderr+result.Stdout) {
		return fmt.Errorf("Could not restart Dock: %s", firstNonEmpty(result.Stderr, result.Stdout))
	}
	return nil
}

func applyWallpaper(ctx api.Context, path string) error {
	if !isMac(ctx) {
		return errors.New("This wallpaper setter currently supports macOS only.")
	}
	escaped := strings.ReplaceAll(strings.ReplaceAll(path, "\\", "\\\\"), "\"", "\\\"")
	scripts := []string{
		fmt.Sprintf("tell application \"System Events\" to tell every desktop to set picture to POSIX file \"%s\"", escaped),
		fmt.Sprintf("tell application \"Finder\" to set desktop picture to POSIX file \"%s\"", escaped),
	}
	failure := ""
	for _, script := range scripts {
		result, err := ctx.Desktop().Shell().AppleScript(script, api.ShellOptions{})
		if err != nil {
			failure = err.Error()
			continue
		}
		if result.ExitCode == 0 {
			return nil
		}
		failure = firstNonEmpty(result.Stderr, result.Stdout)
	}
	return errors.New(firstNonEmpty(failure, "Cannot set wallpaper. Check macOS Automation permissions for Nevermind."))
}

func matchColors(ctx api.Context, file api.FileRef) (string, error) {
	colors, err := extractPalette(ctx, file)
	if err != nil {
		return "", err
	}
	return applyColors(ctx, colors)
}
