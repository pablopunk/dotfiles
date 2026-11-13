package main

import (
	"errors"
	"net/url"
	"regexp"
	"strconv"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	extractCommandID  = "extract-url"
	copyURLActionID   = "copy-url"
	ocrIndicatorID    = "url-ocr"
	ocrLanguage       = "en"
	ocrTimeoutMs      = 30000
	ocrCapability     = "ocr"
	ocrListSubtitle   = "Local OCR • Check long authentication tokens for recognition errors."
	noURLSubtitle     = "Try a tighter, higher-resolution screenshot of the URL."
	reviewTitle       = "Review or Edit URL"
	reviewScreenTitle = "Review URL"
)

var (
	urlStartPattern     = regexp.MustCompile(`(?i)https?\s*:\s*/\s*/`)
	urlSchemePrefix     = regexp.MustCompile(`(?i)https?\s*:\s*/`)
	quoteOrBracketChars = regexp.MustCompile(`[<>"'` + "`" + `]`)
	proseAfterURL       = regexp.MustCompile(`\s+[A-Za-z]{2,}\s+[A-Za-z]{2,}(?:\s|[.!:]|$)`)
	disallowedURLChars  = regexp.MustCompile(`[^A-Za-z0-9\s\-._~:/?#\[\]@!$&()*+,;=%]`)
	proseLine           = regexp.MustCompile(`[A-Za-z]{2,}\s+[A-Za-z]{2,}(?:\s+[A-Za-z]{2,}|[.:!?]?$)`)
	terminalPrompt      = regexp.MustCompile(`^(?:\$|>|❯|➜)\s`)
	bareWord            = regexp.MustCompile(`^[A-Za-z]+[.:!?]?$`)
	whitespace          = regexp.MustCompile(`\s+`)
	zeroWidth           = regexp.MustCompile(`[\x{200B}-\x{200D}\x{FEFF}]`)
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:      extractCommandID,
		Title:   "Get URL from Screenshot",
		Icon:    "scan-text",
		Aliases: []string{"OCR URL", "Copy URL from Clipboard Image", "Terminal Login URL"},
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case extractCommandID:
		return extractResult(ctx)
	case copyURLActionID:
		return copyEditedURL(ctx, in.EditorContent)
	}
	return api.Result{}, errors.New("unknown action " + in.Ref.ID)
}

func extractResult(ctx api.Context) (api.Result, error) {
	if !ctx.System().HasCapability(ocrCapability) {
		return api.Result{}, errors.New("Native OCR is unavailable on this system.")
	}
	clipboard := ctx.Desktop().Clipboard()
	image, found, err := clipboard.ReadImage()
	if err != nil {
		return api.Result{}, err
	}
	if !found {
		return api.Result{}, errors.New("Copy a screenshot to the clipboard first, then run Get URL from Screenshot.")
	}
	showIndicator(ctx, api.IndicatorInput{ID: ocrIndicatorID, Title: "Reading URL from screenshot…", Status: api.IndicatorLoading})
	defer ctx.Indicators().Hide(ocrIndicatorID)
	result, err := ctx.OCR().Image(api.OCRInput{Source: image}, api.OCROptions{Languages: []string{ocrLanguage}, TimeoutMs: ocrTimeoutMs})
	if err != nil {
		return api.Result{}, err
	}
	text := recognizedText(result)
	urls := extractURLs(text)
	if len(urls) == 0 {
		view := noURLView(text)
		return api.Result{View: &view, Navigation: api.NavPush}, nil
	}
	copied := false
	if len(urls) == 1 {
		copied = copyIfClipboardUnchanged(ctx, image, urls[0])
	}
	view := urlListView(urls, text, copied)
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func recognizedText(result api.OCRResult) string {
	if result.Text != "" {
		return result.Text
	}
	parts := make([]string, 0, len(result.Blocks))
	for _, block := range result.Blocks {
		parts = append(parts, block.Text)
	}
	return strings.Join(parts, "\n")
}

func copyIfClipboardUnchanged(ctx api.Context, image, value string) bool {
	clipboard := ctx.Desktop().Clipboard()
	current, found, err := clipboard.ReadImage()
	if err != nil || !found || current != image {
		return false
	}
	if err := clipboard.WriteText(value, false); err != nil {
		return false
	}
	showIndicator(ctx, api.IndicatorInput{Title: "URL copied", Subtitle: "Wrapped lines and spaces removed", Status: api.IndicatorSuccess, DurationMs: 2500})
	return true
}

func noURLView(text string) api.View {
	view := api.ListView("No URL Found")
	view.ContentSizing = "fit"
	view.Items = []api.Item{
		contextRow("no-url-hint", noURLSubtitle),
		{
			ID:       "review",
			Title:    "Review Recognized Text",
			Subtitle: "Repair the URL, remove surrounding instructions, then copy it.",
			Icon:     "text-cursor-input",
			Primary:  api.Primary(api.PushView(reviewTitle, reviewView(text))),
		},
	}
	return view
}

func urlListView(urls []string, text string, copied bool) api.View {
	title := "Choose a URL to Copy"
	if copied {
		title = "URL Copied"
	}
	view := api.ListView(title)
	view.ContentSizing = "fit"
	visible := true
	view.Detail = &api.DetailPane{Placement: "bottom", Visible: &visible}
	view.Items = []api.Item{contextRow("ocr-hint", ocrListSubtitle)}
	for index, value := range urls {
		view.Items = append(view.Items, urlItem(index, value, text))
	}
	return view
}

func urlItem(index int, value, text string) api.Item {
	parsed, _ := url.Parse(value)
	return api.Item{
		ID:       "url-" + strconv.Itoa(index),
		Title:    parsed.Hostname(),
		Subtitle: value,
		Icon:     "link",
		Detail:   &api.Detail{Text: value},
		Primary:  api.Primary(api.CopyText("Copy URL", value, false)),
		Actions: []api.Action{
			api.PushView(reviewTitle, reviewView(value)),
			api.PushView("View Recognized Text", api.View{Kind: api.ViewPreview, Title: "Recognized Text", Preview: &api.PreviewSpec{Text: text}}),
		},
	}
}

func contextRow(id, message string) api.Item {
	return api.Item{ID: id, Title: message, Disabled: true, Contextual: true}
}

func reviewView(content string) api.View {
	submit := api.Run(copyURLActionID, "Copy URL", nil)
	return api.View{
		Kind:  api.ViewEditor,
		Title: reviewScreenTitle,
		Editor: &api.EditorSpec{
			Content: content,
			Format:  "text",
			Submit:  &submit,
		},
	}
}

func copyEditedURL(ctx api.Context, content string) (api.Result, error) {
	value := whitespace.ReplaceAllString(content, "")
	if !validURL(value) {
		return api.Result{}, errors.New("Enter a complete http:// or https:// URL. The clipboard has not been changed.")
	}
	if err := ctx.Desktop().Clipboard().WriteText(value, false); err != nil {
		return api.Result{}, err
	}
	showIndicator(ctx, api.IndicatorInput{Title: "URL copied", Status: api.IndicatorSuccess, DurationMs: 2200})
	return api.Result{Navigation: api.NavPop}, nil
}

func showIndicator(ctx api.Context, input api.IndicatorInput) {
	_ = ctx.Indicators().Show(input)
}

func validURL(value string) bool {
	parsed, err := url.Parse(value)
	return err == nil && (parsed.Scheme == "http" || parsed.Scheme == "https") && parsed.Hostname() != ""
}

// extractURLs rebuilds URLs that OCR wrapped across lines or split with spaces.
func extractURLs(text string) []string {
	lines := strings.Split(zeroWidth.ReplaceAllString(strings.ReplaceAll(text, "\r\n", "\n"), ""), "\n")
	var urls []string
	for index, line := range lines {
		for _, value := range urlsOnLine(lines, index, line) {
			if validURL(value) && !containsString(urls, value) {
				urls = append(urls, value)
			}
		}
	}
	return urls
}

func urlsOnLine(lines []string, index int, line string) []string {
	starts := urlStartPattern.FindAllStringIndex(line, -1)
	var values []string
	for position, start := range starts {
		end := len(line)
		if position+1 < len(starts) {
			end = starts[position+1][0]
		}
		fragment := line[start[0]:end]
		closed := false
		if delimiter := quoteOrBracketChars.FindStringIndex(fragment); delimiter != nil {
			fragment = fragment[:delimiter[0]]
			closed = true
		}
		if prose := proseAfterURL.FindStringIndex(fragment); prose != nil {
			fragment = fragment[:prose[0]]
			closed = true
		}
		value := whitespace.ReplaceAllString(fragment, "")
		if !closed && position == len(starts)-1 {
			value += continuationOf(lines, index)
		}
		values = append(values, trimUnmatched(value))
	}
	return values
}

func continuationOf(lines []string, index int) string {
	var value strings.Builder
	for next := index + 1; next < len(lines); next++ {
		candidate := strings.TrimSpace(lines[next])
		if !isURLContinuation(candidate) {
			break
		}
		value.WriteString(whitespace.ReplaceAllString(candidate, ""))
	}
	return value.String()
}

func isURLContinuation(line string) bool {
	if line == "" || urlSchemePrefix.MatchString(line) {
		return false
	}
	if quoteOrBracketChars.MatchString(line) || disallowedURLChars.MatchString(line) {
		return false
	}
	if proseLine.MatchString(line) || terminalPrompt.MatchString(line) {
		return false
	}
	return !bareWord.MatchString(whitespace.ReplaceAllString(line, ""))
}

func trimUnmatched(value string) string {
	for _, pair := range [][2]string{{"(", ")"}, {"[", "]"}} {
		for strings.HasSuffix(value, pair[1]) && strings.Count(value, pair[1]) > strings.Count(value, pair[0]) {
			value = value[:len(value)-1]
		}
	}
	return value
}

func containsString(values []string, target string) bool {
	for _, value := range values {
		if value == target {
			return true
		}
	}
	return false
}
