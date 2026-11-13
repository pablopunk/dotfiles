package main

import (
	"errors"
	"fmt"
	"sort"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func restoreColors(ctx api.Context) (api.Result, error) {
	var saved snapshot
	found, err := ctx.Storage().Get(backupKey, &saved)
	if err != nil {
		return api.Result{}, err
	}
	if !found {
		return api.Result{}, errors.New("This extension has not saved any previous colors yet. Your local Wallpapers extension keeps its own backup.")
	}
	before, err := readSnapshot(ctx, sortedKeys(saved))
	if err != nil {
		return api.Result{}, err
	}
	if err := writeSnapshot(ctx, saved); err != nil {
		if rollbackErr := writeSnapshot(ctx, before); rollbackErr != nil {
			return api.Result{}, fmt.Errorf("%s Rollback also failed: %s", err.Error(), rollbackErr.Error())
		}
		return api.Result{}, err
	}
	if err := ctx.Storage().Delete(backupKey); err != nil {
		return api.Result{}, err
	}
	if err := restartDock(ctx); err != nil {
		return api.Result{}, errors.New("Previous colors were restored, but " + err.Error())
	}
	return api.Result{}, ctx.Indicators().Show(api.IndicatorInput{Title: "Previous colors restored · Dock refreshed", Status: api.IndicatorSuccess, DurationMs: 4000})
}

func sortedKeys(values map[string]*string) []string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func ptr(value string) *string {
	return &value
}

func contains(values []string, value string) bool {
	for _, candidate := range values {
		if candidate == value {
			return true
		}
	}
	return false
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}
