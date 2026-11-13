package main

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const (
	listCommandID  = "list-stages"
	stagesLoader   = "stages"
	refreshAction  = "refresh-stages"
	switchAction   = "switch"
	inspectAction  = "inspect"
	inspectFailure = "Neither process returned any accessible UI elements. Check Nevermind Accessibility permissions."
	stageMaxCount  = 32
)

// Stage Manager has no public stage-list API. On this macOS setup, its shelf
// appears as AXButtons inside an AXList under WindowManager's AXGroup.
const helpers = `
on cleanText(t)
  set t to t as text
  set AppleScript's text item delimiters to {tab, return, linefeed, "|"}
  set pieces to text items of t
  set AppleScript's text item delimiters to " "
  return pieces as text
end cleanText



on labelOf(el)
  set n to ""
  tell application "System Events"
    try
      set n to name of el as text
    end try
    if n is "" or n is "missing value" then
      try
        set n to description of el as text
      end try
    end if
  end tell
  if n is "missing value" then set n to ""
  return my cleanText(n)
end labelOf
`

// Only collect the exact WindowManager group → list → button structure shown
// by the user's accessibility diagnosis. Never confuse Dock apps with stages.
const scanScript = helpers + `
set outputText to ""
tell application "System Events"
  try
    set wm to first application process whose name is "WindowManager"
    set groupIndex to 0
    repeat with grp in UI elements of wm
      set groupIndex to groupIndex + 1
      if groupIndex > 20 then exit repeat
      try
        if role of grp is "AXGroup" then
          set listIndex to 0
          repeat with lst in UI elements of grp
            set listIndex to listIndex + 1
            if listIndex > 20 then exit repeat
            try
              if role of lst is "AXList" then
                set buttonIndex to 0
                repeat with btn in UI elements of lst
                  set buttonIndex to buttonIndex + 1
                  if buttonIndex > 40 then exit repeat
                  try
                    if role of btn is "AXButton" then
                      set buttonName to my labelOf(btn)
                      if buttonName is not "" then set outputText to outputText & "WindowManager." & (groupIndex as text) & "." & (listIndex as text) & "." & (buttonIndex as text) & "|" & buttonName & linefeed
                    end if
                  end try
                end repeat
              end if
            end try
          end repeat
        end if
      end try
    end repeat
  end try
end tell
return outputText
`

// Read-only, bounded correlation: title of an AXWindow -> owning process name.
// This does not activate stages or assume an installed app belongs to a stage.
const windowScript = helpers + `
set outputText to ""
tell application "System Events"
  set processCount to 0
  repeat with proc in application processes
    set processCount to processCount + 1
    if processCount > 120 then exit repeat
    try
      set procName to my cleanText(name of proc)
      if procName is not "WindowManager" and procName is not "Dock" then
        set windowCount to 0
        repeat with win in windows of proc
          set windowCount to windowCount + 1
          if windowCount > 25 then exit repeat
          try
            set windowName to my labelOf(win)
            if windowName is not "" then set outputText to outputText & procName & "|" & windowName & linefeed
          end try
        end repeat
      end if
    end try
  end repeat
end tell
return outputText
`

// Bounded, read-only diagnostic for layouts that differ from the observed one.
const inspectScript = helpers + `
property seenCount : 0
on inspect(el, depth, pathText)
  if depth > 5 or seenCount > 110 then return ""
  set resultText to ""
  tell application "System Events"
    try
      set kids to UI elements of el
    on error errText
      return pathText & " — cannot read children: " & my cleanText(errText) & linefeed
    end try
    set k to 0
    repeat with child in kids
      set k to k + 1
      if k > 40 or seenCount > 110 then exit repeat
      set seenCount to seenCount + 1
      set childPath to pathText & "." & (k as text)
      set roleText to "?"
      set descText to ""
      try
        set roleText to role of child as text
      end try
      try
        set descText to description of child as text
      end try
      set resultText to resultText & childPath & "  " & my cleanText(roleText) & "  name=" & my labelOf(child) & "  description=" & my cleanText(descText) & linefeed
      set resultText to resultText & my inspect(child, depth + 1, childPath)
    end repeat
  end tell
  return resultText
end inspect



set outputText to ""
tell application "System Events"
  repeat with procName in {"Dock", "WindowManager"}
    try
      set proc to first application process whose name is (procName as text)
      set outputText to outputText & "## " & (procName as text) & linefeed & my inspect(proc, 0, procName as text)
    on error errText
      set outputText to outputText & "## " & (procName as text) & ": " & my cleanText(errText) & linefeed
    end try
  end repeat
end tell
return outputText
`

var (
	stageElementPattern = regexp.MustCompile(`^WindowManager\.\d{1,2}\.\d{1,2}\.\d{1,2}$`)
	stageActivation     = regexp.MustCompile(`^WindowManager\.([1-9]\d?)\.([1-9]\d?)\.([1-9]\d?)$`)
)

type stage struct {
	path string
	name string
}

type windowEntry struct {
	app   string
	title string
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       listCommandID,
		Title:    "Stage Manager Stages",
		Subtitle: "List WindowManager shelf stages and switch to one",
		Icon:     "panels-top-left",
	}}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case listCommandID:
		return stagesResult(ctx)
	case refreshAction:
		items, err := stageItems(ctx)
		if err != nil {
			return api.Result{}, err
		}
		return api.Result{Patch: &api.ViewPatch{Mode: api.PatchReplace, Items: items}}, nil
	case switchAction:
		return api.Result{}, switchStage(ctx, in.Ref.Args["path"], in.Ref.Args["label"])
	case inspectAction:
		return inspectResult(ctx)
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func LoadItems(ctx api.Context, loader string) ([]api.Item, error) {
	return stageItems(ctx)
}

func stagesResult(ctx api.Context) (api.Result, error) {
	if ctx.System().OS() != "darwin" {
		return errorResult("Stage Manager Stages", "This command requires macOS."), nil
	}
	view := api.ListView("Stage Manager Stages")
	view.Placeholder = "Search stages…"
	view.Source = &api.DataSource{Loader: stagesLoader}
	view.EmptyView = &api.EmptyState{Title: "No accessible stages", Subtitle: "Stage Manager must be on with Recent Apps visible."}
	view.Actions = []api.Action{ctx.Views().Refresh()}
	view.Refresh = &api.Refresh{Mode: api.PatchReplace, Ref: &api.ActionRef{ID: refreshAction}}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func runAppleScript(ctx api.Context, script string, timeoutMs int64) (string, error) {
	result, err := ctx.Desktop().Shell().AppleScript(script, api.ShellOptions{TimeoutMs: timeoutMs, OutputLimit: 30000})
	if err != nil {
		return "", err
	}
	if result.ExitCode != 0 {
		detail := strings.TrimSpace(result.Stderr)
		if detail == "" {
			detail = "Check Nevermind Accessibility and System Events permissions."
		}
		return "", fmt.Errorf("Could not access Stage Manager UI. %s", detail)
	}
	return result.Stdout, nil
}

func inspectResult(ctx api.Context) (api.Result, error) {
	tree, err := runAppleScript(ctx, inspectScript, 15000)
	if err != nil {
		return api.Result{}, err
	}
	content := "Read-only Dock / WindowManager accessibility tree (first 110 elements). Names may include open apps.\n\n" + orDefault(strings.TrimSpace(tree), inspectFailure)
	view := api.View{
		Kind:    api.ViewPreview,
		Title:   "Stage Manager Accessibility Diagnosis",
		Preview: &api.PreviewSpec{Text: content},
		Actions: []api.Action{api.CopyText("Copy Accessibility Diagnosis", tree, false)},
	}
	return api.Result{View: &view, Navigation: api.NavPush}, nil
}

func switchStage(ctx api.Context, path, label string) error {
	script, err := activateScript(path, label)
	if err != nil {
		return err
	}
	_, err = runAppleScript(ctx, script, 10000)
	return err
}
