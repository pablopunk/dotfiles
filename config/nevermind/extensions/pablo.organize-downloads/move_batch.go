package main

import (
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

type moveBatch struct {
	movedByCategory map[string][]planRow
	failures        []moveFailure
	processed       int
}

func (b moveBatch) movedCount() int {
	count := 0
	for _, rows := range b.movedByCategory {
		count += len(rows)
	}
	return count
}

func moveRows(ctx api.Context, scan scanResult, rows []planRow) (moveBatch, error) {
	batch := moveBatch{movedByCategory: map[string][]planRow{}}
	reportMove(ctx, api.IndicatorInput{Title: "Organizing Downloads", Subtitle: "Preparing category folders…", Status: api.IndicatorLoading, Value: 0, Total: len(rows)})
	ready, failures, err := prepareCategories(ctx, scan.rootPath, rows)
	if err != nil {
		return batch, err
	}
	batch.failures = failures
	for _, row := range rows {
		reportMove(ctx, api.IndicatorInput{Title: "Organizing Downloads", Subtitle: fmt.Sprintf("Processing %d of %d: %s", batch.processed+1, len(rows), row.name), Status: api.IndicatorLoading, Value: batch.processed, Total: len(rows)})
		if !ready[row.category] {
			batch.processed++
			reportMove(ctx, api.IndicatorInput{Title: "Organizing Downloads", Subtitle: fmt.Sprintf("Processed %d of %d · %s skipped", batch.processed, len(rows), row.name), Status: api.IndicatorLoading, Value: batch.processed, Total: len(rows)})
			continue
		}
		failure, err := moveOne(ctx, scan.rootPath, row)
		if err != nil {
			return batch, err
		}
		if failure != nil {
			batch.failures = append(batch.failures, *failure)
		} else {
			batch.movedByCategory[row.category] = append(batch.movedByCategory[row.category], row)
		}
		batch.processed++
		subtitle := fmt.Sprintf("Processed %d of %d · %d moved", batch.processed, len(rows), batch.movedCount())
		if failure != nil {
			subtitle = fmt.Sprintf("Processed %d of %d · %s skipped", batch.processed, len(rows), row.name)
		}
		reportMove(ctx, api.IndicatorInput{Title: "Organizing Downloads", Subtitle: subtitle, Status: api.IndicatorLoading, Value: batch.processed, Total: len(rows)})
	}
	return batch, nil
}

// prepareCategories creates each target category folder and records the rows of any that cannot be created.
func prepareCategories(ctx api.Context, root string, rows []planRow) (map[string]bool, []moveFailure, error) {
	ready := map[string]bool{}
	var failures []moveFailure
	for _, category := range distinctCategories(rows) {
		result, err := ctx.Desktop().Shell().Exec("mkdir", []string{"-p", root + "/categories/" + category}, api.ShellOptions{})
		if err != nil {
			return nil, nil, err
		}
		if result.ExitCode == 0 {
			ready[category] = true
			continue
		}
		for _, row := range rows {
			if row.category == category {
				failures = append(failures, moveFailure{row: row, reason: "could not create categories/" + category})
			}
		}
	}
	return ready, failures, nil
}

// moveOne moves one root entry with mv -n. A non-nil failure means the entry stayed where it was.
func moveOne(ctx api.Context, root string, row planRow) (*moveFailure, error) {
	source := root + "/" + row.name
	destination := root + "/categories/" + row.category + "/" + row.name
	result, err := ctx.Desktop().Shell().Exec("mv", []string{"-n", source, destination}, api.ShellOptions{})
	if err != nil {
		return nil, err
	}
	if result.ExitCode != 0 {
		return &moveFailure{row: row, reason: firstNonEmpty(strings.TrimSpace(result.Stderr), "mv failed")}, nil
	}
	stillThere, err := ctx.Desktop().Shell().Exec("test", []string{"-e", source}, api.ShellOptions{})
	if err != nil {
		return nil, err
	}
	if stillThere.ExitCode == 0 {
		return &moveFailure{row: row, reason: fmt.Sprintf("categories/%s already has a “%s”", row.category, row.name)}, nil
	}
	return nil, nil
}

func finishMoves(ctx api.Context, root string, rows []planRow, batch moveBatch, originals originalsOutcome) api.Result {
	revealLabel := ctx.System().Labels().RevealInFileManager
	moved := batch.movedCount()
	total := moved + len(batch.failures)
	ctx.Logs().Log(api.LogInfo, fmt.Sprintf("%s moved %d/%d · %s · failures %d · %s", extensionID, moved, len(rows), categorySummary(batch.movedByCategory), len(batch.failures), originals.status), nil)
	status := api.IndicatorSuccess
	title := "Downloads organized"
	if len(batch.failures) > 0 {
		title = "Downloads organized with skips"
	}
	if len(batch.failures) > 0 || strings.Contains(originals.status, "not created") {
		status = api.IndicatorError
	}
	reportMove(ctx, api.IndicatorInput{Title: title, Subtitle: fmt.Sprintf("%d of %d moved · %s", moved, len(rows), originals.status), Status: status, Value: batch.processed, Total: len(rows), DurationMs: 5000})
	view := movedListView(revealLabel, root, batch, originals, moved, total)
	return api.Result{View: &view, Navigation: api.NavReplace}
}

func movedListView(revealLabel, root string, batch moveBatch, originals originalsOutcome, moved, total int) api.View {
	title := "Downloads organized"
	if len(batch.failures) > 0 {
		title = "Downloads organized with skips"
	}
	items := movedCategoryItems(root, batch.movedByCategory)
	items = append(items, api.Item{
		ID:       "done:originals",
		Title:    "originals/",
		Subtitle: originals.detail,
		Icon:     "link",
		Primary:  api.Primary(api.RevealPath("Reveal originals/", root+"/originals")),
		Actions:  []api.Action{api.RevealPath("Reveal ~/Downloads", root)},
	})
	for _, failure := range batch.failures {
		items = append(items, api.Item{
			ID:         "failed:" + failure.row.name,
			Title:      failure.row.name,
			Subtitle:   failure.reason,
			Icon:       "circle-alert",
			Appearance: &api.Appearance{Foreground: api.ColorRed},
			Primary:    api.Primary(api.RevealPath(revealLabel, root+"/"+failure.row.name)),
		})
	}
	view := api.ListView(title, items...)
	view.Subtitle = fmt.Sprintf("%d of %d moved · %s", moved, total, originals.status)
	view.ContentSizing = "fit"
	view.EmptyView = &api.EmptyState{Title: "Nothing moved", Subtitle: emptySubtitle(batch.failures)}
	view.Actions = []api.Action{
		api.Run(actionOrganizeAgain, "Organize Again", nil),
		api.RevealPath("Reveal ~/Downloads", root),
		api.OpenPath("Open categories/", root+"/categories"),
	}
	return view
}

func movedCategoryItems(root string, movedByCategory map[string][]planRow) []api.Item {
	categories := make([]string, 0, len(movedByCategory))
	for category := range movedByCategory {
		categories = append(categories, category)
	}
	sort.SliceStable(categories, func(i, j int) bool {
		countI, countJ := len(movedByCategory[categories[i]]), len(movedByCategory[categories[j]])
		if countI != countJ {
			return countI > countJ
		}
		return lessFold(categories[i], categories[j])
	})
	var items []api.Item
	for _, category := range categories {
		rows := movedByCategory[category]
		names := make([]string, 0, len(rows))
		for _, row := range rows {
			names = append(names, row.name)
		}
		items = append(items, api.Item{
			ID:          "done:" + category,
			Title:       category,
			Subtitle:    fmt.Sprintf("%s moved · categories/%s", plural(len(rows), "item"), category),
			Icon:        categoryIconOr(category, "folder"),
			Accessories: []api.Accessory{{Text: strconv.Itoa(len(rows)), Tone: api.ToneSuccess}},
			Primary:     api.Primary(api.OpenPath("Open "+category, root+"/categories/"+category)),
			Detail: &api.Detail{
				Text:     strings.Join(names, "\n"),
				Metadata: []api.Metadata{{Kind: api.MetadataText, Label: "Folder", Value: "categories/" + category, Copyable: true}},
			},
		})
	}
	return items
}

func ensureOriginals(ctx api.Context, scan scanResult) (originalsOutcome, error) {
	if scan.hasOriginals {
		return originalsOutcome{
			status: "originals/ left untouched",
			detail: "The flat symlink folder already exists, so this run did not modify it.",
		}, nil
	}
	result, err := ctx.Desktop().Shell().Script(originalsScript, api.ShellOptions{TimeoutMs: 20000})
	if err != nil {
		return originalsOutcome{}, err
	}
	if result.ExitCode != 0 {
		return originalsOutcome{
			status: "originals/ was not created",
			detail: firstNonEmpty(strings.TrimSpace(result.Stderr), "The symlink step failed."),
		}, nil
	}
	created := firstCapture(createdCount, result.Stdout)
	total := firstCapture(totalCount, result.Stdout)
	return originalsOutcome{
		status: fmt.Sprintf("originals/ created with %s new symlink%s", created, pluralSuffix(created)),
		detail: fmt.Sprintf("%s symlink%s now point into categories/ using absolute paths.", total, pluralSuffix(total)),
	}, nil
}

func scanDownloads(ctx api.Context) (scanResult, error) {
	result, err := ctx.Desktop().Shell().Script(scanScript, api.ShellOptions{TimeoutMs: 15000})
	if err != nil {
		return scanResult{}, err
	}
	if result.ExitCode != 0 {
		if stderr := strings.TrimSpace(result.Stderr); stderr != "" {
			return scanResult{}, fmt.Errorf("Could not read ~/Downloads: %s", stderr)
		}
		return scanResult{}, errors.New("Could not read ~/Downloads.")
	}
	return parseScan(result.Stdout)
}

func parseScan(output string) (scanResult, error) {
	lines := strings.Split(output, "\n")
	rootPath := strings.TrimSpace(lines[0])
	if rootPath == "" {
		return scanResult{}, errors.New("Could not resolve the Downloads folder path.")
	}
	scan := scanResult{rootPath: rootPath}
	section := ""
	for _, line := range lines[1:] {
		trimmed := strings.TrimSpace(line)
		switch trimmed {
		case "---ENTRIES---":
			section = "entries"
			continue
		case "---CATEGORIES---":
			section = "categories"
			continue
		case "---ORIGINALS---":
			section = "originals"
			continue
		}
		if trimmed == "" {
			continue
		}
		switch section {
		case "entries":
			scan.entries = appendEntry(scan.entries, line)
		case "categories":
			scan.categories = append(scan.categories, trimmed)
		case "originals":
			scan.hasOriginals = trimmed == "yes"
		}
	}
	scan.entries = visibleEntries(scan.entries)
	return scan, nil
}

func appendEntry(entries []entry, line string) []entry {
	fields := strings.Split(line, "\t")
	if len(fields) < 2 || fields[1] == "" {
		return entries
	}
	size := int64(0)
	if len(fields) > 2 {
		size, _ = strconv.ParseInt(fields[2], 10, 64)
	}
	return append(entries, entry{kind: fields[0], name: fields[1], size: size})
}

func visibleEntries(entries []entry) []entry {
	var visible []entry
	for _, candidate := range entries {
		if strings.HasPrefix(candidate.name, ".") || candidate.name == "categories" || candidate.name == "originals" {
			continue
		}
		visible = append(visible, candidate)
	}
	return visible
}
