package main

import (
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       "lookup",
		Title:    "Look Up Shortcut",
		Subtitle: "Find what Alt+T and other keys do",
		Aliases:  []string{"alt t", "alt+t"},
		Keywords: []string{"shortcut", "hotkey", "keybind", "accelerator", "keys", "alt"},
		Icon:     "keyboard",
		Actions:  []api.Action{api.Run("lookup", "Show shortcuts", nil)},
	}}, nil
}

func SearchItems(ctx api.Context, query string) ([]api.Item, error) {
	q := strings.TrimSpace(query)
	if q == "" {
		return nil, nil
	}
	if !isShortcutQuery(q) {
		return nil, nil
	}
	clean := cleanQuery(q)
	recs := allShortcuts(ctx)
	if len(recs) == 0 {
		return nil, nil
	}
	if clean == "" {
		return itemsFor(recs, 15), nil
	}
	matched := matchShortcuts(recs, clean)
	if len(matched) == 0 {
		again := api.Run("lookup", "Show all shortcuts", nil)
		return []api.Item{{
			ID:       "no-match",
			Title:    "No shortcut matches " + strings.TrimSpace(q),
			Subtitle: "Press Enter to see all shortcuts",
			Icon:     "keyboard",
			Primary:  &again,
		}}, nil
	}
	return itemsFor(matched, 15), nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	if in.Ref.ID == "lookup" {
		recs := allShortcuts(ctx)
		items := itemsFor(recs, 50)
		if len(items) == 0 {
			items = []api.Item{{ID: "empty", Title: "No shortcuts yet", Subtitle: "Assign one in Settings", Icon: "keyboard"}}
		}
		v := api.ListView("Shortcuts", items...)
		return ctx.Navigation().Push(&v), nil
	}
	return api.Result{}, nil
}

func allShortcuts(ctx api.Context) []api.ShortcutRecord {
	var out []api.ShortcutRecord
	pal := ctx.Shortcuts().Palette()
	if pal.ActionID != "" || pal.Accelerator != "" || pal.Title != "" {
		out = append(out, pal)
	}
	seen := map[string]bool{}
	for _, r := range out {
		seen[r.ActionID+"|"+r.Accelerator] = true
	}
	for _, r := range ctx.Shortcuts().List() {
		k := r.ActionID + "|" + r.Accelerator
		if seen[k] {
			continue
		}
		seen[k] = true
		out = append(out, r)
	}
	return out
}

func itemFor(r api.ShortcutRecord) api.Item {
	title := r.Title
	if title == "" {
		title = r.Label
	}
	if title == "" {
		title = r.ActionID
	}
	if title == "" {
		title = r.Accelerator
	}
	// shown is the shortcut as Nevermind displays it (symbols, Hyper); Accelerator is only the stored form.
	shown := r.Label
	if shown == "" {
		shown = r.Accelerator
	}
	sub := shown
	if r.Subtitle != "" && r.Accelerator != "" {
		sub = shown + " — " + r.Subtitle
	} else if r.Subtitle != "" {
		sub = r.Subtitle
	} else if r.Scope != "" && r.Accelerator != "" {
		sub = shown + " • " + r.Scope
	}
	copyText := r.Accelerator
	if copyText == "" {
		copyText = title
	}
	it := api.Item{
		ID:       r.ActionID,
		Title:    title,
		Subtitle: sub,
		Icon:     "keyboard",
		Keywords: []string{r.Accelerator, r.Label, r.Scope, r.Source},
		Primary:  api.Primary(api.CopyText("Copy shortcut", copyText, false)),
	}
	if it.ID == "" {
		it.ID = "sc-" + norm(r.Accelerator+" "+title)
	}
	if r.Accelerator != "" {
		it.Accessories = []api.Accessory{{Text: shown, Icon: "keyboard"}}
	}
	return it
}

func itemsFor(recs []api.ShortcutRecord, limit int) []api.Item {
	out := make([]api.Item, 0, limit)
	for _, r := range recs {
		if len(out) >= limit {
			break
		}
		if r.Title == "" && r.Label == "" && r.ActionID == "" && r.Accelerator == "" {
			continue
		}
		out = append(out, itemFor(r))
	}
	return out
}

func matchShortcuts(recs []api.ShortcutRecord, clean string) []api.ShortcutRecord {
	cn := norm(clean)
	if cn == "" {
		return recs
	}
	parts := strings.Fields(cn)
	var accMatch []api.ShortcutRecord
	var textMatch []api.ShortcutRecord
	for _, r := range recs {
		an := norm(r.Accelerator)
		if an != "" && accelContains(an, cn, parts) {
			accMatch = append(accMatch, r)
			continue
		}
		hay := norm(r.Title + " " + r.Label + " " + r.ActionID + " " + r.Subtitle)
		if hay != "" && containsAll(hay, parts) {
			textMatch = append(textMatch, r)
		}
	}
	if len(accMatch) > 0 {
		return accMatch
	}
	return textMatch
}

func accelContains(an, cn string, parts []string) bool {
	if strings.Contains(an, cn) {
		return true
	}
	return containsAll(an, parts)
}

func containsAll(hay string, parts []string) bool {
	for _, p := range parts {
		if !strings.Contains(hay, p) {
			return false
		}
	}
	return true
}

func norm(s string) string {
	s = strings.ToLower(s)
	s = strings.ReplaceAll(s, "+", " ")
	s = strings.ReplaceAll(s, ",", " ")
	f := strings.Fields(s)
	return strings.Join(f, " ")
}

func isShortcutQuery(q string) bool {
	l := strings.ToLower(strings.TrimSpace(q))
	if l == "" {
		return false
	}
	if strings.Contains(l, "shortcut") || strings.Contains(l, "hotkey") || strings.Contains(l, "hot key") || strings.Contains(l, "keybind") || strings.Contains(l, "accelerator") {
		return true
	}
	n := norm(l)
	words := strings.Fields(n)
	for _, w := range words {
		if w == "alt" || w == "ctrl" || w == "control" || w == "cmd" || w == "command" || w == "shift" || w == "option" || w == "meta" {
			return true
		}
	}
	if strings.Contains(l, "+") {
		for _, w := range words {
			if w == "alt" || w == "ctrl" || w == "control" || w == "cmd" || w == "shift" || w == "option" {
				return true
			}
		}
	}
	return false
}

func cleanQuery(q string) string {
	filler := map[string]bool{
		"shortcut": true, "shortcuts": true, "hotkey": true, "hotkeys": true,
		"hot": true, "key": true, "keys": true, "keybind": true, "keybinds": true,
		"accelerator": true, "lookup": true, "look": true, "up": true, "find": true,
		"show": true, "what": true, "is": true, "does": true, "do": true,
		"for": true, "the": true, "my": true, "bound": true, "to": true, "a": true,
	}
	n := norm(q)
	words := strings.Fields(n)
	kept := make([]string, 0, len(words))
	for _, w := range words {
		if !filler[w] {
			kept = append(kept, w)
		}
	}
	return strings.Join(kept, " ")
}
