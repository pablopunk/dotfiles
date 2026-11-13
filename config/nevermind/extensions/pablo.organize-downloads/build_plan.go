package main

import (
	"fmt"
	"math"
	"regexp"
	"sort"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func buildPlan(scan scanResult) []planRow {
	rows := make([]planRow, 0, len(scan.entries))
	for _, candidate := range scan.entries {
		rows = append(rows, planRow{
			kind:     candidate.kind,
			name:     candidate.name,
			size:     candidate.size,
			category: classify(candidate.kind, candidate.name, scan.categories),
		})
	}
	sort.SliceStable(rows, func(i, j int) bool {
		if rows[i].category != rows[j].category {
			return lessFold(rows[i].category, rows[j].category)
		}
		return lessFold(rows[i].name, rows[j].name)
	})
	return rows
}

func classify(kind, name string, categories []string) string {
	if kind != "file" {
		return resolveCategory("Misc", categories)
	}
	lower := strings.ToLower(name)
	extension := ""
	if strings.Contains(lower, ".") {
		parts := strings.Split(lower, ".")
		extension = parts[len(parts)-1]
	}
	if sensitivePattern.MatchString(lower) {
		return resolveCategory("Credentials & Sensitive", categories)
	}
	for _, group := range extensionGroups {
		if !contains(group.extensions, extension) {
			continue
		}
		if group.category == "Archives" && installLike.MatchString(lower) {
			return resolveCategory("Installers", categories)
		}
		return resolveCategory(group.category, categories)
	}
	return resolveCategory("Misc", categories)
}

func resolveCategory(desired string, existing []string) string {
	target := normalize(desired)
	for _, category := range existing {
		if normalize(category) == target {
			return category
		}
	}
	for _, category := range existing {
		for _, keyword := range categoryKeywords[desired] {
			if strings.Contains(normalize(category), keyword) {
				return category
			}
		}
	}
	return desired
}

func normalize(value string) string {
	return nonAlphanumeric.ReplaceAllString(strings.ToLower(value), "")
}

func summarizePlan(rows []planRow) string {
	counts := map[string]int{}
	for _, row := range rows {
		counts[row.category]++
	}
	categories := make([]string, 0, len(counts))
	for category := range counts {
		categories = append(categories, category)
	}
	sort.SliceStable(categories, func(i, j int) bool {
		if counts[categories[i]] != counts[categories[j]] {
			return counts[categories[i]] > counts[categories[j]]
		}
		return lessFold(categories[i], categories[j])
	})
	parts := make([]string, 0, len(categories))
	for _, category := range categories {
		parts = append(parts, fmt.Sprintf("%d %s", counts[category], category))
	}
	return strings.Join(parts, " · ")
}

func categorySummary(movedByCategory map[string][]planRow) string {
	var parts []string
	for category, rows := range movedByCategory {
		parts = append(parts, fmt.Sprintf("%s:%d", category, len(rows)))
	}
	sort.Strings(parts)
	return strings.Join(parts, ",")
}

func distinctCategories(rows []planRow) []string {
	seen := map[string]bool{}
	var categories []string
	for _, row := range rows {
		if !seen[row.category] {
			seen[row.category] = true
			categories = append(categories, row.category)
		}
	}
	return categories
}

func startMoveProgress(ctx api.Context, total int) {
	err := ctx.Indicators().Show(api.IndicatorInput{
		ID:       moveProgressID,
		Title:    "Organizing Downloads",
		Subtitle: fmt.Sprintf("Preparing to move %d items…", total),
		Status:   api.IndicatorLoading,
		Value:    0,
		Total:    total,
	})
	if err != nil {
		ctx.Logs().Log(api.LogWarn, "Downloads progress indicator could not be shown: "+err.Error(), nil)
	}
}

func reportMove(ctx api.Context, input api.IndicatorInput) {
	input.ID = moveProgressID
	if err := ctx.Indicators().Update(input); err != nil {
		ctx.Logs().Log(api.LogWarn, "Downloads progress indicator update failed: "+err.Error(), nil)
	}
}

func emptySubtitle(failures []moveFailure) string {
	if len(failures) > 0 {
		return "Every item was skipped."
	}
	return ""
}

func categoryIconOr(category, fallback string) string {
	if icon, ok := categoryIcons[category]; ok {
		return icon
	}
	return fallback
}

func formatBytes(bytes int64) string {
	if bytes <= 0 {
		return "0 B"
	}
	units := []string{"B", "KB", "MB", "GB", "TB"}
	value := float64(bytes)
	unit := 0
	for value >= 1024 && unit < len(units)-1 {
		value /= 1024
		unit++
	}
	if value >= 10 || unit == 0 {
		return fmt.Sprintf("%d %s", int64(jsRound(value)), units[unit])
	}
	return fmt.Sprintf("%.1f %s", value, units[unit])
}

func jsRound(value float64) float64 {
	return math.Floor(value + 0.5)
}

func plural(count int, noun string) string {
	if count == 1 {
		return fmt.Sprintf("%d %s", count, noun)
	}
	return fmt.Sprintf("%d %ss", count, noun)
}

func pluralSuffix(count string) string {
	if count == "1" {
		return ""
	}
	return "s"
}

func firstCapture(pattern *regexp.Regexp, text string) string {
	if match := pattern.FindStringSubmatch(text); match != nil {
		return match[1]
	}
	return "0"
}

func lessFold(a, b string) bool {
	if la, lb := strings.ToLower(a), strings.ToLower(b); la != lb {
		return la < lb
	}
	return a < b
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
