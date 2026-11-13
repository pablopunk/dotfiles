package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	commandShowRepos = "show-repos"
	loaderRepos      = "repos"
	repoCacheKey     = "pablopunk-repos-v1"
)

var (
	githubRepoURL = regexp.MustCompile(`(?i)^https://github\.com/`)
)

type repo struct {
	ID          int64   `json:"id"`
	Name        string  `json:"name"`
	FullName    string  `json:"full_name"`
	HTMLURL     string  `json:"html_url"`
	Description *string `json:"description"`
	Private     bool    `json:"private"`
	Fork        bool    `json:"fork"`
	Language    *string `json:"language"`
	UpdatedAt   string  `json:"updated_at"`
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       commandShowRepos,
		Title:    "My GitHub Repos",
		Subtitle: "Open the latest pablopunk repositories",
		Aliases:  []string{"my repos", "github repos", "repos"},
		Icon:     "github",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	if in.Ref.ID != commandShowRepos {
		return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
	}
	view := repoView(ctx)
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func LoadItems(ctx api.Context, loader string) ([]api.Item, error) {
	if loader != loaderRepos {
		return nil, fmt.Errorf("unknown loader %q", loader)
	}
	repos, err := requestRepos(ctx)
	if err != nil {
		return nil, err
	}
	return repoItems(ctx, repos), nil
}

func requestRepos(ctx api.Context) ([]repo, error) {
	result, err := ctx.Desktop().Shell().Exec("gh", []string{
		"api", "--method", "GET", "user/repos",
		"-f", "affiliation=owner", "-f", "sort=updated", "-f", "direction=desc",
		"-f", "per_page=20", "-f", "page=1",
	}, api.ShellOptions{TimeoutMs: 30000, OutputLimit: 1000000})
	if err != nil {
		return nil, errors.New("Could not run GitHub CLI. Install gh and sign in with gh auth login, then retry.")
	}
	if result.ExitCode != 0 {
		detail := strings.ToLower(result.Stderr)
		if strings.Contains(detail, "executable file not found") || strings.Contains(detail, "no such file") {
			return nil, errors.New("GitHub CLI was not found. Install gh, restart Nevermind to reload your login environment, then retry.")
		}
		if strings.Contains(detail, "auth login") || strings.Contains(detail, "401") || strings.Contains(detail, "not logged") {
			return nil, errors.New("Sign in with gh auth login in Terminal, then retry. No access token is required here.")
		}
		return nil, errors.New("GitHub could not load repositories. Check your gh account access and connection, then retry.")
	}
	return decodeRepos(result.Stdout)
}

func decodeRepos(body string) ([]repo, error) {
	var payload any
	if err := json.Unmarshal([]byte(body), &payload); err != nil {
		return nil, errors.New("GitHub returned an unreadable response. Please try again.")
	}
	if _, isList := payload.([]any); !isList {
		object, _ := payload.(map[string]any)
		if message, _ := object["message"].(string); message != "" {
			return nil, fmt.Errorf("GitHub API error: %s", message)
		}
		return nil, errors.New("GitHub returned an unexpected repository response.")
	}
	var repos []repo
	if err := json.Unmarshal([]byte(body), &repos); err != nil {
		return nil, errors.New("GitHub returned an unexpected repository response.")
	}
	owned := repos[:0]
	for _, candidate := range repos {
		if strings.HasPrefix(strings.ToLower(candidate.FullName), "pablopunk/") {
			owned = append(owned, candidate)
		}
	}
	sort.SliceStable(owned, func(i, j int) bool {
		return updatedAt(owned[i]).After(updatedAt(owned[j]))
	})
	if len(owned) > 20 {
		owned = owned[:20]
	}
	return owned, nil
}

func updatedAt(candidate repo) time.Time {
	parsed, _ := time.Parse(time.RFC3339, candidate.UpdatedAt)
	return parsed
}

func repoItems(ctx api.Context, repos []repo) []api.Item {
	now := ctx.Clock().Now()
	var items []api.Item
	for _, candidate := range repos {
		if !githubRepoURL.MatchString(candidate.HTMLURL) {
			continue
		}
		items = append(items, repoItem(candidate, now))
	}
	return items
}

func repoItem(candidate repo, now time.Time) api.Item {
	id := candidate.FullName
	if candidate.ID != 0 {
		id = strconv.FormatInt(candidate.ID, 10)
	}
	title := candidate.Name
	if title == "" {
		title = candidate.FullName
	}
	description := derefString(candidate.Description)
	language := derefString(candidate.Language)
	accessories := []api.Accessory{{Text: visibility(candidate.Private), Tone: api.ToneMuted}}
	if language != "" {
		accessories = append(accessories, api.Accessory{Text: language, Tone: api.ToneMuted})
	}
	if candidate.Fork {
		accessories = append(accessories, api.Accessory{Text: "Fork", Tone: api.ToneMuted})
	}
	return api.Item{
		ID:          id,
		Title:       title,
		Subtitle:    fmt.Sprintf("%s · %s", candidate.FullName, formatUpdated(candidate.UpdatedAt, now)),
		Icon:        "github",
		Keywords:    []string{candidate.FullName, description, language},
		Accessories: accessories,
		Primary:     api.Primary(api.OpenURL(fmt.Sprintf("Open %s on GitHub", candidate.FullName), candidate.HTMLURL)),
	}
}

func visibility(private bool) string {
	if private {
		return "Private"
	}
	return "Public"
}

func derefString(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}

func repoView(ctx api.Context) api.View {
	view := repoListView(nil)
	view.Source = &api.DataSource{
		Loader:     loaderRepos,
		CacheKey:   repoCacheKey,
		TTLMs:      30000,
		StaleTTLMs: 30 * 60000,
		Retry:      true,
	}
	return view
}

func repoListView(items []api.Item) api.View {
	view := api.ListView("My GitHub Repos", items...)
	view.Subtitle = "pablopunk · newest updates first · showing up to 20"
	view.Placeholder = "Filter repositories"
	view.EmptyView = &api.EmptyState{
		Title:    "No pablopunk repositories found",
		Subtitle: "Check that your GitHub CLI account can read pablopunk repositories.",
	}

	return view
}

// formatUpdated mirrors Intl.RelativeTimeFormat with numeric "auto" for English.
func formatUpdated(value string, now time.Time) string {
	stamp, err := time.Parse(time.RFC3339, value)
	if err != nil {
		return "Updated time unavailable"
	}
	delta := stamp.Sub(now)
	minutes := jsRound(delta.Minutes())
	hours := jsRound(delta.Hours())
	days := jsRound(delta.Hours() / 24)
	switch {
	case math.Abs(minutes) < 60:
		return "Updated " + relativeTime(minutes, "minute")
	case math.Abs(hours) < 24:
		return "Updated " + relativeTime(hours, "hour")
	case math.Abs(days) < 30:
		return "Updated " + relativeDay(days)
	}
	return "Updated " + stamp.Local().Format("1/2/2006")
}

func jsRound(value float64) float64 {
	return math.Floor(value + 0.5)
}

func relativeTime(value float64, unit string) string {
	if value == 0 {
		return "this " + unit
	}
	count := int(math.Abs(value))
	label := unit
	if count != 1 {
		label += "s"
	}
	if value < 0 {
		return fmt.Sprintf("%d %s ago", count, label)
	}
	return fmt.Sprintf("in %d %s", count, label)
}

func relativeDay(value float64) string {
	switch value {
	case 0:
		return "today"
	case 1:
		return "tomorrow"
	case -1:
		return "yesterday"
	}
	return relativeTime(value, "day")
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}
