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
cmdID = "copy-screen-urls"
editID = "copy-edited-url"
indID = "screen-urls"
)
var (
startPat = regexp.MustCompile(`(?i)https?\s*:\s*/\s*/`)
prosePat = regexp.MustCompile(`\s+[A-Za-z]{2,}\s+[A-Za-z]{2,}(?:\s|[.!:]|$)`)
quotePat = regexp.MustCompile(`[<>\"'`+"`"+`]`)
wsPat = regexp.MustCompile(`\s+`)
zwPat = regexp.MustCompile(`[\x{200B}-\x{200D}\x{FEFF}]`)
barePat = regexp.MustCompile(`(?i)\b(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}(?:/[^\s<>"']*)?`)
)
func Commands(ctx api.Context) ([]api.Command, error) {
return []api.Command{{ID: cmdID, Title: "Copy Screen Links", Subtitle: "Read visible display and copy links", Aliases: []string{"Copy Links From Display", "Visible Display Links"}, Keywords: []string{"ocr", "display", "link", "copy"}, Icon: "link"}}, nil
}
func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
switch in.Ref.ID {
case cmdID:
return extractResult(ctx)
case editID:
return copyEdited(ctx, in.EditorContent)
}
return api.Result{}, errors.New("unknown action " + in.Ref.ID)
}
func extractResult(ctx api.Context) (api.Result, error) {
if !ctx.System().HasCapability("ocr") {
return api.Result{}, errors.New("Display reading is not available on this system.")
}
_ = ctx.Indicators().Show(api.IndicatorInput{ID: indID, Title: "Scanning display…", Status: api.IndicatorLoading})
defer ctx.Indicators().Hide(indID)
res, err := ctx.OCR().Screen(api.OCROptions{TimeoutMs: 30000})
if err != nil {
return api.Result{}, err
}
text := recognizedText(res)
urls := extractURLs(text)
if len(urls) == 0 {
v := noURLView(text)
return api.Result{View: &v, Navigation: api.NavPush}, nil
}
if len(urls) == 1 {
if err := ctx.Desktop().Clipboard().WriteText(urls[0], false); err == nil {
_ = ctx.Indicators().Show(api.IndicatorInput{Title: "Display link copied", Subtitle: urls[0], Status: api.IndicatorSuccess, DurationMs: 2500})
}
}
v := urlListView(urls, text, len(urls) == 1)
return api.Result{View: &v, Navigation: api.NavPush}, nil
}
func recognizedText(r api.OCRResult) string {
if r.Text != "" {
return r.Text
}
p := make([]string, 0, len(r.Blocks))
for _, b := range r.Blocks {
p = append(p, b.Text)
}
return strings.Join(p, "\n")
}
func extractURLs(text string) []string {
c := strings.ReplaceAll(text, "\r\n", "\n")
c = zwPat.ReplaceAllString(c, "")
lines := strings.Split(c, "\n")
var out []string
for i, l := range lines {
for _, u := range urlsOnLine(lines, i, l) {
if validURL(u) && !contains(out, u) {
out = append(out, u)
}
}
}
for _, l := range lines {
for _, b := range bareURLs(l) {
if !contains(out, b) {
out = append(out, b)
}
}
}
return out
}
func urlsOnLine(lines []string, idx int, line string) []string {
idxs := startPat.FindAllStringIndex(line, -1)
var vals []string
for pi, s := range idxs {
end := len(line)
if pi+1 < len(idxs) {
end = idxs[pi+1][0]
}
frag := line[s[0]:end]
closed := false
if q := quotePat.FindStringIndex(frag); q != nil {
frag = frag[:q[0]]
closed = true
}
if p := prosePat.FindStringIndex(frag); p != nil {
frag = frag[:p[0]]
closed = true
}
v := wsPat.ReplaceAllString(frag, "")
if !closed && pi == len(idxs)-1 {
v += continuationOf(lines, idx)
}
vals = append(vals, trimUnmatched(v))
}
return vals
}
func bareURLs(line string) []string {
var o []string
for _, m := range barePat.FindAllString(line, -1) {
m = trimUnmatched(strings.TrimSpace(m))
m = strings.Trim(m, ".,;:!?)\"'(")
m = strings.TrimLeft(m, "([\"'")
if m == "" {
continue
}
u := "https://" + m
if !validURL(u) {
continue
}
p, _ := url.Parse(u)
if !bareHostOK(p.Hostname()) {
continue
}
if !contains(o, u) {
o = append(o, u)
}
}
return o
}
func bareHostOK(h string) bool {
p := strings.Split(strings.ToLower(h), ".")
if len(p) < 2 {
return false
}
t := p[len(p)-1]
if len(t) < 2 || len(t) > 24 {
return false
}
for _, r := range t {
if r < 'a' || r > 'z' {
return false
}
}
switch t {
case "png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "tif", "tiff", "mp3", "mp4", "mov", "avi", "mkv", "wav", "pdf", "docx", "xlsx", "pptx", "zip", "rar", "dmg", "exe", "js", "ts", "py", "go", "json", "xml", "yml", "yaml", "log", "txt":
return false
}
return true
}
func continuationOf(lines []string, idx int) string {
var b strings.Builder
for n := idx + 1; n < len(lines); n++ {
t := strings.TrimSpace(lines[n])
if !isContinuation(t) {
break
}
b.WriteString(wsPat.ReplaceAllString(t, ""))
}
return b.String()
}
func isContinuation(t string) bool {
if t == "" || startPat.MatchString(t) {
return false
}
if strings.Contains(t, " ") || strings.Contains(t, "\t") || quotePat.MatchString(t) || len(t) < 3 {
return false
}
for _, r := range t {
if r >= 'A' && r <= 'Z' || r >= 'a' && r <= 'z' || r >= '0' && r <= '9' {
continue
}
if strings.ContainsRune("-._~:/?#[]@!$&()*+,;=%", r) {
continue
}
return false
}
return true
}
func trimUnmatched(v string) string {
for _, p := range [][2]string{{"(", ")"}, {"[", "]"}} {
for strings.HasSuffix(v, p[1]) && strings.Count(v, p[1]) > strings.Count(v, p[0]) {
v = v[:len(v)-1]
}
}
return strings.TrimRight(v, ".,;:!?)")
}
func contains(a []string, t string) bool {
for _, v := range a {
if v == t {
return true
}
}
return false
}
func validURL(v string) bool {
p, err := url.Parse(v)
return err == nil && (p.Scheme == "http" || p.Scheme == "https") && p.Hostname() != ""
}
func noURLView(text string) api.View {
v := api.ListView("No Display Links")
v.ContentSizing = "fit"
rev := api.PushView("See Display Reading", api.View{Kind: api.ViewPreview, Title: "Display Reading", Preview: &api.PreviewSpec{Text: text}})
v.Items = []api.Item{{ID: "hint", Title: "No links visible on the display right now.", Disabled: true, Contextual: true}, {ID: "inspect", Title: "Inspect Display Reading", Subtitle: "Check what the display reader saw.", Icon: "text-cursor-input", Primary: api.Primary(rev)}}
return v
}
func urlListView(urls []string, text string, copied bool) api.View {
title := "Copy Display Link"
if copied {
title = "Display Link Ready"
}
v := api.ListView(title)
v.ContentSizing = "fit"
vis := true
v.Detail = &api.DetailPane{Placement: "bottom", Visible: &vis}
v.Items = []api.Item{{ID: "hint", Title: "Found on the visible display. Enter copies.", Disabled: true, Contextual: true}}
for i, u := range urls {
v.Items = append(v.Items, urlItem(i, u, text))
}
return v
}
func urlItem(i int, val, text string) api.Item {
p, _ := url.Parse(val)
h := p.Hostname()
if h == "" {
h = val
}
return api.Item{ID: "url-" + strconv.Itoa(i), Title: h, Subtitle: val, Icon: "link", Detail: &api.Detail{Text: val}, Primary: api.Primary(api.CopyText("Copy Display Link", val, false)), Actions: []api.Action{api.PushView("Fix Link Text", reviewView(val)), api.PushView("Show Display Reading", api.View{Kind: api.ViewPreview, Title: "Display Reading", Preview: &api.PreviewSpec{Text: text}})}}
}
func reviewView(c string) api.View {
s := api.Run(editID, "Copy Fixed Link", nil)
return api.View{Kind: api.ViewEditor, Title: "Fix Display Link", Editor: &api.EditorSpec{Content: c, Format: "text", Submit: &s}}
}
func copyEdited(ctx api.Context, c string) (api.Result, error) {
v := wsPat.ReplaceAllString(c, "")
if !validURL(v) {
if validURL("https://" + v) {
v = "https://" + v
} else {
return api.Result{}, errors.New("Enter a complete http:// or https:// link. Clipboard unchanged.")
}
}
if err := ctx.Desktop().Clipboard().WriteText(v, false); err != nil {
return api.Result{}, err
}
_ = ctx.Indicators().Show(api.IndicatorInput{Title: "Display link copied", Status: api.IndicatorSuccess, DurationMs: 2200})
return api.Result{Navigation: api.NavPop}, nil
}
