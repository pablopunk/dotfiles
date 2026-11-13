package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"time"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	prsCommandID   = "show-my-prs"
	filterActionID = "change-filter"
	filterStateKey = "queryType"
	defaultFilter  = "authored"
	prsLoaderBase  = "prs:"
)

var prFilters = []api.ViewFilterOption{
	{Title: "Authored by me", Value: "authored"},
	{Title: "Involving me", Value: "involved"},
	{Title: "Review requested", Value: "review-requested"},
	{Title: "All in current repository", Value: "repo-all"},
}

var (
	githubRemotePattern     = regexp.MustCompile(`(?i)github\.com[/:]([^/]+/[^/]+?)(?:\.git)?$`)
	authFailurePattern      = regexp.MustCompile(`(?i)auth|login|token|401|credentials`)
	rateLimitFailurePattern = regexp.MustCompile(`(?i)rate limit|403`)
)

type prLabel struct {
	Name  string `json:"name"`
	Color string `json:"color"`
}

type prAuthor struct {
	Login string `json:"login"`
}

type prRepository struct {
	NameWithOwner string `json:"nameWithOwner"`
}

type pullRequest struct {
	Number     int          `json:"number"`
	Title      string       `json:"title"`
	URL        string       `json:"url"`
	Author     *prAuthor    `json:"author"`
	UpdatedAt  string       `json:"updatedAt"`
	Labels     []prLabel    `json:"labels"`
	Repository prRepository `json:"repository"`
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       prsCommandID,
		Title:    "Show My Pull Requests",
		Subtitle: "List open pull requests across repos or current repo",
		Icon:     "git-pull-request",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case prsCommandID:
		view := prsView(ctx, savedFilter(ctx))
		return api.Result{View: &view, Navigation: api.NavPush}, nil
	case filterActionID:
		if err := ctx.Storage().Set(filterStateKey, filterOrDefault(in.Value)); err != nil {
			return api.Result{}, err
		}
		view := prsView(ctx, savedFilter(ctx))
		return api.Result{View: &view, Navigation: api.NavReplace}, nil
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

// LoadItems fetches the pull requests of the filter named in the loader id, e.g. "prs:authored".
func LoadItems(ctx api.Context, loader string) ([]api.Item, error) {
	queryType := strings.TrimPrefix(loader, prsLoaderBase)
	prs, err := fetchPRs(ctx, queryType)
	if err != nil {
		ctx.Logs().Log(api.LogError, "GitHub pull requests failed to load", map[string]any{"queryType": queryType, "message": err.Error()})
		return nil, err
	}
	items := make([]api.Item, 0, len(prs))
	for _, pr := range prs {
		items = append(items, prItem(pr))
	}
	return items, nil
}

// prsView is a lazily loaded list: the host shows the cached rows for the filter and refreshes them in place.
func prsView(ctx api.Context, filter string) api.View {
	view := api.ListView("My Pull Requests")
	source := ctx.Data().StaleWhileRevalidate(prsLoaderBase+filter, "gh-prs-v2-"+filter, time.Minute, 5*time.Minute, false)
	view.Source = &source
	view.Filter = &api.ViewFilter{Value: filter, Options: prFilters, OnChange: &api.ActionRef{ID: filterActionID}}
	view.EmptyView = &api.EmptyState{Title: "No open pull requests", Subtitle: "No results found. Try changing the dropdown filter."}
	view.Placeholder = "Filter results…"
	return view
}

func filterOrDefault(filter string) string {
	if filter == "" {
		return defaultFilter
	}
	return filter
}

func savedFilter(ctx api.Context) string {
	var filter string
	if found, err := ctx.Storage().Get(filterStateKey, &filter); err != nil || !found {
		return defaultFilter
	}
	return filterOrDefault(filter)
}

func fetchPRs(ctx api.Context, queryType string) ([]pullRequest, error) {
	ghPath, err := findGhPath(ctx)
	if err != nil {
		return nil, err
	}
	shell := ctx.Desktop().Shell()
	auth, err := shell.Exec(ghPath, []string{"auth", "status", "--hostname", "github.com"}, api.ShellOptions{TimeoutMs: 15000, OutputLimit: 100000})
	if err != nil {
		return nil, err
	}
	if auth.ExitCode != 0 {
		detail := outputDetail(auth)
		ctx.Logs().Log(api.LogError, "GitHub CLI authentication unavailable", map[string]any{"ghPath": ghPath, "detail": detail})
		return nil, explainGhFailure(detail)
	}
	args := []string{"search", "prs", "--state", "open", "--limit", "50", "--json", "number,title,url,author,updatedAt,labels,repository"}
	switch queryType {
	case "authored":
		args = append(args, "--author", "@me")
	case "involved":
		args = append(args, "--involved", "@me")
	case "review-requested":
		args = append(args, "--review-requested", "@me")
	case "repo-all":
		repository, err := currentRepository(ctx)
		if err != nil {
			return nil, err
		}
		args = append(args, "--repo", repository)
	}
	result, err := shell.Exec(ghPath, args, api.ShellOptions{TimeoutMs: 30000, OutputLimit: 2000000})
	if err != nil {
		return nil, err
	}
	if result.ExitCode != 0 {
		detail := outputDetail(result)
		ctx.Logs().Log(api.LogError, "GitHub pull request search failed", map[string]any{"ghPath": ghPath, "queryType": queryType, "exitCode": result.ExitCode, "detail": detail})
		return nil, explainGhFailure(detail)
	}
	var prs []pullRequest
	if err := json.Unmarshal([]byte(result.Stdout), &prs); err != nil {
		return nil, fmt.Errorf("GitHub returned invalid JSON: %w", err)
	}
	ctx.Logs().Log(api.LogInfo, "GitHub pull requests loaded", map[string]any{"queryType": queryType, "count": len(prs), "ghPath": ghPath})
	return prs, nil
}

func prItem(pr pullRequest) api.Item {
	repository := pr.Repository.NameWithOwner
	if repository == "" {
		repository = "Unknown repository"
	}
	author := "ghost"
	if pr.Author != nil && pr.Author.Login != "" {
		author = pr.Author.Login
	}
	keywords := []string{repository, author}
	for _, label := range pr.Labels {
		keywords = append(keywords, label.Name)
	}
	var accessories []api.Accessory
	if updated, err := time.Parse(time.RFC3339, pr.UpdatedAt); err == nil {
		accessories = append(accessories, api.Accessory{Text: updated.Local().Format("1/2/2006"), Tooltip: "Last updated"})
	}
	for _, label := range firstLabels(pr.Labels, 2) {
		accessories = append(accessories, api.Accessory{Text: label.Name, Tooltip: "Label"})
	}
	return api.Item{
		ID:          pr.URL,
		Title:       pr.Title,
		Subtitle:    fmt.Sprintf("%s #%d", repository, pr.Number),
		Keywords:    keywords,
		Accessories: accessories,
		Icon:        "git-pull-request",
		Primary:     api.Primary(api.OpenURL("Open in Browser", pr.URL)),
		Actions: []api.Action{
			api.CopyText("Copy URL", pr.URL, false),
			api.CopyText("Copy Repository Name", repository, false),
		},
	}
}

func firstLabels(labels []prLabel, count int) []prLabel {
	if len(labels) > count {
		return labels[:count]
	}
	return labels
}

func currentRepository(ctx api.Context) (string, error) {
	result, err := ctx.Desktop().Shell().Exec("/usr/bin/git", []string{"config", "--get", "remote.origin.url"}, api.ShellOptions{})
	if err != nil {
		return "", err
	}
	remote := strings.TrimSpace(result.Stdout)
	if result.ExitCode != 0 || remote == "" {
		return "", errors.New("No GitHub repository could be detected from Nevermind’s current working directory.")
	}
	match := githubRemotePattern.FindStringSubmatch(remote)
	if match == nil {
		return "", fmt.Errorf("The current Git remote is not a GitHub repository: %s", remote)
	}
	return match[1], nil
}

func explainGhFailure(detail string) error {
	switch {
	case authFailurePattern.MatchString(detail):
		return errors.New("GitHub CLI is installed, but Nevermind could not access its login. Restart Nevermind and try again.")
	case rateLimitFailurePattern.MatchString(detail):
		return fmt.Errorf("GitHub API rate limit reached. %s", detail)
	case detail == "":
		return errors.New("GitHub pull request search failed: Unknown GitHub CLI error")
	}
	return fmt.Errorf("GitHub pull request search failed: %s", detail)
}

// findGhPath locates gh the way Terminal does: the app's PATH first, then the user's login shell, then the usual folders.
func findGhPath(ctx api.Context) (string, error) {
	shell := ctx.Desktop().Shell()
	var candidates []string
	located, locateErr := shell.Which("gh")
	if locateErr == nil && located.ExitCode == 0 && strings.TrimSpace(located.Stdout) != "" {
		candidates = append(candidates, strings.TrimSpace(located.Stdout))
	}
	loginShell, loginErr := shell.Exec("/bin/zsh", []string{"-lic", "command -v gh"}, api.ShellOptions{TimeoutMs: 10000, OutputLimit: 20000})
	if loginErr == nil && loginShell.ExitCode == 0 && strings.TrimSpace(loginShell.Stdout) != "" {
		lines := strings.Split(strings.TrimSpace(loginShell.Stdout), "\n")
		candidates = append(candidates, lines[len(lines)-1])
	}
	candidates = append(candidates, "/opt/homebrew/bin/gh", "/usr/local/bin/gh", "/usr/bin/gh")
	for _, path := range uniqueTrimmed(candidates) {
		check, checkErr := shell.Exec("/bin/test", []string{"-x", path}, api.ShellOptions{})
		if checkErr == nil && check.ExitCode == 0 {
			ctx.Logs().Log(api.LogInfo, "GitHub CLI located", map[string]any{"path": path})
			return path, nil
		}
	}
	ctx.Logs().Log(api.LogError, "GitHub CLI discovery failed", map[string]any{
		"whichExitCode":      located.ExitCode,
		"whichOutput":        strings.TrimSpace(located.Stdout),
		"loginShellExitCode": loginShell.ExitCode,
		"loginShellOutput":   strings.TrimSpace(loginShell.Stdout),
		"loginShellError":    strings.TrimSpace(loginShell.Stderr),
	})
	return "", errors.New("Nevermind could not locate the GitHub CLI used by Terminal. Restart Nevermind once so it reloads your login environment, then try again.")
}

func uniqueTrimmed(values []string) []string {
	seen := map[string]bool{}
	var unique []string
	for _, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed != "" && !seen[trimmed] {
			seen[trimmed] = true
			unique = append(unique, trimmed)
		}
	}
	return unique
}

// outputDetail is the trimmed stderr, or stdout when stderr is empty.
func outputDetail(result api.ShellResult) string {
	if detail := strings.TrimSpace(result.Stderr); detail != "" {
		return detail
	}
	return strings.TrimSpace(result.Stdout)
}
