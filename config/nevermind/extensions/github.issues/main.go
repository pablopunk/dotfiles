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
	issuesCommandID = "show-my-issues"
	filterActionID  = "change-filter"
	filterStateKey  = "queryType"
	defaultFilter   = "pablopunk"
)

var issueFilters = []api.ViewFilterOption{
	{Title: "My repos (pablopunk/*)", Value: "pablopunk"},
	{Title: "Assigned to me", Value: "assigned"},
	{Title: "Authored by me", Value: "authored"},
	{Title: "Current repository", Value: "repo-all"},
}

var githubRemotePattern = regexp.MustCompile(`(?i)github\.com[/:]([^/]+/[^/]+?)(?:\.git)?$`)

type searchLabel struct {
	Name string `json:"name"`
}

type searchUser struct {
	Login string `json:"login"`
}

type searchIssue struct {
	Number        int           `json:"number"`
	Title         string        `json:"title"`
	HTMLURL       string        `json:"html_url"`
	User          *searchUser   `json:"user"`
	UpdatedAt     string        `json:"updated_at"`
	Labels        []searchLabel `json:"labels"`
	RepositoryURL string        `json:"repository_url"`
}

type searchResponse struct {
	Items []searchIssue `json:"items"`
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       issuesCommandID,
		Title:    "Show GitHub Issues",
		Subtitle: "Open issues across pablopunk repositories, newest first",
		Icon:     "circle-dot",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case issuesCommandID:
		return issuesResult(ctx, savedFilter(ctx), api.NavPush)
	case filterActionID:
		filter := in.Value
		if filter == "" {
			filter = defaultFilter
		}
		return issuesResult(ctx, filter, api.NavReplace)
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func savedFilter(ctx api.Context) string {
	var filter string
	if found, err := ctx.Storage().Get(filterStateKey, &filter); err != nil || !found || filter == "" {
		return defaultFilter
	}
	return filter
}

// issuesResult returns a cached, host-loaded list before any CLI or network work starts.
func issuesResult(ctx api.Context, filter string, navigation api.NavigationMode) (api.Result, error) {
	if err := ctx.Storage().Set(filterStateKey, filter); err != nil {
		return api.Result{}, err
	}
	view := api.ListView("GitHub Issues")
	view.Source = &api.DataSource{Loader: "issues:" + filter, CacheKey: "issues:v2:" + filter, TTLMs: 30000, StaleTTLMs: 1800000, Retry: true}
	view.Filter = &api.ViewFilter{Value: filter, Options: issueFilters, OnChange: &api.ActionRef{ID: filterActionID}}
	view.EmptyView = &api.EmptyState{Title: "No open issues", Subtitle: "No results found for this filter."}
	view.Placeholder = "Filter issues…"
	return api.Result{View: &view, Navigation: navigation}, nil
}

func LoadItems(ctx api.Context, loader string) ([]api.Item, error) {
	if !strings.HasPrefix(loader, "issues:") {
		return nil, fmt.Errorf("unknown loader %q", loader)
	}
	return loadIssues(ctx, strings.TrimPrefix(loader, "issues:"))
}

func loadIssues(ctx api.Context, queryType string) ([]api.Item, error) {
	issues, err := fetchIssues(ctx, queryType)
	if err != nil {
		ctx.Logs().Log(api.LogError, "GitHub Issues failed to load", map[string]any{"queryType": queryType, "message": err.Error()})
		return nil, err
	}
	items := make([]api.Item, 0, len(issues))
	for _, issue := range issues {
		items = append(items, issueItem(issue))
	}
	return items, nil
}

func fetchIssues(ctx api.Context, queryType string) ([]searchIssue, error) {
	ghPath, err := findGhPath(ctx)
	if err != nil {
		return nil, err
	}
	shell := ctx.Desktop().Shell()
	repository := ""
	if queryType == "repo-all" {
		if repository, err = currentRepository(ctx); err != nil {
			return nil, err
		}
	}
	result, err := shell.Exec(ghPath, []string{
		"api", "--method", "GET", "search/issues",
		"-f", "q=" + searchQualifier(queryType, repository),
		"-f", "sort=updated",
		"-f", "order=desc",
		"-f", "per_page=50",
	}, api.ShellOptions{TimeoutMs: 30000, OutputLimit: 2000000})
	if err != nil {
		return nil, err
	}
	if result.ExitCode != 0 {
		detail := outputDetail(result)
		ctx.Logs().Log(api.LogError, "GitHub API issue search failed", map[string]any{"ghPath": ghPath, "queryType": queryType, "exitCode": result.ExitCode, "detail": detail})
		return nil, explainGhFailure("issue", detail)
	}
	var response searchResponse
	if err := json.Unmarshal([]byte(result.Stdout), &response); err != nil {
		return nil, fmt.Errorf("GitHub returned invalid JSON: %w", err)
	}
	if response.Items == nil {
		return nil, errors.New("GitHub returned an unexpected issue-search response.")
	}
	valid := validIssues(response.Items)
	ctx.Logs().Log(api.LogInfo, "GitHub Issues loaded", map[string]any{"queryType": queryType, "count": len(valid), "ghPath": ghPath})
	return valid, nil
}

func validIssues(items []searchIssue) []searchIssue {
	var valid []searchIssue
	for _, item := range items {
		if item.HTMLURL != "" && item.Number != 0 && item.Title != "" && item.UpdatedAt != "" {
			valid = append(valid, item)
		}
	}
	return valid
}

func issueItem(issue searchIssue) api.Item {
	repository := repositoryOf(issue)
	author := "ghost"
	if issue.User != nil && issue.User.Login != "" {
		author = issue.User.Login
	}
	keywords := []string{repository, author}
	var accessories []api.Accessory
	if updated, err := time.Parse(time.RFC3339, issue.UpdatedAt); err == nil {
		accessories = append(accessories, api.Accessory{Text: updated.Local().Format("1/2/2006"), Tooltip: "Last updated"})
	}
	for _, label := range issue.Labels {
		if label.Name != "" {
			keywords = append(keywords, label.Name)
		}
	}
	for _, label := range firstLabels(issue.Labels, 2) {
		if label.Name != "" {
			accessories = append(accessories, api.Accessory{Text: label.Name, Tooltip: "Label"})
		}
	}
	return api.Item{
		ID:          issue.HTMLURL,
		Title:       issue.Title,
		Subtitle:    fmt.Sprintf("%s #%d", repository, issue.Number),
		Keywords:    keywords,
		Accessories: accessories,
		Icon:        "circle-dot",
		Primary:     api.Primary(api.OpenURL("Open in Browser", issue.HTMLURL)),
		Actions: []api.Action{
			api.CopyText("Copy URL", issue.HTMLURL, false),
			api.CopyText("Copy Repository Name", repository, false),
		},
	}
}

func firstLabels(labels []searchLabel, count int) []searchLabel {
	if len(labels) > count {
		return labels[:count]
	}
	return labels
}

// repositoryOf reads owner/name from the API URL, as the search response has no repository field.
func repositoryOf(issue searchIssue) string {
	_, after, found := strings.Cut(issue.RepositoryURL, "/repos/")
	if !found || after == "" {
		return "Unknown repository"
	}
	return after
}

func searchQualifier(queryType, repository string) string {
	switch {
	case queryType == "assigned":
		return "is:issue is:open assignee:@me"
	case queryType == "authored":
		return "is:issue is:open author:@me"
	case queryType == "repo-all" && repository != "":
		return "is:issue is:open repo:" + repository
	}
	return "is:issue is:open user:pablopunk"
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

var (
	authFailurePattern      = regexp.MustCompile(`(?i)auth|login|token|401|credentials`)
	rateLimitFailurePattern = regexp.MustCompile(`(?i)rate limit|403`)
)

func explainGhFailure(kind, detail string) error {
	switch {
	case authFailurePattern.MatchString(detail):
		return errors.New("GitHub CLI is installed, but Nevermind could not access its login. Restart Nevermind and try again.")
	case rateLimitFailurePattern.MatchString(detail):
		return fmt.Errorf("GitHub API rate limit reached. %s", detail)
	case detail == "":
		return fmt.Errorf("GitHub %s search failed: Unknown GitHub CLI error", kind)
	}
	return fmt.Errorf("GitHub %s search failed: %s", kind, detail)
}

// findGhPath locates gh the way Terminal does: the app's PATH first, then the user's login shell, then the usual folders.
func findGhPath(ctx api.Context) (string, error) {
	return "gh", nil
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
