package main

import (
	"errors"
	"fmt"
	"net/url"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func listingParams(state browseState) url.Values {
	query := state.query
	if query == "" {
		query = feedSearchTerms[state.feed]
	}
	sorting, topRange := "toplist", "1M"
	if state.query != "" {
		sorting = "relevance"
	}
	if state.feed == "year" {
		topRange = "1y"
	}
	params := url.Values{
		"categories": {"100"},
		"purity":     {"100"},
		"sorting":    {sorting},
		"topRange":   {topRange},
		"atleast":    {"1920x1080"},
		"ratios":     {"16x9,16x10,21x9"},
		"order":      {"desc"},
		"page":       {strconv.Itoa(state.page)},
	}
	if query != "" {
		params.Set("q", query)
	}
	return params
}

func isLandscapeSFW(candidate wallpaper) bool {
	return idPattern.MatchString(candidate.ID) && candidate.Purity == "sfw" &&
		candidate.DimensionX >= 1920 && candidate.DimensionY >= 1080 &&
		candidate.DimensionX > candidate.DimensionY &&
		(candidate.FileType == "image/jpeg" || candidate.FileType == "image/png")
}

func checkWallpaperURLs(candidate wallpaper) error {
	if _, err := checkedURL(candidate.Path, "image"); err != nil {
		return err
	}
	if _, err := checkedURL(candidate.Thumbs.Large, "thumb"); err != nil {
		return err
	}
	_, err := checkedURL(candidate.URL, "page")
	return err
}

func checkedURL(value, kind string) (string, error) {
	hosts := map[string]string{"image": "w.wallhaven.cc", "thumb": "th.wallhaven.cc", "page": "wallhaven.cc"}
	parsed, err := url.Parse(value)
	if err != nil || parsed.Scheme != "https" || parsed.Hostname() != hosts[kind] || parsed.User != nil || parsed.Port() != "" {
		return "", errors.New("Wallhaven returned an unexpected URL.")
	}
	return parsed.String(), nil
}

func browseView(ctx api.Context, state browseState) (api.View, error) {
	result, err := listing(ctx, state)
	if err != nil {
		return api.View{}, err
	}
	lastPage := result.LastPage
	if lastPage < 1 {
		lastPage = 1
	}
	common := browseActions(state, result.LastPage)
	var items []api.Item
	for _, candidate := range result.Data {
		items = append(items, wallpaperItem(candidate, state, common))
	}
	view := api.GridView(gridTitle(state), 3, items...)
	view.ID = gridID
	view.Size = api.SizeLarge
	view.Grid = &api.GridSpec{Columns: 3, Layout: "wide", AspectRatio: "16/9"}
	view.Subtitle = fmt.Sprintf("Wallhaven · %s · Landscape · 1080p+ · Page %d/%d", sourceLabel(state), state.page, lastPage)
	view.Placeholder = "Filter this page… · Use Search Online Wallpapers for a new search"
	view.EmptyView = &api.EmptyState{Title: "No matching wallpapers", Subtitle: "Try another category or use Search Online Wallpapers."}
	view.Filter = collectionAccessory(state)
	view.Actions = common
	return view, nil
}

func gridTitle(state browseState) string {
	if state.query != "" {
		return "Wallpapers: " + state.query
	}
	return "Online Wallpapers"
}

func sourceLabel(state browseState) string {
	if state.query != "" {
		return "Search results"
	}
	for _, candidate := range feeds {
		if candidate.value == state.feed {
			return candidate.title
		}
	}
	return ""
}

func collectionAccessory(state browseState) *api.ViewFilter {
	value := state.feed
	var options []api.ViewFilterOption
	if state.query != "" {
		value = "search"
		options = append(options, api.ViewFilterOption{Title: "Search results", Value: "search"})
	}
	for _, candidate := range feeds {
		options = append(options, api.ViewFilterOption{Title: candidate.title, Value: candidate.value})
	}
	return &api.ViewFilter{Value: value, Options: options, OnChange: &api.ActionRef{ID: actionChangeFeed}}
}

func browseActions(state browseState, lastPage int) []api.Action {
	var actions []api.Action
	if state.page > 1 {
		previous := state
		previous.page--
		prev := api.Run(actionBrowsePage, "Previous Page", previous.args())
		prev.Shortcut = "Control+P"
		actions = append(actions, prev)
	}
	if state.page < lastPage {
		next := state
		next.page++
		following := api.Run(actionBrowsePage, "Next Page", next.args())
		following.Shortcut = "Control+N"
		actions = append(actions, following)
	}
	return append(actions,
		api.Run(commandSearch, "Search Online Wallpapers", nil),
		api.Run(actionRefresh, "Refresh Results", state.args()),
		api.Run(actionOpenFolder, "Open Download Folder", nil),
		api.Run(commandRestoreColors, "Restore Online Wallpaper Colors", nil),
	)
}

func changeFeed(ctx api.Context, value string) (api.Result, error) {
	feedName := value
	if feedName == "" {
		feedName = "top"
	}
	if feedName == "search" {
		return api.Result{}, nil
	}
	view, err := browseView(ctx, browseState{feed: feedName, page: 1})
	if err != nil {
		return api.Result{}, err
	}
	return api.Result{View: &view, Navigation: api.NavReplace}, nil
}

func wallpaperItem(candidate wallpaper, state browseState, common []api.Action) api.Item {
	ref := wallpaperArgs(state, candidate.ID)
	return api.Item{
		ID:       candidate.ID,
		Title:    "Wallhaven · " + candidate.ID,
		Subtitle: fmt.Sprintf("%s · ♥ %d", candidate.Resolution, candidate.Favorites),
		Image:    &api.Image{Src: thumbnailURL(candidate)},
		Keywords: []string{candidate.ID, candidate.Resolution},
		Primary:  api.Primary(applyAction("Set Wallpaper & Match Colors", "colors", ref, "image")),
		Actions: append([]api.Action{
			applyAction("Set Wallpaper Only", "only", ref, ""),
			api.Run(actionPreview, "Preview Wallpaper", ref),
			applyAction("Preview Matching Colors", "palette", ref, ""),
			applyAction("Download Only", "save", ref, ""),
			api.OpenURL("View on Wallhaven", candidate.URL),
		}, common...),
	}
}

func thumbnailURL(candidate wallpaper) string {
	value, _ := checkedURL(candidate.Thumbs.Large, "thumb")
	return value
}

func wallpaperArgs(state browseState, id string) map[string]string {
	args := state.args()
	args["id"] = id
	return args
}

func applyAction(title, mode string, ref map[string]string, icon string) api.Action {
	args := make(map[string]string, len(ref)+1)
	for key, value := range ref {
		args[key] = value
	}
	args["mode"] = mode
	action := api.Run(actionApply, title, args)
	action.Icon = icon
	return action
}

func searchPrompt(ctx api.Context) api.Action {
	return ctx.Input().Prompt(api.PromptSpec{
		Title:   "Search Online Wallpapers",
		Message: "Landscape wallpapers only · SFW · at least 1920×1080",
		Fields: []api.Field{{
			ID:          "query",
			Label:       "Search wallpapers",
			Type:        api.FieldText,
			Placeholder: "mountains, forest, space…",
			Required:    true,
		}},
		Action: api.Run(actionSearchSubmit, "Search", nil),
	})
}

func searchSubmit(ctx api.Context, form api.FormValues) (api.Result, error) {
	query := strings.TrimSpace(form["query"].Text)
	if runes := []rune(query); len(runes) > 200 {
		query = string(runes[:200])
	}
	if query == "" {
		return api.Result{}, errors.New("Enter a search term.")
	}
	view, err := browseView(ctx, browseState{feed: "top", query: query, page: 1})
	if err != nil {
		return api.Result{}, err
	}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func openDownloadFolder(ctx api.Context) (api.Result, error) {
	directory, err := wallpaperDirectory(ctx)
	if err != nil {
		return api.Result{}, err
	}
	if _, err := ctx.Desktop().Shell().Exec("/bin/mkdir", []string{"-p", directory}, api.ShellOptions{}); err != nil {
		return api.Result{}, err
	}
	open := api.OpenPath("Open", directory)
	return api.Result{Next: &open}, nil
}

func wallpaperDirectory(ctx api.Context) (string, error) {
	result, err := ctx.Desktop().Shell().Script(`printf '%s' "$HOME"`, api.ShellOptions{})
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(result.Stdout) + "/.config/wallpapers", nil
}

func applyFromArgs(ctx api.Context, args map[string]string) (api.Result, error) {
	return withLock(func() (api.Result, error) {
		candidate, err := lookupWallpaper(ctx, args)
		if err != nil {
			return api.Result{}, err
		}
		return runWallpaperMode(ctx, candidate, args)
	})
}

func previewWallpaper(ctx api.Context, args map[string]string) (api.Result, error) {
	candidate, err := lookupWallpaper(ctx, args)
	if err != nil {
		return api.Result{}, err
	}
	ref := wallpaperArgs(stateFromArgs(args), candidate.ID)
	view := api.View{
		Kind:    api.ViewPreview,
		Title:   "Wallhaven · " + candidate.ID,
		Preview: &api.PreviewSpec{Image: &api.Image{Src: candidate.Path}, Text: candidate.Resolution + " · Full-resolution preview from Wallhaven"},
		Actions: []api.Action{
			applyAction("Set Wallpaper & Match Colors", "colors", ref, ""),
			applyAction("Set Wallpaper Only", "only", ref, ""),
			api.OpenURL("View on Wallhaven", candidate.URL),
		},
	}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}
