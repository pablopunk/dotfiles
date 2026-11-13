package main

import (
	"github.com/pablopunk/nvm/native/internal/ext/api"
)

// errorResult is the 1.x ui.error: a list with one contextual row that holds the title and the message.
func errorResult(title, message string) api.Result {
	view := api.ErrorView(title, message)
	return api.Result{View: &view, Navigation: api.NavPush}
}
