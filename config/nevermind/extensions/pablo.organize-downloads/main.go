package main

import (
	"fmt"
	"regexp"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	extensionID         = "pablo.organize-downloads"
	commandOrganize     = "organize-downloads"
	actionRescan        = "rescan"
	actionOrganizeAgain = "organize-again"
	actionMoveFiles     = "move-files"
	moveProgressID      = "pablo.organize-downloads.move-progress"
	scanScript          = `cd "$HOME/Downloads" || exit 1
pwd -P
echo '---ENTRIES---'
find . -mindepth 1 -maxdepth 1 -exec sh -c '
  for f; do
    if [ -L "$f" ]; then t=link
    elif [ -d "$f" ]; then t=dir
    elif [ -f "$f" ]; then t=file
    else t=other; fi
    s=$(stat -f%z "$f" 2>/dev/null || echo 0)
    printf "%s\t%s\t%s\n" "$t" "${f#./}" "$s"
  done' _ {} +
echo '---CATEGORIES---'
find categories -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's|^categories/||' | sort
echo '---ORIGINALS---'
if [ -d originals ]; then echo yes; else echo no; fi
`
	originalsScript = `cd "$HOME/Downloads" || exit 1
mkdir -p originals
created=0
while IFS= read -r -d '' f; do
  name=$(basename "$f")
  if [ -e "originals/$name" ] || [ -L "originals/$name" ]; then continue; fi
  ln -s "$HOME/Downloads/$f" "originals/$name" && created=$((created + 1))
done < <(find categories -type f -print0 2>/dev/null)
total=$(find originals -mindepth 1 -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
echo "CREATED=$created"
echo "TOTAL=$total"
`
	alreadyOrganizedMarkdown = "Nothing to move: there are no loose files or folders left in the `~/Downloads` root.\n\n- `categories/` holds the organized files\n- `originals/` is never modified once it exists"
)

var (
	sensitivePattern = regexp.MustCompile(`(?i)client_secret|credential|password|passwd|secret|\.p12$|\.pem$|\.key$`)
	installLike      = regexp.MustCompile(`install|setup`)
	nonAlphanumeric  = regexp.MustCompile(`[^a-z0-9]`)
	createdCount     = regexp.MustCompile(`CREATED=(\d+)`)
	totalCount       = regexp.MustCompile(`TOTAL=(\d+)`)
)

var categoryIcons = map[string]string{
	"3D Models":               "shapes",
	"Archives":                "file-archive",
	"Credentials & Sensitive": "key-round",
	"Data":                    "database",
	"Documents":               "file-text",
	"Installers":              "package-down",
	"Media":                   "image",
	"Misc":                    "box",
}

var categoryKeywords = map[string][]string{
	"3D Models":               {"3d"},
	"Credentials & Sensitive": {"credential", "sensitive", "security"},
	"Installers":              {"install"},
}

type extensionGroup struct {
	category   string
	extensions []string
}

var extensionGroups = []extensionGroup{
	{category: "Installers", extensions: []string{"dmg", "pkg", "iso", "exe", "msi", "app"}},
	{category: "3D Models", extensions: []string{"3mf", "stl", "obj", "step", "stp", "scad"}},
	{category: "Media", extensions: []string{
		"png", "jpg", "jpeg", "gif", "heic", "webp", "tiff", "bmp", "svg", "avif",
		"mp4", "mov", "mkv", "webm", "avi", "m4v",
		"mp3", "wav", "m4a", "flac", "aac", "aiff", "ogg",
	}},
	{category: "Documents", extensions: []string{
		"pdf", "md", "markdown", "txt", "rtf", "doc", "docx", "xls", "xlsx",
		"ppt", "pptx", "pages", "numbers", "keynote", "epub",
	}},
	{category: "Data", extensions: []string{
		"csv", "tsv", "xml", "har", "sqlite", "db", "json", "jsonl", "parquet",
		"log", "yaml", "yml", "plist", "gz", "tar", "tgz", "bz2", "xz",
	}},
	{category: "Archives", extensions: []string{"zip", "rar", "7z"}},
}

type entry struct {
	kind string
	name string
	size int64
}

type scanResult struct {
	rootPath     string
	entries      []entry
	categories   []string
	hasOriginals bool
}

type planRow struct {
	kind     string
	name     string
	size     int64
	category string
}

type moveFailure struct {
	row    planRow
	reason string
}

type originalsOutcome struct {
	status string
	detail string
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       commandOrganize,
		Title:    "Organize Downloads",
		Subtitle: "Review a category plan for ~/Downloads, then move the files",
		Aliases:  []string{"sort downloads", "tidy downloads", "clean up downloads"},
		Icon:     "folder-tree",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case commandOrganize:
		view, err := planView(ctx)
		if err != nil {
			return api.Result{}, err
		}
		return api.Result{View: &view, Navigation: api.NavPush}, nil
	case actionRescan, actionOrganizeAgain:
		view, err := planView(ctx)
		if err != nil {
			return api.Result{}, err
		}
		return api.Result{View: &view, Navigation: api.NavReplace}, nil
	case actionMoveFiles:
		return moveWithFailureReport(ctx)
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func planView(ctx api.Context) (api.View, error) {
	scan, err := scanDownloads(ctx)
	if err != nil {
		return api.View{}, err
	}
	rows := buildPlan(scan)
	if len(rows) == 0 {
		return api.PreviewView("Downloads already organized", alreadyOrganizedMarkdown), nil
	}
	return planListView(ctx, scan, rows), nil
}

func planListView(ctx api.Context, scan scanResult, rows []planRow) api.View {
	visible := true
	files := make([]api.Item, 0, len(rows))
	for _, row := range rows {
		files = append(files, planRowItem(ctx, scan.rootPath, row))
	}
	return api.View{
		Kind:         api.ViewList,
		Title:        "Organize Downloads",
		Subtitle:     fmt.Sprintf("%s in root · %d target %s", plural(len(rows), "item"), len(distinctCategories(rows)), categoryNoun(len(distinctCategories(rows)))),
		Presentation: api.PresentSidePreview,
		Detail:       &api.DetailPane{Visible: &visible},
		Sections: []api.ItemSection{
			{Title: "Plan", Items: []api.Item{planHeading(ctx, scan.rootPath, rows)}},
			{Title: "Files to move", Items: files},
		},
		EmptyView: &api.EmptyState{Title: "Nothing to organize"},
	}
}

func categoryNoun(count int) string {
	if count == 1 {
		return "category"
	}
	return "categories"
}

func planHeading(ctx api.Context, root string, rows []planRow) api.Item {
	moveAction := api.Run(actionMoveFiles, "Moving files…", nil)
	moveAction = api.WithConfirmation(moveAction, api.Confirmation{
		Title:        fmt.Sprintf("Move %s into categories/?", plural(len(rows), "item")),
		Message:      fmt.Sprintf("Plan: %s.\n\nFiles are moved, never deleted. Existing category folders are reused, and originals/ is left untouched.", summarizePlan(rows)),
		ConfirmLabel: "Move files",
	})
	return api.Item{
		ID:         "plan:move",
		Title:      fmt.Sprintf("Move %s into categories", plural(len(rows), "item")),
		Subtitle:   summarizePlan(rows),
		Icon:       "folder-tree",
		Appearance: &api.Appearance{Prominence: "primary"},
		Primary:    api.Primary(moveAction),
		Actions: []api.Action{
			api.Run(actionRescan, "Rescan Downloads", nil),
			api.RevealPath("Reveal ~/Downloads", root),
			api.OpenPath("Open categories/", root+"/categories"),
		},
	}
}

func planRowItem(ctx api.Context, root string, row planRow) api.Item {
	path := root + "/" + row.name
	icon := categoryIconOr(row.category, "file")
	accessory := formatBytes(row.size)
	kindLabel := row.kind
	if row.kind == "dir" || row.kind == "link" {
		icon = "folder"
	}
	if row.kind == "dir" {
		accessory = "folder"
		kindLabel = "folder"
	}
	return api.Item{
		ID:          "entry:" + row.name,
		Title:       row.name,
		Subtitle:    "→ categories/" + row.category,
		Icon:        icon,
		Accessories: []api.Accessory{{Text: accessory, Tone: api.ToneMuted}},
		Detail: &api.Detail{
			Text: row.name,
			Metadata: []api.Metadata{
				{Kind: api.MetadataText, Label: "Destination", Value: "categories/" + row.category, Copyable: true},
				{Kind: api.MetadataText, Label: "Source", Value: path, Copyable: true},
				{Kind: api.MetadataText, Label: "Type", Value: kindLabel},
				{Kind: api.MetadataText, Label: "Size", Value: formatBytes(row.size)},
			},
		},
		Primary: api.Primary(api.RevealPath(ctx.System().Labels().RevealInFileManager, path)),
		Actions: []api.Action{
			api.OpenPath("Open", path),
			api.CopyText("Copy Path", path, false),
		},
	}
}

func moveWithFailureReport(ctx api.Context) (api.Result, error) {
	result, err := moveFiles(ctx)
	if err != nil {
		reportMove(ctx, api.IndicatorInput{Title: "Downloads organization failed", Subtitle: err.Error(), Status: api.IndicatorError, DurationMs: 7000})
		return api.Result{}, err
	}
	return result, nil
}

func moveFiles(ctx api.Context) (api.Result, error) {
	scan, err := scanDownloads(ctx)
	if err != nil {
		return api.Result{}, err
	}
	rows := buildPlan(scan)
	if len(rows) == 0 {
		view := api.ListView("Nothing to organize")
		view.Subtitle = "The Downloads root is already clear."
		view.ContentSizing = "fit"
		view.EmptyView = &api.EmptyState{Title: "Nothing to move"}
		return api.Result{View: &view, Navigation: api.NavReplace}, nil
	}
	startMoveProgress(ctx, len(rows))
	batch, err := moveRows(ctx, scan, rows)
	if err != nil {
		return api.Result{}, err
	}
	originals, err := ensureOriginals(ctx, scan)
	if err != nil {
		return api.Result{}, err
	}
	return finishMoves(ctx, scan.rootPath, rows, batch, originals), nil
}
