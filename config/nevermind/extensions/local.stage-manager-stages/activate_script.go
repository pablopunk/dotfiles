package main

import (
	"errors"
	"strings"
)

func activateScript(path, label string) (string, error) {
	match := stageActivation.FindStringSubmatch(path)
	if match == nil {
		return "", errors.New("Invalid Stage Manager element path. Refresh the list.")
	}
	return helpers + `
tell application "System Events"
  set wm to first application process whose name is "WindowManager"
  set grp to UI element ` + match[1] + ` of wm
  if role of grp is not "AXGroup" then error "Stage Manager layout changed. Refresh the list."
  set lst to UI element ` + match[2] + ` of grp
  if role of lst is not "AXList" then error "Stage Manager layout changed. Refresh the list."
  set btn to UI element ` + match[3] + ` of lst
  if role of btn is not "AXButton" or my labelOf(btn) is not ` + scriptString(label) + ` then error "Stage Manager stages changed. Refresh the list."
  try
    perform action "AXPress" of btn
  on error
    click btn
  end try
end tell
return "OK"
`, nil
}

func scriptString(text string) string {
	return `"` + strings.NewReplacer(`\`, `\\`, `"`, `\"`).Replace(text) + `"`
}
