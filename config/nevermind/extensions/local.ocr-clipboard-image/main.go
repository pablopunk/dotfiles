package main

import (
	"errors"
	"fmt"
	"net/url"
	"regexp"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	commandCopyText     = "copy-text"
	actionCopyFormImage = "copy-image"
	successIndicatorID  = "clipboard-ocr-success"
)

var (
	crlfPattern         = regexp.MustCompile(`\r\n?`)
	paragraphSeparator  = regexp.MustCompile(`\n[\t ]*\n(?:[\t ]*\n)*`)
	lineBreakPattern    = regexp.MustCompile(`[\t ]*\n[\t ]*`)
	httpPrefixPattern   = regexp.MustCompile(`(?i)^https?://`)
	invisibleWhitespace = regexp.MustCompile(`[\s\x{200B}\x{FEFF}]+`)
	printableASCII      = regexp.MustCompile(`^[\x21-\x7E]+$`)
	queryString         = regexp.MustCompile(`\?([^#]*)`)
	queryPair           = regexp.MustCompile(`^[A-Za-z0-9_.~-]+=\S*$`)
	fragmentMarker      = regexp.MustCompile(`[/%.?&#=_~+-]`)
	whitespaceSpan      = regexp.MustCompile(`\s+`)
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       commandCopyText,
		Title:    "OCR Image in Clipboard",
		Subtitle: "Automatically use the clipboard image, copied file, or image path",
		Aliases:  []string{"Copy Text from Clipboard Image", "Clipboard OCR"},
		Icon:     "scan-text",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case commandCopyText:
		return copyFromClipboard(ctx)
	case actionCopyFormImage:
		path := in.Form["image"].Text
		if path == "" {
			return api.Result{}, errors.New("Choose an image file first.")
		}
		if err := recognizeAndCopy(ctx, path); err != nil {
			return api.Result{}, err
		}
		return doneResult(), nil
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func copyFromClipboard(ctx api.Context) (api.Result, error) {
	if err := requireOCR(ctx); err != nil {
		return api.Result{}, err
	}
	input, err := clipboardImageInput(ctx)
	if err != nil {
		return api.Result{}, err
	}
	if input != "" {
		if err := recognizeAndCopy(ctx, input); err != nil {
			return api.Result{}, err
		}
		return doneResult(), nil
	}
	prompt := ctx.Input().Prompt(api.PromptSpec{
		Title:   "OCR Image in Clipboard",
		Message: "No image or file path in the clipboard. Choose an image instead.",
		Fields: []api.Field{{
			ID:         "image",
			Label:      "Image file",
			Type:       api.FieldFile,
			Required:   true,
			Extensions: []string{"png", "jpg", "jpeg", "tiff", "tif", "heic", "webp", "bmp", "gif"},
		}},
		Action: api.Run(actionCopyFormImage, "Copy Image Text", nil),
	})
	return api.Result{Next: &prompt}, nil
}

func clipboardImageInput(ctx api.Context) (string, error) {
	clipboard := ctx.Desktop().Clipboard()
	dataURL, found, err := clipboard.ReadImage()
	if err != nil {
		return "", err
	}
	if found && dataURL != "" {
		return dataURL, nil
	}
	content, err := clipboard.Read([]string{"image", "files"})
	if err != nil {
		return "", err
	}
	switch content.Type {
	case "image":
		if content.ImageDataURL != "" {
			return content.ImageDataURL, nil
		}
	case "files":
		if len(content.Paths) > 0 && content.Paths[0] != "" {
			return content.Paths[0], nil
		}
	}
	text, err := clipboard.ReadText()
	if err != nil {
		return "", err
	}
	if path := unquote(strings.TrimSpace(text)); isPathInput(path) {
		return path, nil
	}
	return "", nil
}

func isPathInput(value string) bool {
	return strings.HasPrefix(value, "/") || strings.HasPrefix(value, "~/") || strings.HasPrefix(value, "file://")
}

func unquote(value string) string {
	if len(value) >= 2 && (value[0] == '\'' || value[0] == '"') && value[len(value)-1] == value[0] {
		return value[1 : len(value)-1]
	}
	return value
}

func recognizeAndCopy(ctx api.Context, input string) error {
	if err := requireOCR(ctx); err != nil {
		return err
	}
	recognized, err := ctx.OCR().Image(api.OCRInput{Source: input}, api.OCROptions{TimeoutMs: 30000})
	if err != nil {
		return err
	}
	text := unwrapLines(recognized.Text)
	if text == "" {
		return errors.New("No text was found in the image. The clipboard was left unchanged.")
	}
	if err := ctx.Desktop().Clipboard().WriteText(text, false); err != nil {
		return err
	}
	return ctx.Indicators().Show(api.IndicatorInput{
		ID:         successIndicatorID,
		Title:      "Copied to clipboard",
		Status:     api.IndicatorSuccess,
		DurationMs: 2500,
	})
}

func requireOCR(ctx api.Context) error {
	if !ctx.System().HasCapability("ocr") {
		return errors.New("Image text recognition is not supported on this system.")
	}
	return nil
}

func doneResult() api.Result {
	return api.Result{Next: &api.Action{Kind: api.ActionPop, Title: "Done", DismissAfterRun: true}}
}

// unwrapLines joins hard-wrapped lines inside each paragraph and keeps paragraph breaks.
func unwrapLines(text string) string {
	normalized := strings.TrimSpace(crlfPattern.ReplaceAllString(text, "\n"))
	var paragraphs []string
	for _, paragraph := range paragraphSeparator.Split(normalized, -1) {
		cleaned, ok := cleanURLParagraph(strings.TrimSpace(paragraph))
		if !ok {
			cleaned = strings.TrimSpace(lineBreakPattern.ReplaceAllString(paragraph, " "))
		}
		if cleaned != "" {
			paragraphs = append(paragraphs, cleaned)
		}
	}
	return strings.Join(paragraphs, "\n\n")
}

// cleanURLParagraph returns the URL a wrapped paragraph holds, with its line breaks removed, when it is one.
func cleanURLParagraph(paragraph string) (string, bool) {
	if !httpPrefixPattern.MatchString(paragraph) {
		return "", false
	}
	compact := invisibleWhitespace.ReplaceAllString(paragraph, "")
	if !printableASCII.MatchString(compact) {
		return "", false
	}
	parsed, err := url.Parse(compact)
	if err != nil || parsed.Hostname() == "" || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		return "", false
	}
	if !whitespaceSpan.MatchString(paragraph) {
		return compact, true
	}
	if hasOnlyKeyValueQuery(compact) {
		return compact, true
	}
	fragments := whitespaceSpan.Split(paragraph, -1)
	if len(fragments) > 1 && allMatch(fragments[1:], fragmentMarker.MatchString) {
		return compact, true
	}
	return "", false
}

func hasOnlyKeyValueQuery(compact string) bool {
	match := queryString.FindStringSubmatch(compact)
	if match == nil || match[1] == "" {
		return false
	}
	return allMatch(strings.Split(match[1], "&"), queryPair.MatchString)
}

func allMatch(values []string, predicate func(string) bool) bool {
	for _, value := range values {
		if !predicate(value) {
			return false
		}
	}
	return true
}
