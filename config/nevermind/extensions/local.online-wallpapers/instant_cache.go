package main

import (
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func loaderForState(state browseState) string {
	return fmt.Sprintf("browse-v1|%s|%s|%d", state.feed, url.QueryEscape(state.query), state.page)
}

func stateFromLoader(loader string) (browseState, bool) {
	parts := strings.SplitN(loader, "|", 4)
	if len(parts) != 4 || parts[0] != "browse-v1" {
		return browseState{}, false
	}
	query, _ := url.QueryUnescape(parts[2])
	feed := parts[1]
	if feed == "" {
		feed = "top"
	}
	return browseState{feed: feed, query: query, page: parsePage(parts[3])}, true
}

func cachedListing(ctx api.Context, state browseState) (wallhavenListing, bool) {
	var out wallhavenListing
	found, err := ctx.Storage().Get(listingKey(state), &out)
	if err != nil || !found || len(out.Data) == 0 {
		return wallhavenListing{}, false
	}
	return out, true
}

func gridViewFromListing(state browseState, data []wallpaper, lastPage int) api.View {
	if lastPage < 1 {
		lastPage = 1
	}
	common := browseActions(state, lastPage)
	var items []api.Item
	for _, candidate := range data {
		items = append(items, wallpaperItem(candidate, state, common))
	}
	view := api.GridView(gridTitle(state), 3, items...)
	view.ID = gridID
	view.Size = api.SizeLarge
	view.Grid = &api.GridSpec{Columns: 3, Layout: "wide", AspectRatio: "16/9"}
	view.Subtitle = fmt.Sprintf("Wallhaven \u00b7 %s \u00b7 Landscape \u00b7 1080p+ \u00b7 Page %d/%d", sourceLabel(state), state.page, lastPage)
	view.Placeholder = "Filter this page\u2026 \u00b7 Use Search Online Wallpapers for a new search"
	view.EmptyView = &api.EmptyState{Title: "No matching wallpapers", Subtitle: "Try another category or use Search Online Wallpapers."}
	view.Filter = collectionAccessory(state)
	view.Actions = common
	return view
}

func emptyGridShell(state browseState) api.View {
	view := api.GridView(gridTitle(state), 3)
	view.ID = gridID
	view.Size = api.SizeLarge
	view.Grid = &api.GridSpec{Columns: 3, Layout: "wide", AspectRatio: "16/9"}
	view.Subtitle = fmt.Sprintf("Wallhaven \u00b7 %s \u00b7 Loading\u2026", sourceLabel(state))
	view.Placeholder = "Loading wallpapers\u2026"
	view.IsLoading = true
	view.Filter = collectionAccessory(state)
	view.Actions = browseActions(state, state.page)
	return view
}

func attachSource(ctx api.Context, view *api.View, state browseState) {
	ds := ctx.Data().StaleWhileRevalidate(loaderForState(state), "listing-items-v1:"+state.feed+":"+state.query+":"+strconv.Itoa(state.page), 30*time.Minute, 24*time.Hour, true)
	view.Source = &ds
}

func LoadItems(ctx api.Context, loader string) ([]api.Item, error) {
	state, ok := stateFromLoader(loader)
	if !ok {
		return nil, fmt.Errorf("unknown loader %q", loader)
	}
	result, err := listing(ctx, state)
	if err != nil {
		return nil, err
	}
	lastPage := result.LastPage
	if lastPage < 1 {
		lastPage = 1
	}
	common := browseActions(state, lastPage)
	items := make([]api.Item, 0, len(result.Data))
	for _, candidate := range result.Data {
		items = append(items, wallpaperItem(candidate, state, common))
	}
	return items, nil
}
