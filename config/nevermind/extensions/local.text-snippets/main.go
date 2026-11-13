package main

import (
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	storageKey      = "snippets-v1"
	listID          = "snippets"
	addAction       = "add"
	copyActionID    = "copy"
	pasteActionID   = "paste"
	viewActionID    = "view"
	editActionID    = "edit"
	editReplaceID   = "edit-replace"
	saveActionID    = "save"
	deleteActionID  = "delete"
	copyIndicatorID = "snippet-copied"
	placeholderText = "Write the text you want to save…"
)

type snippet struct {
	ID        string `json:"id"`
	Text      string `json:"text"`
	UpdatedAt int64  `json:"updatedAt"`
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       listID,
		Title:    "Snippets",
		Subtitle: "Add, copy, edit, and delete saved text",
		Icon:     "text",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case listID:
		return listResult(ctx, api.NavPush)
	case addAction:
		return api.Result{View: editorViewFor(snippet{}, true), Navigation: api.NavPush}, nil
	case copyActionID:
		return api.Result{}, copySnippet(ctx, in.Ref.Args["id"])
	case pasteActionID:
		return pasteResult(ctx, in.Ref.Args["id"])
	case viewActionID:
		return viewResult(ctx, in.Ref.Args["id"])
	case editActionID:
		return editResult(ctx, in.Ref.Args["id"], api.NavPush)
	case editReplaceID:
		return editResult(ctx, in.Ref.Args["id"], api.NavReplace)
	case saveActionID:
		return saveSnippet(ctx, in)
	case deleteActionID:
		return deleteSnippet(ctx, in.Ref.Args["id"])
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func readSnippets(ctx api.Context) ([]snippet, error) {
	var items []snippet
	if _, err := ctx.Storage().Get(storageKey, &items); err != nil {
		return nil, errors.New("Saved snippets could not be read. Your stored data has not been changed.")
	}
	return items, nil
}

func findSnippet(ctx api.Context, id string) (snippet, error) {
	items, err := readSnippets(ctx)
	if err != nil {
		return snippet{}, err
	}
	index := indexOfSnippet(items, id)
	if index < 0 {
		return snippet{}, errors.New("This snippet no longer exists. Reopen Snippets to refresh the list.")
	}
	return items[index], nil
}

func indexOfSnippet(items []snippet, id string) int {
	for index, item := range items {
		if item.ID == id {
			return index
		}
	}
	return -1
}

func listResult(ctx api.Context, navigation api.NavigationMode) (api.Result, error) {
	view, err := listView(ctx)
	if err != nil {
		return api.Result{}, err
	}
	return api.Result{View: &view, Navigation: navigation}, nil
}

func listView(ctx api.Context) (api.View, error) {
	items, err := readSnippets(ctx)
	if err != nil {
		return api.View{}, err
	}
	sort.SliceStable(items, func(i, j int) bool { return items[i].UpdatedAt > items[j].UpdatedAt })
	rows := make([]api.Item, 0, len(items))
	for _, item := range items {
		rows = append(rows, snippetRow(item))
	}
	view := api.ListView("Snippets", rows...)
	view.ID = listID
	view.Placeholder = "Search saved text…"
	view.EmptyView = &api.EmptyState{Title: "No snippets yet", Subtitle: "Add a snippet to save a piece of text."}
	view.ActionPanel = api.Panel(api.Section("Snippets", api.Run(addAction, "Add Snippet", nil)))
	return view, nil
}

func snippetRow(item snippet) api.Item {
	id := map[string]string{"id": item.ID}
	edit := api.Run(editActionID, "Edit Snippet", id)
	edit.Shortcut = "Command+E"
	remove := api.WithConfirmation(api.Destructive(api.Run(deleteActionID, "Delete Snippet", id)), api.Confirmation{
		Message:      fmt.Sprintf("Delete “%s”?", snippetTitle(item.Text)),
		ConfirmLabel: "Delete",
		Destructive:  true,
	})
	remove.Shortcut = "Command+Backspace"
	return api.Item{
		ID:       item.ID,
		Title:    snippetTitle(item.Text),
		Subtitle: snippetSubtitle(item.Text),
		Keywords: []string{item.Text},
		Icon:     "text",
		Primary:  api.Primary(copyRun(item.ID)),
		Actions: []api.Action{
			api.Run(viewActionID, "View Snippet", id),
			edit,
			api.Run(pasteActionID, "Paste Snippet", id),
			remove,
		},
	}
}

func snippetTitle(text string) string {
	for _, line := range strings.Split(text, "\n") {
		if trimmed := strings.TrimSpace(line); trimmed != "" {
			return firstRunes(trimmed, 80)
		}
	}
	return "Untitled Snippet"
}

func snippetSubtitle(text string) string {
	return firstRunes(strings.Join(strings.Fields(text), " "), 160)
}

func firstRunes(text string, limit int) string {
	runes := []rune(text)
	if len(runes) <= limit {
		return text
	}
	return string(runes[:limit])
}

func editorViewFor(current snippet, isNew bool) *api.View {
	title := "Edit Snippet"
	args := map[string]string{"id": current.ID, "updatedAt": strconv.FormatInt(current.UpdatedAt, 10)}
	if isNew {
		title = "New Snippet"
		args = map[string]string{}
	}
	submit := api.Run(saveActionID, "Save Snippet", args)
	submit.Shortcut = "Command+Enter"
	view := api.View{
		Kind:  api.ViewEditor,
		Title: title,
		Editor: &api.EditorSpec{
			Content:     current.Text,
			Format:      "text",
			Placeholder: placeholderText,
			Submit:      &submit,
		},
	}
	return &view
}

func readOnlyViewFor(current snippet) api.View {
	view := api.View{
		Kind:   api.ViewEditor,
		Title:  snippetTitle(current.Text),
		Editor: &api.EditorSpec{Content: current.Text, Format: "text", ReadOnly: true},
	}
	view.Actions = []api.Action{
		copyRun(current.ID),
		concealedPaste(current.Text),
		api.Run(editReplaceID, "Edit Snippet", map[string]string{"id": current.ID}),
	}
	return view
}

func copyRun(id string) api.Action {
	action := api.Run(copyActionID, "Copy Snippet", map[string]string{"id": id})
	action.Background = true
	return action
}

func concealedPaste(text string) api.Action {
	action := api.PasteText("Paste Snippet", text)
	action.Paste = &api.PasteOptions{RestoreClipboard: true, Concealed: true}
	return action
}

func copySnippet(ctx api.Context, id string) error {
	current, err := findSnippet(ctx, id)
	if err != nil {
		return err
	}
	if err := ctx.Desktop().Clipboard().WriteText(current.Text, false); err != nil {
		return err
	}
	_ = ctx.Indicators().Show(api.IndicatorInput{ID: copyIndicatorID, Title: "Copied", Status: api.IndicatorSuccess, DurationMs: 1500})
	return nil
}

func pasteResult(ctx api.Context, id string) (api.Result, error) {
	current, err := findSnippet(ctx, id)
	if err != nil {
		return api.Result{}, err
	}
	next := concealedPaste(current.Text)
	return api.Result{Next: &next}, nil
}

func viewResult(ctx api.Context, id string) (api.Result, error) {
	current, err := findSnippet(ctx, id)
	if err != nil {
		return api.Result{}, err
	}
	view := readOnlyViewFor(current)
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func editResult(ctx api.Context, id string, navigation api.NavigationMode) (api.Result, error) {
	current, err := findSnippet(ctx, id)
	if err != nil {
		return api.Result{}, err
	}
	return api.Result{View: editorViewFor(current, false), Navigation: navigation}, nil
}

func saveSnippet(ctx api.Context, in api.Invocation) (api.Result, error) {
	text := in.EditorContent
	if strings.TrimSpace(text) == "" {
		return api.Result{}, errors.New("Enter some text before saving the snippet.")
	}
	items, err := readSnippets(ctx)
	if err != nil {
		return api.Result{}, err
	}
	saved := snippet{ID: in.Ref.Args["id"], Text: text, UpdatedAt: ctx.Clock().Now().UnixMilli()}
	if saved.ID == "" {
		generated, err := ctx.Text().Template("{uuid}", api.TemplateOptions{})
		if err != nil {
			return api.Result{}, err
		}
		saved.ID = generated.Text
		items = append(items, saved)
	} else {
		index := indexOfSnippet(items, saved.ID)
		if index < 0 {
			return api.Result{}, errors.New("This snippet was deleted and cannot be updated.")
		}
		if strconv.FormatInt(items[index].UpdatedAt, 10) != in.Ref.Args["updatedAt"] {
			return api.Result{}, errors.New("This snippet changed since you opened it. Reopen it before saving to avoid overwriting newer text.")
		}
		items[index] = saved
	}
	if err := ctx.Storage().Set(storageKey, items); err != nil {
		return api.Result{}, err
	}
	return listResult(ctx, api.NavRoot)
}

func deleteSnippet(ctx api.Context, id string) (api.Result, error) {
	items, err := readSnippets(ctx)
	if err != nil {
		return api.Result{}, err
	}
	kept := make([]snippet, 0, len(items))
	for _, item := range items {
		if item.ID != id {
			kept = append(kept, item)
		}
	}
	if err := ctx.Storage().Set(storageKey, kept); err != nil {
		return api.Result{}, err
	}
	return listResult(ctx, api.NavReplace)
}
