package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	commandBrowse        = "browse"
	actionBrowsePage     = "browse-page"
	actionChangeFeed     = "change-collection"
	actionRefresh        = "refresh-results"
	actionOpenFolder     = "open-download-folder"
	actionApply          = "apply-wallpaper"
	actionPreview        = "preview-wallpaper"
	commandSearch        = "search"
	actionSearchSubmit   = "search-submit"
	commandRestoreColors = "restore-colors"
	indicatorID          = "online-wallpaper"
	backupKey            = "appearance-original-v1"
	maxDownloadBytes     = 60 * 1024 * 1024
	gridID               = "online-wallpapers-grid"
	jxaSampleScript      = `ObjC.import('AppKit');
function run(argv) {
 var image = $.NSImage.alloc.initWithContentsOfFile($(argv[0]));
 if (!image || image.isNil()) throw Error('Cannot decode wallpaper image');
 var bitmap = $.NSBitmapImageRep.imageRepWithData(image.TIFFRepresentation);
 if (!bitmap || bitmap.isNil()) throw Error('Cannot sample wallpaper image');
 var w = Number(bitmap.pixelsWide), h = Number(bitmap.pixelsHigh), samples = [];
 if (w < 1 || h < 1) throw Error('Wallpaper has no pixels');
 for (var y=0;y<40;y++) for (var x=0;x<40;x++) {
  var color = bitmap.colorAtXY(Math.min(w-1,Math.floor((x+0.5)*w/40)),Math.min(h-1,Math.floor((y+0.5)*h/40))).colorUsingColorSpace($.NSColorSpace.sRGBColorSpace);
  if (color && !color.isNil() && Number(color.alphaComponent)>0.5) samples.push([Number(color.redComponent),Number(color.greenComponent),Number(color.blueComponent)]);
 }
 return JSON.stringify(samples);
}`
)

var appearanceKeys = []string{"AppleHighlightColor", "AppleIconAppearanceTintColor", "AppleIconAppearanceCustomTintColor", "AppleIconAppearanceTheme"}

var feeds = []feed{
	{title: "Top this month", value: "top"},
	{title: "Nature & landscapes", value: "nature"},
	{title: "Minimal", value: "minimal"},
	{title: "Abstract", value: "abstract"},
	{title: "Top this year", value: "year"},
}

var feedSearchTerms = map[string]string{"nature": "nature", "minimal": "minimalism", "abstract": "abstract"}

var (
	idPattern         = regexp.MustCompile(`^[a-z0-9]{6}$`)
	downloadType      = regexp.MustCompile(`^image/(jpeg|png)(;|$)`)
	missingDefault    = regexp.MustCompile(`(?i)does not exist|could not find key|domain/default pair[^\n]*not found`)
	stringType        = regexp.MustCompile(`(?i)string`)
	noMatchingProcess = regexp.MustCompile(`(?i)no matching processes`)
	busyMu            sync.Mutex
	busy              bool
)

type feed struct {
	title string
	value string
}

type browseState struct {
	feed  string
	query string
	page  int
}

type wallpaper struct {
	ID         string `json:"id"`
	URL        string `json:"url"`
	Path       string `json:"path"`
	Resolution string `json:"resolution"`
	DimensionX int    `json:"dimension_x"`
	DimensionY int    `json:"dimension_y"`
	Purity     string `json:"purity"`
	FileType   string `json:"file_type"`
	FileSize   int64  `json:"file_size"`
	Favorites  int    `json:"favorites"`
	Thumbs     struct {
		Large string `json:"large"`
	} `json:"thumbs"`
}

type wallhavenListing struct {
	Data     []wallpaper `json:"data"`
	LastPage int         `json:"last_page"`
}

type rgb [3]float64

type palette struct {
	Tint       rgb  `json:"tint"`
	Highlight  rgb  `json:"highlight"`
	Monochrome bool `json:"monochrome"`
}

type colorBin struct {
	count int
	sum   rgb
}

type colorCluster struct {
	color rgb
	count int
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{
		{
			ID:       commandBrowse,
			Title:    "Online Wallpapers",
			Subtitle: "Browse top-rated landscape wallpapers · Wallhaven · No account needed",
			Aliases:  []string{"wallhaven", "online backgrounds", "download wallpaper"},
			Icon:     "image",
		},
		{
			ID:       commandSearch,
			Title:    "Search Online Wallpapers",
			Subtitle: "Search Wallhaven for landscape wallpapers, 1080p+, SFW",
			Icon:     "search",
		},
		{
			ID:       commandRestoreColors,
			Title:    "Restore Online Wallpaper Colors",
			Subtitle: "Restore colors saved before this extension first applied matching colors",
			Icon:     "undo-2",
		},
	}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case commandBrowse:
		if !isMac(ctx) {
			return api.Result{}, errors.New("This extension currently supports macOS.")
		}
		view, err := browseView(ctx, browseState{feed: "top", page: 1})
		if err != nil {
			return api.Result{}, err
		}
		return api.Result{View: &view, Navigation: api.NavPush}, nil
	case actionBrowsePage:
		view, err := browseView(ctx, stateFromArgs(in.Ref.Args))
		if err != nil {
			return api.Result{}, err
		}
		return api.Result{View: &view, Navigation: api.NavReplace}, nil
	case actionChangeFeed:
		return changeFeed(ctx, in.Value)
	case actionRefresh:
		state := stateFromArgs(in.Ref.Args)
		if err := ctx.Storage().Delete(listingKey(state)); err != nil {
			return api.Result{}, err
		}
		view, err := browseView(ctx, state)
		if err != nil {
			return api.Result{}, err
		}
		return api.Result{View: &view, Navigation: api.NavReplace}, nil
	case actionOpenFolder:
		return openDownloadFolder(ctx)
	case commandSearch:
		prompt := searchPrompt(ctx)
		return api.Result{Next: &prompt}, nil
	case actionSearchSubmit:
		return searchSubmit(ctx, in.Form)
	case actionApply:
		return applyFromArgs(ctx, in.Ref.Args)
	case actionPreview:
		return previewWallpaper(ctx, in.Ref.Args)
	case commandRestoreColors:
		return withLock(func() (api.Result, error) { return restoreColors(ctx) })
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func isMac(ctx api.Context) bool {
	system := strings.ToLower(ctx.System().OS())
	return strings.Contains(system, "mac") || strings.Contains(system, "darwin")
}

func withLock(run func() (api.Result, error)) (api.Result, error) {
	busyMu.Lock()
	if busy {
		busyMu.Unlock()
		return api.Result{}, errors.New("Another online wallpaper update is in progress. Please try again shortly.")
	}
	busy = true
	busyMu.Unlock()
	defer releaseLock()
	return run()
}

func releaseLock() {
	busyMu.Lock()
	defer busyMu.Unlock()
	busy = false
}

func stateFromArgs(args map[string]string) browseState {
	feedName := args["feed"]
	if feedName == "" {
		feedName = "top"
	}
	return browseState{feed: feedName, query: args["query"], page: parsePage(args["page"])}
}

func (s browseState) args() map[string]string {
	return map[string]string{"feed": s.feed, "query": s.query, "page": strconv.Itoa(s.page)}
}

func parsePage(value string) int {
	page, err := strconv.Atoi(value)
	if err != nil || page < 1 {
		return 1
	}
	return page
}

func listingKey(state browseState) string {
	return fmt.Sprintf("listing-v1:%s:%s:%d", state.feed, state.query, state.page)
}

func listing(ctx api.Context, state browseState) (wallhavenListing, error) {
	var out wallhavenListing
	err := ctx.Storage().Memo(listingKey(state), 10*time.Minute, &out, func() (any, error) {
		result, err := fetchListing(ctx, state)
		return result, err
	})
	return out, err
}

func fetchListing(ctx api.Context, state browseState) (wallhavenListing, error) {
	endpoint := "https://wallhaven.cc/api/v1/search?" + listingParams(state).Encode()
	response, err := ctx.Network().Fetch(api.FetchRequest{URL: endpoint, TimeoutMs: 25000})
	if err != nil {
		return wallhavenListing{}, fmt.Errorf("Cannot reach Wallhaven: %s", err.Error())
	}
	if response.Status == 429 {
		return wallhavenListing{}, errors.New("Wallhaven rate limit reached. Please wait a minute before trying again.")
	}
	if response.Status < 200 || response.Status > 299 {
		return wallhavenListing{}, fmt.Errorf("Wallhaven returned HTTP %d. Please try again later.", response.Status)
	}
	var body struct {
		Data *[]wallpaper `json:"data"`
		Meta struct {
			LastPage *int `json:"last_page"`
		} `json:"meta"`
	}
	if err := json.Unmarshal([]byte(response.Body), &body); err != nil || body.Data == nil || body.Meta.LastPage == nil {
		return wallhavenListing{}, errors.New("Wallhaven returned an invalid listing.")
	}
	var kept []wallpaper
	for _, candidate := range *body.Data {
		if !isLandscapeSFW(candidate) {
			continue
		}
		if err := checkWallpaperURLs(candidate); err != nil {
			return wallhavenListing{}, err
		}
		kept = append(kept, candidate)
	}
	return wallhavenListing{Data: kept, LastPage: *body.Meta.LastPage}, nil
}
