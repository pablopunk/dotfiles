package main

import (
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func colorSummary(colors palette, tahoe bool) string {
	if !tahoe {
		return "Highlight " + hex(colors.Highlight) + " · Icon tint requires macOS Tahoe 26+"
	}
	single := ""
	if colors.Monochrome {
		single = " (single-color fallback)"
	}
	return "Light tint " + hex(colors.Tint) + " · Highlight " + hex(colors.Highlight) + single
}

func applyColors(ctx api.Context, colors palette) (string, error) {
	tahoe, err := isTahoeOrLater(ctx)
	if err != nil {
		return "", err
	}
	values := snapshot{"AppleHighlightColor": stringPtr(components(colors.Highlight))}
	if tahoe {
		values["AppleIconAppearanceTintColor"] = stringPtr("Other")
		values["AppleIconAppearanceCustomTintColor"] = stringPtr(components(colors.Tint) + " 1.0")
		values["AppleIconAppearanceTheme"] = stringPtr("TintedLight")
	}
	before, err := readSnapshot(ctx, snapshotKeys(values))
	if err != nil {
		return "", err
	}
	if err := backupBefore(ctx, before); err != nil {
		return "", err
	}
	if err := writeAndVerify(ctx, values); err != nil {
		if rollbackErr := writeSnapshot(ctx, before); rollbackErr != nil {
			return "", fmt.Errorf("%w Rollback also failed: %v. Use Restore Previous Colors.", err, rollbackErr)
		}
		return "", err
	}
	return colorSummary(colors, tahoe), nil
}

func isTahoeOrLater(ctx api.Context) (bool, error) {
	result, err := ctx.Desktop().Shell().Exec("/usr/bin/sw_vers", []string{"-productVersion"}, api.ShellOptions{})
	if err != nil || result.ExitCode != 0 {
		return false, errors.New("Cannot determine macOS version; appearance preferences were not changed.")
	}
	major, _ := strconv.Atoi(strings.Split(strings.TrimSpace(result.Stdout), ".")[0])
	return major >= 26, nil
}

func backupBefore(ctx api.Context, before snapshot) error {
	var original snapshot
	if _, err := ctx.Storage().Get(backupKey, &original); err != nil {
		return err
	}
	merged := snapshot{}
	for key, value := range before {
		merged[key] = value
	}
	for key, value := range original {
		merged[key] = value
	}
	return ctx.Storage().Set(backupKey, merged)
}

func writeAndVerify(ctx api.Context, values snapshot) error {
	if err := writeSnapshot(ctx, values); err != nil {
		return err
	}
	check, err := readSnapshot(ctx, snapshotKeys(values))
	if err != nil {
		return err
	}
	for key, want := range values {
		if !sameValue(check[key], want) {
			return errors.New("macOS did not retain the requested color preferences.")
		}
	}
	return nil
}

func readSnapshot(ctx api.Context, keys []string) (snapshot, error) {
	shell := ctx.Desktop().Shell()
	values := snapshot{}
	for _, key := range keys {
		result, err := shell.Exec("/usr/bin/defaults", []string{"read", "-g", key}, api.ShellOptions{})
		if err != nil {
			return nil, err
		}
		if result.ExitCode != 0 {
			if isMissingPreference(result, key) {
				values[key] = nil
				continue
			}
			return nil, fmt.Errorf("Cannot read %s: %s", key, firstNonEmptyTrimmed(result.Stderr, result.Stdout))
		}
		kind, err := shell.Exec("/usr/bin/defaults", []string{"read-type", "-g", key}, api.ShellOptions{})
		if err != nil || kind.ExitCode != 0 || !stringPreference.MatchString(kind.Stdout) {
			return nil, fmt.Errorf("Unexpected preference type for %s; no color preferences were changed.", key)
		}
		value := strings.TrimSpace(result.Stdout)
		values[key] = &value
	}
	return values, nil
}

func writeSnapshot(ctx api.Context, values snapshot) error {
	shell := ctx.Desktop().Shell()
	for _, key := range snapshotKeys(values) {
		if !contains(colorKeys, key) {
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
		if result.ExitCode != 0 && !(value == nil && isMissingPreference(result, key)) {
			return fmt.Errorf("Cannot update %s: %s", key, firstNonEmptyTrimmed(result.Stderr, result.Stdout))
		}
	}
	return nil
}

func isMissingPreference(result api.ShellResult, key string) bool {
	diagnostic := result.Stderr + "\n" + result.Stdout
	return strings.Contains(diagnostic, key) && missingDefaults.MatchString(diagnostic)
}

func restoreColors(ctx api.Context) error {
	var saved snapshot
	found, err := ctx.Storage().Get(backupKey, &saved)
	if err != nil {
		return err
	}
	if !found {
		return errors.New("No previous colors have been saved yet.")
	}
	before, err := readSnapshot(ctx, snapshotKeys(saved))
	if err != nil {
		return err
	}
	if err := writeSnapshot(ctx, saved); err != nil {
		if rollbackErr := writeSnapshot(ctx, before); rollbackErr != nil {
			return fmt.Errorf("%w Rollback also failed: %v", err, rollbackErr)
		}
		return err
	}
	if err := ctx.Storage().Delete(backupKey); err != nil {
		return err
	}
	showIndicator(ctx, api.IndicatorInput{Title: "Previous color preferences restored", Subtitle: "Reopen apps or log out/in if the appearance has not refreshed.", Status: api.IndicatorSuccess, DurationMs: 6000})
	return nil
}

func isMac(ctx api.Context) bool {
	name := strings.ToLower(ctx.System().OS())
	return strings.Contains(name, "mac") || strings.Contains(name, "darwin")
}

func snapshotKeys(values snapshot) []string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func sameValue(a, b *string) bool {
	if a == nil || b == nil {
		return a == b
	}
	return *a == *b
}

func stringPtr(text string) *string {
	return &text
}

func contains(values []string, target string) bool {
	for _, value := range values {
		if value == target {
			return true
		}
	}
	return false
}

func firstNonEmptyTrimmed(values ...string) string {
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			return trimmed
		}
	}
	return ""
}

func showIndicator(ctx api.Context, input api.IndicatorInput) {
	_ = ctx.Indicators().Show(input)
}

func hideIndicator(ctx api.Context, id string) {
	_ = ctx.Indicators().Hide(id)
}

func orDefault(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
