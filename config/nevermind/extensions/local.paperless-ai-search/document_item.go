package main

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func documentItem(ctx api.Context, candidate document, total int, query string) api.Item {
	link := documentURL(candidate.ID)
	title := candidate.Title
	if title == "" {
		title = fmt.Sprintf("Document %d", candidate.ID)
	}
	excerpt := candidate.Content
	if candidate.SearchHit != nil && candidate.SearchHit.Highlights != "" {
		excerpt = candidate.SearchHit.Highlights
	}
	excerpt = truncateRunes(tagPattern.ReplaceAllString(excerpt, ""), maxExcerptRunes)
	created := candidate.Created
	if len(created) > 10 {
		created = created[:10]
	}
	return api.Item{
		ID:       "document-" + strconv.FormatInt(candidate.ID, 10),
		Title:    title,
		Icon:     "file-text",
		Subtitle: joinNonEmpty(" · ", created, candidate.OriginalFileName),
		Primary:  api.Primary(api.OpenURL("Open Document in Paperless", link)),
		Actions: []api.Action{
			api.Run(actionEnlargeImage, "Enlarge Preview", map[string]string{"id": strconv.FormatInt(candidate.ID, 10), "title": title}),
			api.PushView("View Extracted Text", textPreview(title, firstNonEmpty(excerpt, "No extracted text available."))),
			api.CopyText("Copy Document Link", link, false),
			editQueryPrompt(ctx, query),
			searchPrompt(ctx),
		},
		Detail: &api.Detail{
			Title: candidate.Title,
			Text:  "Select this document to load its first-page preview.",
			Metadata: []api.Metadata{
				{Kind: api.MetadataText, Label: "Document ID", Value: strconv.FormatInt(candidate.ID, 10)},
				{Kind: api.MetadataText, Label: "Total matches", Value: strconv.Itoa(total)},
				{Kind: api.MetadataText, Label: "Paperless query", Value: query},
			},
		},
	}
}

func pageItem(id, title, icon, subtitle, query string, page int) api.Item {
	return api.Item{
		ID:       id,
		Title:    title,
		Subtitle: subtitle,
		Icon:     icon,
		Primary: api.Primary(api.Run(actionResultsPage, title, map[string]string{
			"query": query,
			"page":  strconv.Itoa(page),
		})),
	}
}

func loadPreview(ctx api.Context, loader, selected string) (api.Result, error) {
	cached, found := rowCache(ctx).Get(loader)
	if !found {
		return api.Result{}, nil
	}
	rows, _ := cached.([]api.Item)
	for index, row := range rows {
		if row.ID != selected || !strings.HasPrefix(row.ID, "document-") {
			continue
		}
		updated := withVisualDetail(ctx, row)
		rows[index] = updated
		rowCache(ctx).Set(loader, rows, rowCacheTTL)
		return api.Result{Patch: &api.ViewPatch{Items: []api.Item{updated}}}, nil
	}
	return api.Result{}, nil
}

func withVisualDetail(ctx api.Context, row api.Item) api.Item {
	base := api.Detail{Title: row.Title}
	if row.Detail != nil {
		base = *row.Detail
	}
	id, _ := strconv.ParseInt(strings.TrimPrefix(row.ID, "document-"), 10, 64)
	detail := visualDetail(ctx, id, base)
	row.Detail = &detail
	return row
}

func visualDetail(ctx api.Context, id int64, base api.Detail) api.Detail {
	image, err := thumbnail(ctx, id)
	if err != nil {
		base.Image = nil
		base.Subtitle = "Preview unavailable"
		base.Text = err.Error()
		return base
	}
	base.Text = ""
	base.Subtitle = "First-page preview"
	base.Image = &api.Image{Src: image, Fit: api.FitContain, Alt: base.Title}
	return base
}

func enlargePreview(ctx api.Context, args map[string]string) (api.Result, error) {
	id, _ := strconv.ParseInt(args["id"], 10, 64)
	title := args["title"]
	detail := visualDetail(ctx, id, api.Detail{Title: title})
	view := api.View{
		Kind:    api.ViewPreview,
		Title:   title,
		Size:    api.SizeLarge,
		Preview: &api.PreviewSpec{Image: detail.Image, Text: detail.Text},
		Actions: []api.Action{api.OpenURL("Open Document in Paperless", documentURL(id))},
	}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func tokenView() api.View {
	submit := api.Run(actionSaveToken, "Save Token and Search", nil)
	view := api.View{
		Kind:  api.ViewForm,
		Title: "Connect Paperless",
		Form: &api.FormSpec{
			Fields: []api.Field{
				{ID: "info", Type: api.FieldDescription, Description: previewBlurb},
				{ID: "token", Label: "Paperless API Token", Type: api.FieldPassword, Required: true},
			},
			Submit:      &submit,
			SubmitTitle: "Save Token and Search",
		},
	}
	view.Actions = []api.Action{api.OpenURL("Open Paperless to Get Token", paperlessBase)}
	return view
}

func saveToken(ctx api.Context, form api.FormValues) (api.Result, error) {
	token := tokenPrefix.ReplaceAllString(strings.TrimSpace(form["token"].Text), "")
	if token == "" || whitespacePattern.MatchString(token) {
		return api.Result{}, errors.New("Enter a valid Paperless API token, without whitespace.")
	}
	if _, err := requestPage(ctx, url.Values{"page_size": {"1"}}, token); err != nil {
		return api.Result{}, err
	}
	if err := ctx.Secrets().Set(tokenSecret, token); err != nil {
		return api.Result{}, err
	}
	bumpCredentialVersion()
	clearThumbnails()
	prompt := searchPrompt(ctx)
	return api.Result{Next: &prompt}, nil
}

func forgetAndShowConnect(ctx api.Context) (api.Result, error) {
	if err := forgetToken(ctx); err != nil {
		return api.Result{}, err
	}
	view := tokenView()
	return api.Result{View: &view, Navigation: api.NavReplace}, nil
}

func forgetToken(ctx api.Context) error {
	if err := ctx.Secrets().Delete(tokenSecret); err != nil {
		return err
	}
	bumpCredentialVersion()
	clearThumbnails()
	return nil
}

func requiredToken(ctx api.Context) (string, error) {
	token, _, err := ctx.Secrets().Get(tokenSecret)
	if err != nil {
		return "", err
	}
	if token == "" {
		return "", errors.New("No saved Paperless API token. Reopen Search Paperless with AI to connect.")
	}
	return token, nil
}

func requestPage(ctx api.Context, params url.Values, token string) (resultsPage, error) {
	endpoint := paperlessBase + "/api/documents/?" + params.Encode()
	response, err := ctx.Network().Fetch(api.FetchRequest{
		URL:       endpoint,
		Headers:   map[string]string{"Authorization": "Token " + token, "Accept": "application/json"},
		TimeoutMs: 25000,
	})
	if err != nil || response.FinalURL != endpoint {
		return resultsPage{}, errors.New("Could not reach docs.notflix.us. Check your connection/VPN. A login-proxy redirect or a timeout can also prevent API access.")
	}
	if response.Status == 401 || response.Status == 403 {
		if stored, _, _ := ctx.Secrets().Get(tokenSecret); stored == token {
			if err := forgetToken(ctx); err != nil {
				return resultsPage{}, err
			}
		}
		return resultsPage{}, errors.New("Paperless rejected API access. Run Search Paperless with AI again and enter a valid API token with document-read permission.")
	}
	if response.Status == 400 {
		return resultsPage{}, errors.New("Paperless rejected the search query. Use Edit Paperless Query or try a simpler search.")
	}
	if response.Status < 200 || response.Status > 299 {
		return resultsPage{}, fmt.Errorf("Paperless request failed (HTTP %d).", response.Status)
	}
	if !strings.Contains(strings.ToLower(header(response.Headers, "content-type")), "json") {
		return resultsPage{}, errors.New("Paperless returned a login page instead of API data. Check that API-token access is allowed through your login proxy.")
	}
	var data resultsPage
	if err := json.Unmarshal([]byte(response.Body), &data); err != nil || data.Count == nil || data.Results == nil {
		return resultsPage{}, errors.New("Unexpected Paperless API response: a paginated document list was expected.")
	}
	return data, nil
}

func thumbnail(ctx api.Context, id int64) (string, error) {
	token, err := requiredToken(ctx)
	if err != nil {
		return "", err
	}
	version := currentCredentialVersion()
	if cached, found := cachedThumbnail(id); found {
		return cached, nil
	}
	image, err := fetchThumbnail(ctx, id, token)
	if err != nil {
		return "", err
	}
	if version != currentCredentialVersion() {
		return "", errors.New("The Paperless connection changed. Reopen the search.")
	}
	storeThumbnail(id, image)
	return image, nil
}

func fetchThumbnail(ctx api.Context, id int64, token string) (string, error) {
	endpoint := fmt.Sprintf("%s/api/documents/%d/thumb/", paperlessBase, id)
	response, err := ctx.Network().Fetch(api.FetchRequest{
		URL:       endpoint,
		Headers:   map[string]string{"Authorization": "Token " + token},
		TimeoutMs: 15000,
		MaxBytes:  maxPreviewBytes,
	})
	if errors.Is(err, api.ErrQuotaExceeded) {
		return "", errors.New("Document preview is too large.")
	}
	if err != nil || response.FinalURL != endpoint {
		return "", errors.New("Could not load the document preview. Check your connection or login proxy.")
	}
	if response.Status < 200 || response.Status > 299 {
		return "", fmt.Errorf("Document preview unavailable (HTTP %d). You can still open it in Paperless.", response.Status)
	}
	mime := strings.ToLower(strings.TrimSpace(strings.Split(header(response.Headers, "content-type"), ";")[0]))
	if !contains(previewMIMETypes, mime) {
		return "", errors.New("Paperless did not return a supported preview image.")
	}
	body, err := responseBytes(response)
	if err != nil {
		return "", err
	}
	if len(body) > maxPreviewBytes {
		return "", errors.New("Document preview is too large.")
	}
	return "data:" + mime + ";base64," + base64.StdEncoding.EncodeToString(body), nil
}

func responseBytes(response api.FetchResponse) ([]byte, error) {
	if response.BodyBase64 != "" {
		return base64.StdEncoding.DecodeString(response.BodyBase64)
	}
	return []byte(response.Body), nil
}

func cachedThumbnail(id int64) (string, bool) {
	stateMu.Lock()
	defer stateMu.Unlock()
	image, found := thumbnails[id]
	return image, found
}
