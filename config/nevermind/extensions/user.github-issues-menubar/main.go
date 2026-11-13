package main

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const refreshID = "refresh"

type searchIssue struct {
	Number        int    `json:"number"`
	Title         string `json:"title"`
	HTMLURL       string `json:"html_url"`
	RepositoryURL string `json:"repository_url"`
}

type searchResponse struct {
	Items []searchIssue `json:"items"`
}

func MenuBarTriggers() []api.Trigger {
	return []api.Trigger{{Type: api.TriggerInterval, Every: "5m"}}
}

func MenuBars(ctx api.Context) ([]api.MenuBar, error) {
	issues, err := fetchIssues(ctx)
	if err != nil {
		errRow := api.MenuRow{ID: "error", Title: "GitHub Issues unavailable", Subtitle: short(err.Error(), 80), Disabled: true}
		ract := api.Run(refreshID, "Refresh", nil)
		rrow := api.MenuRow{ID: refreshID, Title: "Refresh", Action: &ract}
		bar := api.MenuBar{ID: "github-issues", Icon: api.MenuBarIcon("github"), Title: "!", Tooltip: "GitHub Issues: " + err.Error(), Sections: []api.MenuSection{{Title: "GitHub Issues", Rows: []api.MenuRow{errRow, rrow}}}}
		return []api.MenuBar{bar}, nil
	}
	rows := make([]api.MenuRow, 0, len(issues)+1)
	for _, is := range issues {
		if len(rows) >= 20 {
			break
		}
		repo := repositoryOf(is)
		sub := fmt.Sprintf("%s #%d", repo, is.Number)
		open := api.OpenURL("Open in Browser", is.HTMLURL)
		rows = append(rows, api.MenuRow{ID: is.HTMLURL, Title: short(is.Title, 70), Subtitle: sub, Action: &open})
	}
	if len(rows) == 0 {
		rows = append(rows, api.MenuRow{ID: "empty", Title: "No open issues", Disabled: true})
	}
	ract := api.Run(refreshID, "Refresh", nil)
	rows = append(rows, api.MenuRow{ID: refreshID, Title: "Refresh", Subtitle: "Update now", Action: &ract})
	count := fmt.Sprintf("%d", len(issues))
	tip := fmt.Sprintf("%d open issues in pablopunk repos", len(issues))
	if len(issues) == 1 {
		tip = "1 open issue in pablopunk repos"
	}
	bar := api.MenuBar{ID: "github-issues", Icon: api.MenuBarIcon("github"), Title: count, Tooltip: tip, Sections: []api.MenuSection{{Title: "GitHub Issues", Rows: rows}}}
	return []api.MenuBar{bar}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	if in.Ref.ID == refreshID {
		ctx.Views().RefreshMenuBar()
		return api.Result{}, nil
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func fetchIssues(ctx api.Context) ([]searchIssue, error) {
	result, err := ctx.Desktop().Shell().Exec("gh", []string{"api", "--method", "GET", "search/issues", "-f", "q=is:issue is:open user:pablopunk", "-f", "sort=updated", "-f", "order=desc", "-f", "per_page=20"}, api.ShellOptions{TimeoutMs: 15000, OutputLimit: 2000000})
	if err != nil {
		return nil, err
	}
	if result.ExitCode != 0 {
		detail := strings.TrimSpace(result.Stderr)
		if detail == "" {
			detail = strings.TrimSpace(result.Stdout)
		}
		if detail == "" {
			detail = "Unknown GitHub CLI error"
		}
		return nil, fmt.Errorf("%s", detail)
	}
	var resp searchResponse
	if err := json.Unmarshal([]byte(result.Stdout), &resp); err != nil {
		return nil, fmt.Errorf("GitHub returned invalid JSON: %w", err)
	}
	if resp.Items == nil {
		return nil, fmt.Errorf("GitHub returned an unexpected issue-search response.")
	}
	return resp.Items, nil
}

func repositoryOf(is searchIssue) string {
	_, after, found := strings.Cut(is.RepositoryURL, "/repos/")
	if !found || after == "" {
		return "Unknown repository"
	}
	return after
}

func short(s string, n int) string {
	s = strings.TrimSpace(s)
	if len(s) <= n {
		return s
	}
	return strings.TrimSpace(s[:n-1]) + "…"
}
