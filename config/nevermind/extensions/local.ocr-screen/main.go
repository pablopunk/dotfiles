package main

import (
	"fmt"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	commandCopyVisibleText = "copy-visible-screen-text"
	indicatorID            = "ocr-screen"
)

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       commandCopyVisibleText,
		Title:    "OCR Screen",
		Subtitle: "Copy all visible text to the clipboard",
		Aliases: []string{
			"copy screen text",
			"extract text from screen",
			"screen text",
			"visible text",
		},
		Keywords:        []string{"ocr", "screen", "copy", "text", "visible"},
		Icon:            "scan-text",
		Mode:            api.ModeBackground,
		DismissAfterRun: true,
		Customizable:    true,
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	if in.Ref.ID != commandCopyVisibleText {
		return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
	}
	if err := ctx.Indicators().Show(api.IndicatorInput{ID: indicatorID, Title: "OCR Screen", Subtitle: "Reading visible text…", Status: api.IndicatorLoading}); err != nil {
		return api.Result{}, err
	}
	err := copyVisibleText(ctx)
	if err == nil {
		return api.Result{}, nil
	}
	ctx.Logs().Log(api.LogError, "Screen OCR failed", map[string]string{"error": err.Error()})
	_ = ctx.Indicators().Update(api.IndicatorInput{ID: indicatorID, Title: "OCR Screen", Subtitle: err.Error(), Status: api.IndicatorError, DurationMs: 4500})
	return api.Result{}, fmt.Errorf("OCR Screen failed: %s", err.Error())
}

func copyVisibleText(ctx api.Context) error {
	if !ctx.System().HasCapability("ocr") {
		return fmt.Errorf("Screen OCR is not available on this Mac")
	}
	recognized, err := ctx.OCR().Screen(api.OCROptions{TimeoutMs: 30000})
	if err != nil {
		return err
	}
	text := strings.TrimSpace(recognized.Text)
	if text == "" {
		return updateNoText(ctx)
	}
	if err := ctx.Desktop().Clipboard().WriteText(text, false); err != nil {
		return err
	}
	return ctx.Indicators().Update(api.IndicatorInput{
		ID:         indicatorID,
		Title:      "OCR Screen",
		Subtitle:   fmt.Sprintf("Copied %s to the clipboard", pluralLines(nonBlankLines(text))),
		Status:     api.IndicatorSuccess,
		DurationMs: 2500,
	})
}

// updateNoText is not an error in 1.x: the indicator reports the empty screen and the command ends.
func updateNoText(ctx api.Context) error {
	return ctx.Indicators().Update(api.IndicatorInput{ID: indicatorID, Title: "OCR Screen", Subtitle: "No visible text found", Status: api.IndicatorError, DurationMs: 3500})
}

func nonBlankLines(text string) int {
	count := 0
	for _, line := range strings.Split(text, "\n") {
		if strings.TrimSpace(line) != "" {
			count++
		}
	}
	return count
}

func pluralLines(count int) string {
	if count == 1 {
		return "1 line"
	}
	return fmt.Sprintf("%d lines", count)
}
