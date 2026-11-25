package main

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/pablopunk/nvm/native/internal/ext/api"
)

const cmdID = "todays-weather"
const refreshID = "refresh"

type locCache struct {
	Lat   float64 `json:"lat"`
	Lon   float64 `json:"lon"`
	Label string  `json:"label"`
}

type meteo struct {
	Current struct {
		Temp     float64 `json:"temperature_2m"`
		Feels    float64 `json:"apparent_temperature"`
		Humidity int     `json:"relative_humidity_2m"`
		Code     int     `json:"weather_code"`
		Wind     float64 `json:"wind_speed_10m"`
	} `json:"current"`
	Daily struct {
		Codes  []int     `json:"weather_code"`
		Max    []float64 `json:"temperature_2m_max"`
		Min    []float64 `json:"temperature_2m_min"`
		Precip []int     `json:"precipitation_probability_max"`
	} `json:"daily"`
}

type saved struct {
	W     meteo `json:"w"`
	Label string `json:"label"`
}

func MenuBarTriggers() []api.Trigger {
	return []api.Trigger{{Type: api.TriggerInterval, Every: "30m"}}
}

func Commands(ctx api.Context) ([]api.Command, error) {
	return []api.Command{{
		ID:       cmdID,
		Title:    "Today's Weather",
		Subtitle: "Show today's forecast for your current location",
		Icon:     "cloud-sun",
		Keywords: []string{"weather", "forecast", "temperature", "menubar"},
	}}, nil
}

func MenuBars(ctx api.Context) ([]api.MenuBar, error) {
	w, label, cached, err := loadWeather(ctx)
	if err != nil {
		retry := api.Run(refreshID, "Refresh", nil)
		row := api.MenuRow{ID: "err", Title: "Weather unavailable", Subtitle: short(err.Error(), 70), Disabled: true}
		rrow := api.MenuRow{ID: refreshID, Title: "Refresh", Action: &retry}
		bar := api.MenuBar{ID: "weather", Icon: api.MenuBarIcon("cloud-off"), Title: "?", Tooltip: "Today's weather unavailable: " + short(err.Error(), 120), Sections: []api.MenuSection{{Title: "Today's Weather", Rows: []api.MenuRow{row, rrow}}}}
		return []api.MenuBar{bar}, nil
	}
	desc, icon := describe(codeOf(w))
	title := fmt.Sprintf("%.0f°", w.Current.Temp)
	if cached {
		title = fmt.Sprintf("%.0f°*", w.Current.Temp)
	}
	tip := fmt.Sprintf("%s in %s: %.0f° (H %s L %s)", desc, label, w.Current.Temp, hiOf(w), loOf(w))
	if cached {
		tip += " · cached"
	}
	rows := []api.MenuRow{
		{ID: "now", Title: fmt.Sprintf("%s · %.0f°", desc, w.Current.Temp), Subtitle: fmt.Sprintf("Feels %.0f° in %s", w.Current.Feels, label), Disabled: true},
		{ID: "hilow", Title: fmt.Sprintf("H %s  L %s", hiOf(w), loOf(w)), Subtitle: precipOf(w), Disabled: true},
		{ID: "extra", Title: fmt.Sprintf("Humidity %d%% · Wind %.0f km/h", w.Current.Humidity, w.Current.Wind), Disabled: true},
	}
	open := api.OpenURL("Open Full Forecast", "https://www.google.com/search?q=weather+"+plus(label))
	rows = append(rows, api.MenuRow{ID: "open", Title: "Open Full Forecast", Subtitle: label, Action: &open})
	refresh := api.Run(refreshID, "Refresh", nil)
	rows = append(rows, api.MenuRow{ID: refreshID, Title: "Refresh", Subtitle: "Update now", Action: &refresh})
	bar := api.MenuBar{ID: "weather", Icon: api.MenuBarIcon(icon), Title: title, Tooltip: tip, Sections: []api.MenuSection{{Title: "Today's Weather", Rows: rows}}}
	return []api.MenuBar{bar}, nil
}

func RunAction(ctx api.Context, in api.Invocation) (api.Result, error) {
	switch in.Ref.ID {
	case refreshID:
		ctx.Views().RefreshMenuBar()
		return api.Result{}, nil
	case cmdID:
		w, label, cached, err := loadWeather(ctx)
		if err != nil {
			return api.Result{}, err
		}
		view := detailView(w, label, cached)
		return api.Result{View: &view, Navigation: api.NavPush}, nil
	}
	return api.Result{}, fmt.Errorf("unknown action %q", in.Ref.ID)
}

func detailView(w meteo, label string, cached bool) api.View {
	desc, icon := describe(codeOf(w))
	sub := label
	if cached {
		sub += " · cached"
	}
	items := []api.Item{
		{ID: "now", Title: fmt.Sprintf("%s · %.0f°", desc, w.Current.Temp), Subtitle: fmt.Sprintf("Feels like %.0f° in %s", w.Current.Feels, label), Icon: icon, Primary: api.Primary(api.CopyText("Copy Summary", fmt.Sprintf("%s %.0f° (H %s L %s) in %s", desc, w.Current.Temp, hiOf(w), loOf(w), label), false))},
		{ID: "hilow", Title: fmt.Sprintf("High %s  /  Low %s", hiOf(w), loOf(w)), Subtitle: precipOf(w), Icon: "thermometer"},
		{ID: "extra", Title: fmt.Sprintf("Humidity %d%% · Wind %.0f km/h", w.Current.Humidity, w.Current.Wind), Subtitle: "Today", Icon: "wind"},
	}
	view := api.ListView("Today's Weather · "+label, items...)
	view.Subtitle = sub
	open := api.OpenURL("Open Full Forecast", "https://www.google.com/search?q=weather+"+plus(label))
	refresh := api.Run(refreshID, "Refresh", nil)
	view.Actions = []api.Action{refresh, open}
	return view
}

func loadWeather(ctx api.Context) (meteo, string, bool, error) {
	var out meteo
	lat, lon, label := resolveLoc(ctx)
	if label == "" {
		return out, "", false, fmt.Errorf("could not detect location")
	}
	url := fmt.Sprintf("https://api.open-meteo.com/v1/forecast?latitude=%f&longitude=%f&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&timezone=auto&forecast_days=1", lat, lon)
	resp, err := ctx.Network().Fetch(api.FetchRequest{URL: url, TimeoutMs: 12000, MaxBytes: 300000})
	if err == nil && resp.Status >= 200 && resp.Status < 300 {
		if jerr := json.Unmarshal([]byte(resp.Body), &out); jerr == nil && len(out.Daily.Max) > 0 {
			_ = ctx.Storage().Set("last-weather", saved{W: out, Label: label})
			return out, label, false, nil
		}
		if err == nil {
			err = fmt.Errorf("forecast lookup failed (HTTP %d)", resp.Status)
		}
	}
	var s saved
	if found, gerr := ctx.Storage().Get("last-weather", &s); gerr == nil && found && len(s.W.Daily.Max) > 0 {
		return s.W, s.Label, true, nil
	}
	if err == nil {
		err = fmt.Errorf("forecast unavailable")
	}
	return out, label, false, err
}

func resolveLoc(ctx api.Context) (float64, float64, string) {
	if lat, lon, label, err := freshLoc(ctx); err == nil {
		_ = ctx.Storage().Set("loc", locCache{Lat: lat, Lon: lon, Label: label})
		return lat, lon, label
	}
	var s locCache
	if found, err := ctx.Storage().Get("loc", &s); err == nil && found && s.Lat != 0 {
		return s.Lat, s.Lon, s.Label
	}
	return 0, 0, ""
}

func freshLoc(ctx api.Context) (float64, float64, string, error) {
	var a struct {
		City    string  `json:"city"`
		Region  string  `json:"region"`
		Country string  `json:"country_name"`
		Lat     float64 `json:"latitude"`
		Lon     float64 `json:"longitude"`
	}
	if err := fetchJSON(ctx, "https://ipapi.co/json/", &a); err == nil && a.Lat != 0 {
		return a.Lat, a.Lon, place(a.City, a.Region, a.Country), nil
	}
	var b struct {
		City    string  `json:"city"`
		Region  string  `json:"region"`
		Country string  `json:"country"`
		Lat     float64 `json:"latitude"`
		Lon     float64 `json:"longitude"`
	}
	if err := fetchJSON(ctx, "https://ipwho.is/", &b); err == nil && b.Lat != 0 {
		return b.Lat, b.Lon, place(b.City, b.Region, b.Country), nil
	}
	return 0, 0, "", fmt.Errorf("location lookup failed")
}

func fetchJSON(ctx api.Context, url string, into any) error {
	resp, err := ctx.Network().Fetch(api.FetchRequest{URL: url, TimeoutMs: 8000, MaxBytes: 200000})
	if err != nil {
		return err
	}
	if resp.Status < 200 || resp.Status >= 300 {
		return fmt.Errorf("HTTP %d", resp.Status)
	}
	return json.Unmarshal([]byte(resp.Body), into)
}

func describe(code int) (string, string) {
	switch code {
	case 0:
		return "Clear sky", "sun"
	case 1:
		return "Mainly clear", "sun"
	case 2:
		return "Partly cloudy", "cloud-sun"
	case 3:
		return "Overcast", "cloud"
	case 45, 48:
		return "Foggy", "cloud-fog"
	case 51, 53, 55, 56, 57:
		return "Drizzle", "cloud-drizzle"
	case 61, 63, 65, 66, 67, 80, 81, 82:
		return "Rain", "cloud-rain"
	case 71, 73, 75, 77, 85, 86:
		return "Snow", "cloud-snow"
	case 95, 96, 99:
		return "Thunderstorm", "cloud-lightning"
	}
	return "Unknown", "cloud"
}

func codeOf(w meteo) int {
	if len(w.Daily.Codes) > 0 {
		return w.Daily.Codes[0]
	}
	return w.Current.Code
}

func hiOf(w meteo) string {
	if len(w.Daily.Max) > 0 {
		return fmt.Sprintf("%.0f°", w.Daily.Max[0])
	}
	return "—"
}

func loOf(w meteo) string {
	if len(w.Daily.Min) > 0 {
		return fmt.Sprintf("%.0f°", w.Daily.Min[0])
	}
	return "—"
}

func precipOf(w meteo) string {
	if len(w.Daily.Precip) > 0 {
		return fmt.Sprintf("Precipitation chance %d%%", w.Daily.Precip[0])
	}
	return "Precipitation chance —"
}

func place(parts ...string) string {
	var kept []string
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" && !contains(kept, p) {
			kept = append(kept, p)
		}
		if len(kept) == 2 {
			break
		}
	}
	if len(kept) == 0 {
		return "Current location"
	}
	return strings.Join(kept, ", ")
}

func contains(v []string, s string) bool {
	for _, x := range v {
		if x == s {
			return true
		}
	}
	return false
}

func plus(s string) string {
	s = strings.TrimSpace(s)
	if s == "" {
		return "today"
	}
	return strings.ReplaceAll(s, " ", "+")
}

func short(s string, n int) string {
	s = strings.TrimSpace(s)
	r := []rune(s)
	if len(r) <= n {
		return s
	}
	return string(r[:n-1]) + "…"
}
