package main

import (
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"unicode/utf16"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

func storeThumbnail(id int64, image string) {
	stateMu.Lock()
	defer stateMu.Unlock()
	if _, found := thumbnails[id]; !found {
		if len(thumbnails) >= maxThumbnails {
			oldest := thumbnailOrder[0]
			thumbnailOrder = thumbnailOrder[1:]
			delete(thumbnails, oldest)
		}
		thumbnailOrder = append(thumbnailOrder, id)
	}
	thumbnails[id] = image
}

func clearThumbnails() {
	stateMu.Lock()
	defer stateMu.Unlock()
	thumbnails = map[int64]string{}
	thumbnailOrder = nil
}

func bumpCredentialVersion() {
	stateMu.Lock()
	defer stateMu.Unlock()
	credentialVersion++
}

func currentCredentialVersion() int {
	stateMu.Lock()
	defer stateMu.Unlock()
	return credentialVersion
}

func rowCache(ctx api.Context) api.Cache {
	return ctx.Cache()
}

func resultsLoader(query string, page int) string {
	return loaderPrefix + url.Values{"query": {query}, "page": {strconv.Itoa(page)}}.Encode()
}

func parseResultsLoader(loader string) (string, int, error) {
	if !strings.HasPrefix(loader, loaderPrefix) {
		return "", 0, fmt.Errorf("unknown loader %q", loader)
	}
	values, err := url.ParseQuery(strings.TrimPrefix(loader, loaderPrefix))
	if err != nil {
		return "", 0, err
	}
	return values.Get("query"), pageNumber(values.Get("page")), nil
}

func pageNumber(value string) int {
	page, err := strconv.Atoi(value)
	if err != nil || page < 1 {
		return 1
	}
	return page
}

func textPreview(title, text string) api.View {
	return api.View{Kind: api.ViewPreview, Title: title, Size: api.SizeLarge, Preview: &api.PreviewSpec{Text: text}}
}

func documentURL(id int64) string {
	return fmt.Sprintf("%s/documents/%d/details", paperlessBase, id)
}

func header(headers map[string]string, name string) string {
	for key, value := range headers {
		if strings.EqualFold(key, name) {
			return value
		}
	}
	return ""
}

func utf16Length(value string) int {
	return len(utf16.Encode([]rune(value)))
}

func truncateRunes(value string, limit int) string {
	runes := []rune(value)
	if len(runes) <= limit {
		return value
	}
	return string(runes[:limit])
}

func joinNonEmpty(separator string, values ...string) string {
	var parts []string
	for _, value := range values {
		if value != "" {
			parts = append(parts, value)
		}
	}
	return strings.Join(parts, separator)
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
