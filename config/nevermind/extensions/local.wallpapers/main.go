package main

import (
	"encoding/json"
	"fmt"
	"github.com/pablopunk/nvm/native/internal/ext/api"
	"strings"
)

const (
	wd      = "~/.config/wallpapers"
	gridID  = "wallpapers.grid"
	setID   = "set-picture"
	prevID  = "preview-colors"
	restID  = "restore-colors"
	refID   = "refresh-icon-appearance"
	stageID = "refresh-stage-icons"
	bkey    = "appearance-original-v2"
)

var ckeys = []string{"AppleHighlightColor", "AppleIconAppearanceTintColor", "AppleIconAppearanceCustomTintColor", "AppleIconAppearanceTheme"}

const js = `ObjC.import('AppKit');function run(argv){var i=$.NSImage.alloc.initWithContentsOfFile($(argv[0]));if(!i||i.isNil())throw Error('bad image');var b=$.NSBitmapImageRep.imageRepWithData(i.TIFFRepresentation);if(!b||b.isNil())throw Error('bad bitmap');var w=Number(b.pixelsWide),h=Number(b.pixelsHigh),s=[];for(var y=0;y<40;y++)for(var x=0;x<40;x++){var c=b.colorAtXY(Math.min(w-1,Math.floor((x+0.5)*w/40)),Math.min(h-1,Math.floor((y+0.5)*h/40))).colorUsingColorSpace($.NSColorSpace.sRGBColorSpace);if(c&&!c.isNil()&&Number(c.alphaComponent)>0.5)s.push([Number(c.redComponent),Number(c.greenComponent),Number(c.blueComponent)]);}return JSON.stringify(s);}`

type pal struct {
	T, H [3]float64
	M    bool
}

func Commands(ctx api.Context) ([]api.Command, error) {
	b := api.Command{ID: gridID, Title: "Set Desktop Wallpaper", Subtitle: "Browse ~/.config/wallpapers; match icon tint and highlight", Icon: "image", Aliases: []string{"wallpapers", "wallpaper", "background"}, Triggers: []api.Trigger{{Type: api.TriggerFilesChanged, Roots: []string{wd}, DebounceMs: 500, FileKind: api.FileKindImage}}}
	if !isMac(ctx) {
		return []api.Command{b}, nil
	}
	return []api.Command{b, {ID: restID, Title: "Restore Previous Colors", Subtitle: "Restore appearance prefs saved before color matching", Aliases: []string{"restore wallpaper colors"}, Icon: "undo-2"}, {ID: refID, Title: "Refresh Wallpaper Icon Appearance", Subtitle: "Reload icon prefs and refresh Stage Manager thumbnails", Icon: "refresh-cw"}, {ID: stageID, Title: "Refresh Stage Manager Icons", Subtitle: "Toggle icon style back and forth to force Stage Manager to reload colors", Aliases: []string{"stage manager refresh"}, Icon: "refresh-cw"}}, nil
}
func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case gridID:
		return gridResult(ctx)
	case setID:
		return api.Result{}, setPic(ctx, in.Ref.Args["path"], in.Ref.Args["name"], in.Ref.Args["colors"] == "true")
	case prevID:
		return prevResult(ctx, in.Ref.Args["path"])
	case restID:
		return api.Result{}, restore(ctx)
	case refID:
		return api.Result{}, refresh(ctx, true)
	case stageID:
		return api.Result{}, refresh(ctx, false)
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}
func gridResult(ctx api.Context) (api.Result, error) {
	its, err := wallItems(ctx)
	if err != nil {
		return api.Result{}, err
	}
	v := api.GridView("Wallpapers", 3, its...)
	v.ID = "wallpapers-grid"
	v.Subtitle = wd
	v.Size = api.SizeLarge
	v.Placeholder = "Search wallpapers…"
	v.Grid = &api.GridSpec{Columns: 3, Layout: "wide", AspectRatio: "16/9", SelectionFooter: true}
	v.EmptyView = &api.EmptyState{Title: "No Wallpapers Found", Subtitle: "Put images in ~/.config/wallpapers."}
	v.Refresh = &api.Refresh{IntervalMs: 10000, Mode: api.PatchReplace, Ref: &api.ActionRef{ID: gridID}}
	if isMac(ctx) {
		v.Actions = []api.Action{api.Run(restID, "Restore Previous Colors", nil), api.Run(refID, "Refresh Wallpaper Icon Appearance", nil), api.Run(stageID, "Refresh Stage Manager Icons", nil)}
	}
	return api.Result{View: &v, Navigation: api.NavPush}, nil
}
func wallItems(ctx api.Context) ([]api.Item, error) {
	root, err := wallRoot(ctx)
	if err != nil {
		return nil, err
	}
	fs, err := ctx.Desktop().Files().Find([]string{root}, api.FindOptions{Kind: "image", Depth: 2, Limit: 300, SortBy: "name", Order: "asc"})
	if err != nil {
		return nil, fmt.Errorf("Could not load wallpapers: %w", err)
	}
	out := make([]api.Item, 0, len(fs))
	for _, f := range fs {
		out = append(out, wallItem(ctx, f))
	}
	return out, nil
}
func wallItem(ctx api.Context, f api.FileRef) api.Item {
	t := "Set as Wallpaper"
	if isMac(ctx) {
		t = "Set Wallpaper & Match Colors"
	}
	src := f.URL
	if src == "" {
		src = ctx.Desktop().Files().FileURL(f.Path)
	}
	im := &api.Image{Src: src, Fit: api.FitCover, Mask: api.MaskRounded}
	acts := []api.Action{}
	if isMac(ctx) {
		acts = append(acts, setAct(f, "Set Wallpaper Only", false), api.Run(prevID, "Preview Matching Colors", map[string]string{"path": f.Path}), api.Run(stageID, "Refresh Stage Manager Icons", nil))
	}
	acts = append(acts, api.Action{Kind: api.ActionQuickLook, Title: "Quick Look", Path: f.Path}, api.RevealPath("Reveal in Finder", f.Path), api.OpenPath("Open Image", f.Path), api.CopyText("Copy Path", f.Path, false))
	return api.Item{ID: f.Path, Title: f.Name, Subtitle: orDef(f.DisplayPath, f.Path), Image: im, Primary: api.Primary(setAct(f, t, true)), Actions: acts}
}
func setAct(f api.FileRef, title string, colors bool) api.Action {
	s := "false"
	if colors {
		s = "true"
	}
	a := api.Run(setID, title, map[string]string{"path": f.Path, "name": f.Name, "colors": s})
	a.Icon = "image"
	return a
}
func setPic(ctx api.Context, path, name string, colors bool) error {
	if err := applyPicture(ctx, path); err != nil {
		return err
	}
	if !colors || !isMac(ctx) {
		_ = ctx.System().Notify("Wallpaper updated", name)
		return nil
	}
	p, err := extract(ctx, path)
	if err != nil {
		return fmt.Errorf("Wallpaper set, but color sampling failed: %w", err)
	}
	sum, err := applyCols(ctx, p)
	if err != nil {
		return err
	}
	if err := kill(ctx.Desktop().Shell(), "Dock"); err != nil {
		return fmt.Errorf("Colors updated (%s) but the Dock could not restart: %w", sum, err)
	}
	_ = kill(ctx.Desktop().Shell(), "WindowManager")
	_ = ctx.System().Notify("Wallpaper and colors updated", sum)
	return nil
}
func extract(ctx api.Context, path string) (pal, error) {
	r, err := ctx.Desktop().Shell().Exec("/usr/bin/osascript", []string{"-l", "JavaScript", "-e", js, path}, api.ShellOptions{TimeoutMs: 15000})
	if err != nil {
		return pal{}, err
	}
	if r.ExitCode != 0 {
		return pal{}, fmt.Errorf("Could not sample wallpaper: %s", orDef(strings.TrimSpace(r.Stderr), "osascript failed"))
	}
	var s [][3]float64
	if err := json.Unmarshal([]byte(r.Stdout), &s); err != nil || len(s) == 0 {
		return pal{}, fmt.Errorf("Could not sample wallpaper colors")
	}
	return pick(s), nil
}

// cluster is a group of similar colors and how many samples it holds.
type cluster struct {
	C [3]float64
	N float64
}

func dist2(a, b [3]float64) float64 {
	return (a[0]-b[0])*(a[0]-b[0]) + (a[1]-b[1])*(a[1]-b[1]) + (a[2]-b[2])*(a[2]-b[2])
}
func byCount(c []cluster) {
	for i := 1; i < len(c); i++ {
		for j := i; j > 0 && c[j].N > c[j-1].N; j-- {
			c[j], c[j-1] = c[j-1], c[j]
		}
	}
}
func binOf(v float64) int {
	n := int(v * 12)
	if n > 11 {
		return 11
	}
	return n
}

// pick is 1.x's palette: the tint is the wallpaper's dominant usable color, the highlight the next distinct one, softened.
func pick(s [][3]float64) pal {
	idx := map[string]int{}
	bins := []cluster{}
	for _, c := range s {
		if c[0] < 0 || c[0] > 1 || c[1] < 0 || c[1] > 1 || c[2] < 0 || c[2] > 1 {
			continue
		}
		k := fmt.Sprintf("%d,%d,%d", binOf(c[0]), binOf(c[1]), binOf(c[2]))
		i, ok := idx[k]
		if !ok {
			i = len(bins)
			idx[k] = i
			bins = append(bins, cluster{})
		}
		bins[i].N++
		bins[i].C[0] += c[0]
		bins[i].C[1] += c[1]
		bins[i].C[2] += c[2]
	}
	byCount(bins)
	cl := []cluster{}
	for _, b := range bins {
		m := [3]float64{b.C[0] / b.N, b.C[1] / b.N, b.C[2] / b.N}
		near := -1
		for i := range cl {
			if dist2(cl[i].C, m) < 0.0256 {
				near = i
				break
			}
		}
		if near < 0 {
			cl = append(cl, cluster{C: m, N: b.N})
			continue
		}
		t := cl[near].N + b.N
		for j := 0; j < 3; j++ {
			cl[near].C[j] = (cl[near].C[j]*cl[near].N + m[j]*b.N) / t
		}
		cl[near].N = t
	}
	byCount(cl)
	if len(cl) == 0 {
		return pal{M: true}
	}
	cand := []cluster{}
	for _, c := range cl {
		mx, mn := c.C[0], c.C[0]
		for j := 1; j < 3; j++ {
			if c.C[j] > mx {
				mx = c.C[j]
			}
			if c.C[j] < mn {
				mn = c.C[j]
			}
		}
		if mx > 0.12 && mn < 0.9 {
			cand = append(cand, c)
		}
	}
	if len(cand) == 0 {
		cand = cl
	}
	first := cand[0].C
	second := first
	found := false
	for _, list := range [][]cluster{cand, cl} {
		if found {
			break
		}
		for _, c := range list {
			if dist2(first, c.C) >= 0.0529 {
				second = c.C
				found = true
				break
			}
		}
	}
	return pal{T: first, H: [3]float64{second[0]*0.5 + 0.5, second[1]*0.5 + 0.5, second[2]*0.5 + 0.5}, M: !found}
}
func hexV(c [3]float64) string {
	b := func(v float64) int {
		n := int(v*255 + 0.5)
		if n < 0 {
			return 0
		}
		if n > 255 {
			return 255
		}
		return n
	}
	return fmt.Sprintf("#%02X%02X%02X", b(c[0]), b(c[1]), b(c[2]))
}
func comps(c [3]float64) string { return fmt.Sprintf("%.6f %.6f %.6f", c[0], c[1], c[2]) }

// applyCols writes the colors in the format macOS reads: three or four numbers, with the tint named Other. It keeps the
// settings from before the first match, for Restore Previous Colors.
func applyCols(ctx api.Context, p pal) (string, error) {
	sh := ctx.Desktop().Shell()
	values := [][2]string{{"AppleHighlightColor", comps(p.H)}, {"AppleIconAppearanceTintColor", "Other"}, {"AppleIconAppearanceCustomTintColor", comps(p.T) + " 1.0"}, {"AppleIconAppearanceTheme", "TintedLight"}}
	var saved map[string]string
	found, _ := ctx.Storage().Get(bkey, &saved)
	if !found || len(saved) == 0 {
		saved = map[string]string{}
		for _, k := range ckeys {
			v, _ := rdef(sh, k)
			if strings.HasPrefix(v, "#") {
				v = ""
			}
			saved[k] = v
		}
		_ = ctx.Storage().Set(bkey, saved)
	}
	for _, kv := range values {
		if err := wdef(sh, kv[0], kv[1]); err != nil {
			return "", err
		}
	}
	for _, kv := range values {
		v, err := rdef(sh, kv[0])
		if err != nil || v != kv[1] {
			return "", fmt.Errorf("macOS did not keep %s", kv[0])
		}
	}
	ex := ""
	if p.M {
		ex = " Single-color fallback."
	}
	return fmt.Sprintf("Tint %s Highlight %s.%s", hexV(p.T), hexV(p.H), ex), nil
}
func restore(ctx api.Context) error {
	var o map[string]string
	f, _ := ctx.Storage().Get(bkey, &o)
	if !f || len(o) == 0 {
		return fmt.Errorf("No saved colors to restore yet. Set a wallpaper with color matching first")
	}
	sh := ctx.Desktop().Shell()
	for _, k := range ckeys {
		v := strings.TrimSpace(o[k])
		if v == "" {
			_ = ddef(sh, k)
		} else {
			_ = wdef(sh, k, v)
		}
	}
	_ = ctx.Storage().Delete(bkey)
	_ = restartFD(ctx)
	_ = ctx.System().Notify("Colors restored", "Previous appearance preferences restored.")
	return nil
}
func prevResult(ctx api.Context, path string) (api.Result, error) {
	p, err := extract(ctx, path)
	if err != nil {
		return api.Result{}, err
	}
	t := fmt.Sprintf("Tint %s Highlight %s", hexV(p.T), hexV(p.H))
	if p.M {
		t += "\nSingle-color fallback: no distinct second color found."
	}
	t += "\n\nSetting applies Tinted Light and restarts Dock. Use Refresh Stage Manager Icons if thumbnails lag."
	v := api.View{Kind: api.ViewPreview, Title: "Wallpaper Palette", Preview: &api.PreviewSpec{Image: &api.Image{Src: ctx.Desktop().Files().FileURL(path), Fit: api.FitCover}, Text: t}}
	return api.Result{View: &v, Navigation: api.NavPush}, nil
}
func refresh(ctx api.Context, withFinder bool) error {
	if !isMac(ctx) {
		return fmt.Errorf("Stage Manager refresh requires macOS")
	}
	sh := ctx.Desktop().Shell()
	cur, _ := rdef(sh, "AppleIconAppearanceTheme")
	cur = strings.TrimSpace(cur)
	tmp := "Dark"
	if strings.Contains(strings.ToLower(cur), "dark") || cur == "1" {
		tmp = "Light"
	}
	_ = wdef(sh, "AppleIconAppearanceTheme", tmp)
	_ = kill(sh, "Dock")
	if cur == "" {
		_ = ddef(sh, "AppleIconAppearanceTheme")
	} else {
		_ = wdef(sh, "AppleIconAppearanceTheme", cur)
	}
	_ = kill(sh, "Dock")
	_ = kill(sh, "Finder")
	_ = kill(sh, "WindowManager")
	_ = kill(sh, "NotificationCenter")
	if withFinder {
		_ = restartFD(ctx)
	}
	_ = ctx.System().Notify("Stage Manager icons refreshing", "Toggled icon style and restarted Dock. Thumbnails update in a few seconds.")
	return nil
}
func rdef(sh api.Shell, key string) (string, error) {
	r, err := sh.Exec("/usr/bin/defaults", []string{"read", "NSGlobalDomain", key}, api.ShellOptions{TimeoutMs: 5000})
	if err != nil || r.ExitCode != 0 {
		return "", fmt.Errorf("missing")
	}
	return strings.TrimSpace(r.Stdout), nil
}
func wdef(sh api.Shell, key, val string) error {
	r, err := sh.Exec("/usr/bin/defaults", []string{"write", "NSGlobalDomain", key, "-string", val}, api.ShellOptions{TimeoutMs: 5000})
	if err != nil || r.ExitCode != 0 {
		return fmt.Errorf("Could not write %s", key)
	}
	return nil
}
func ddef(sh api.Shell, key string) error {
	_, _ = sh.Exec("/usr/bin/defaults", []string{"delete", "NSGlobalDomain", key}, api.ShellOptions{TimeoutMs: 5000})
	return nil
}
func kill(sh api.Shell, name string) error {
	r, err := sh.Exec("/usr/bin/killall", []string{name}, api.ShellOptions{TimeoutMs: 10000})
	if err != nil {
		return err
	}
	if r.ExitCode != 0 && !strings.Contains(strings.ToLower(r.Stderr+r.Stdout), "no matching processes") {
		return fmt.Errorf("killall %s failed", name)
	}
	return nil
}
func restartFD(ctx api.Context) error {
	_ = kill(ctx.Desktop().Shell(), "Finder")
	return kill(ctx.Desktop().Shell(), "Dock")
}
func isMac(ctx api.Context) bool {
	o := strings.ToLower(ctx.System().OS())
	return strings.Contains(o, "darwin") || strings.Contains(o, "mac")
}
func orDef(a, b string) string {
	if a != "" {
		return a
	}
	return b
}
func wallRoot(ctx api.Context) (string, error) {
	r, err := ctx.Desktop().Shell().Exec("/bin/sh", []string{"-c", `printf "%s" "$HOME"`}, api.ShellOptions{TimeoutMs: 5000})
	h := strings.TrimSpace(r.Stdout)
	if err != nil || r.ExitCode != 0 || !strings.HasPrefix(h, "/") {
		return "", fmt.Errorf("Cannot resolve ~/.config/wallpapers")
	}
	return h + "/.config/wallpapers", nil
}

// applyPicture sets the desktop picture and fails when macOS refused, trying the same ways 1.x tried.
func applyPicture(ctx api.Context, path string) error {
	esc := strings.ReplaceAll(strings.ReplaceAll(path, `\`, `\\`), `"`, `\"`)
	last := ""
	for _, script := range []string{
		`tell application "System Events" to tell every desktop to set picture to POSIX file "` + esc + `"`,
		`tell application "Finder" to set desktop picture to POSIX file "` + esc + `"`,
	} {
		r, err := ctx.Desktop().Shell().Exec("/usr/bin/osascript", []string{"-e", script}, api.ShellOptions{TimeoutMs: 15000})
		if err != nil {
			last = err.Error()
			continue
		}
		if r.ExitCode == 0 {
			return nil
		}
		last = strings.TrimSpace(r.Stderr + r.Stdout)
	}
	return fmt.Errorf("Could not set the wallpaper: %s", last)
}
